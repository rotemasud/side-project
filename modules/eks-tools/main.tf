terraform {
  required_providers {
    helm = {
      source = "hashicorp/helm"
    }
    kubernetes = {
      source = "hashicorp/kubernetes"
    }
    kubectl = {
      source  = "gavinbunney/kubectl"
      version = ">= 1.14.0"
    }
  }
}

########################
# IRSA for EBS CSI + Helm install
########################

data "aws_iam_policy" "ebs_csi_policy" {
  count = var.ebs_csi_enabled && var.ebs_csi_irsa_enabled ? 1 : 0
  arn   = "arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy"
}

module "irsa_ebs_csi_role" {
  count  = var.ebs_csi_enabled && var.ebs_csi_irsa_enabled ? 1 : 0
  source = "terraform-aws-modules/iam/aws//modules/iam-assumable-role-with-oidc"
  version = "5.39.0"

  create_role                   = true
  role_name                     = "AmazonEKSTFEBSCSIRole-${var.cluster_name}"
  provider_url                  = var.oidc_provider
  role_policy_arns              = [data.aws_iam_policy.ebs_csi_policy[0].arn]
  oidc_fully_qualified_subjects = ["system:serviceaccount:kube-system:ebs-csi-controller-sa"]
}

resource "helm_release" "ebs_csi" {
  count = var.ebs_csi_enabled ? 1 : 0

  name       = "aws-ebs-csi-driver"
  repository = var.ebs_csi_repository
  chart      = "aws-ebs-csi-driver"
  namespace  = var.ebs_csi_namespace

  create_namespace = true

  values = concat(
    var.ebs_csi_values_file != null ? [file(var.ebs_csi_values_file)] : [],
    [yamlencode({
      controller = {
        serviceAccount = {
          create = true
          name   = "ebs-csi-controller"
          annotations = var.ebs_csi_irsa_enabled && var.ebs_csi_enabled ? {
            "eks.amazonaws.com/role-arn" = module.irsa_ebs_csi_role[0].iam_role_arn
          } : {}
        }
      }
    })]
  )
}

########################
# Istio via Helm
########################

resource "helm_release" "istio_base" {
  count = var.istio_enabled ? 1 : 0

  name       = "istio-base"
  repository = var.istio_repository
  chart      = "base"
  namespace  = var.istio_namespace

  create_namespace = true
}

resource "helm_release" "istiod" {
  count = var.istio_enabled ? 1 : 0

  name       = "istiod"
  repository = var.istio_repository
  chart      = "istiod"
  namespace  = var.istio_namespace

  values = var.istiod_values_file != null ? [file(var.istiod_values_file)] : []

  depends_on = [helm_release.istio_base]
}

resource "helm_release" "istio_ingress" {
  count = var.istio_enabled && var.istio_ingress_enabled ? 1 : 0

  name       = "istio-ingress"
  repository = var.istio_repository
  chart      = "gateway"
  namespace  = var.istio_namespace

  values = var.istio_ingress_values_file != null ? [file(var.istio_ingress_values_file)] : []

  depends_on = [helm_release.istiod]
}

########################
# Argo CD via Helm
########################

resource "helm_release" "argocd" {
  count = var.argocd_enabled ? 1 : 0

  name       = "argo-cd"
  repository = var.argocd_repository
  chart      = "argo-cd"
  namespace  = var.argocd_namespace

  create_namespace = true

  values = var.argocd_values_file != null ? [file(var.argocd_values_file)] : []
}

########################
# Karpenter via Helm + optional manifests
########################

resource "helm_release" "karpenter" {
  count = var.karpenter_enabled ? 1 : 0

  name       = "karpenter"
  repository = "https://charts.karpenter.sh"
  chart      = "karpenter"
  namespace  = var.karpenter_namespace

  create_namespace = true

  values = [yamlencode({
    serviceAccount = {
      create = true
      name   = "karpenter"
      annotations = local.controller_role_arn_resolved != null ? {
        "eks.amazonaws.com/role-arn" = local.controller_role_arn_resolved
      } : {}
    }
    settings = {
      clusterName = var.cluster_name
    }
    controller = {
      env = [
        { name = "AWS_REGION", value = var.aws_region },
        { name = "AWS_DEFAULT_REGION", value = var.aws_region }
      ]
    }
    interruptionQueue = local.interruption_queue_name_resolved
  })]
}

locals {
  karpenter_yaml_path_resolved = var.karpenter_yaml_path != null ? var.karpenter_yaml_path : "${path.module}/karpenter.yaml"
  karpenter_documents = var.apply_karpenter_yaml ? [for d in split("---\n", file(local.karpenter_yaml_path_resolved)) : d if trimspace(d) != ""] : []
  controller_role_arn_resolved = var.karpenter_controller_role_arn != null ? var.karpenter_controller_role_arn : (try(aws_iam_role.karpenter_controller[0].arn, null))
  interruption_queue_name_resolved = var.karpenter_interruption_queue_name != null ? var.karpenter_interruption_queue_name : (try(aws_sqs_queue.karpenter_interruption[0].name, null))
}

resource "kubectl_manifest" "karpenter_docs" {
  count     = var.apply_karpenter_yaml ? length(local.karpenter_documents) : 0
  yaml_body = element(local.karpenter_documents, count.index)
  
  depends_on = [helm_release.karpenter]
}


