variable "cluster_name" { type = string }
variable "oidc_provider" { type = string }
variable "aws_region" { type = string }

# EBS CSI
variable "ebs_csi_enabled" {
  type    = bool
  default = true
}
variable "ebs_csi_namespace" {
  type    = string
  default = "kube-system"
}
variable "ebs_csi_repository" {
  type    = string
  default = "https://kubernetes-sigs.github.io/aws-ebs-csi-driver"
}
variable "ebs_csi_values_file" {
  type    = string
  default = null
}
variable "ebs_csi_irsa_enabled" {
  type    = bool
  default = true
}

# Istio
variable "istio_enabled" {
  type    = bool
  default = false
}
variable "istio_namespace" {
  type    = string
  default = "istio-system"
}
variable "istio_repository" {
  type    = string
  default = "https://istio-release.storage.googleapis.com/charts"
}
variable "istiod_values_file" {
  type    = string
  default = null
}
variable "istio_ingress_enabled" {
  type    = bool
  default = true
}
variable "istio_ingress_values_file" {
  type    = string
  default = null
}

# Argo CD
variable "argocd_enabled" {
  type    = bool
  default = false
}
variable "argocd_namespace" {
  type    = string
  default = "argocd"
}
variable "argocd_repository" {
  type    = string
  default = "https://argoproj.github.io/argo-helm"
}
variable "argocd_values_file" {
  type    = string
  default = null
}

# Karpenter
variable "karpenter_enabled" {
  type    = bool
  default = true
}
variable "karpenter_namespace" {
  type    = string
  default = "karpenter"
}
variable "karpenter_controller_role_arn" {
  type    = string
  default = null
}
variable "karpenter_interruption_queue_name" {
  type    = string
  default = null
}
variable "karpenter_values_file" {
  type    = string
  default = null
}

# Karpenter YAML application
variable "apply_karpenter_yaml" {
  type    = bool
  default = true
}
variable "karpenter_yaml_path" {
  type    = string
  default = null
}

# Discovery tags variables
variable "private_subnets" {
  type        = list(string)
  description = "List of private subnet IDs for Karpenter discovery tags"
}

variable "cluster_security_group_id" {
  type        = string
  description = "EKS cluster security group ID for Karpenter discovery tags"
}


