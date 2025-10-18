# ECR ImagePullSecret Management
# This creates an imagePullSecret for pulling images from private ECR
# and sets up automatic renewal via CronJob (ECR tokens expire after 12h)

locals {
  ecr_secret_enabled = var.ecr_secret_enabled
  ecr_namespace      = var.ecr_secret_namespace
  ecr_secret_name    = var.ecr_secret_name
}

########################
# IRSA for ECR Token Renewal CronJob
########################

data "aws_iam_policy_document" "ecr_token_renew_assume" {
  count = local.ecr_secret_enabled ? 1 : 0

  statement {
    effect = "Allow"

    principals {
      type        = "Federated"
      identifiers = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:oidc-provider/${replace(var.oidc_provider, "https://", "")}"]
    }

    actions = ["sts:AssumeRoleWithWebIdentity"]

    condition {
      test     = "StringEquals"
      variable = "${replace(var.oidc_provider, "https://", "")}:sub"
      values   = ["system:serviceaccount:kube-system:ecr-renew-sa"]
    }

    condition {
      test     = "StringEquals"
      variable = "${replace(var.oidc_provider, "https://", "")}:aud"
      values   = ["sts.amazonaws.com"]
    }
  }
}

data "aws_iam_policy_document" "ecr_token_renew" {
  count = local.ecr_secret_enabled ? 1 : 0

  statement {
    effect = "Allow"
    actions = [
      "ecr:GetAuthorizationToken",
    ]
    resources = ["*"]
  }

  statement {
    effect = "Allow"
    actions = [
      "ecr:BatchCheckLayerAvailability",
      "ecr:GetDownloadUrlForLayer",
      "ecr:BatchGetImage",
      "ecr:DescribeRepositories",
      "ecr:ListImages",
    ]
    resources = var.ecr_repository_arns
  }
}

resource "aws_iam_role" "ecr_token_renew" {
  count = local.ecr_secret_enabled ? 1 : 0

  name               = "eks-ecr-token-renew-${var.cluster_name}"
  assume_role_policy = data.aws_iam_policy_document.ecr_token_renew_assume[0].json

  tags = {
    Name = "EKS ECR Token Renewal Role"
  }
}

resource "aws_iam_role_policy" "ecr_token_renew" {
  count = local.ecr_secret_enabled ? 1 : 0

  name   = "ecr-token-renew-policy"
  role   = aws_iam_role.ecr_token_renew[0].id
  policy = data.aws_iam_policy_document.ecr_token_renew[0].json
}

data "aws_caller_identity" "current" {}

########################
# Kubernetes Resources
########################

# Namespace for application (if it doesn't exist via chart)
resource "kubernetes_namespace" "ecr_target" {
  count = local.ecr_secret_enabled && var.ecr_create_namespace ? 1 : 0

  metadata {
    name = local.ecr_namespace
  }

  lifecycle {
    ignore_changes = [metadata[0].labels, metadata[0].annotations]
  }
}

# ServiceAccount for CronJob
resource "kubernetes_service_account" "ecr_renew" {
  count = local.ecr_secret_enabled ? 1 : 0

  metadata {
    name      = "ecr-renew-sa"
    namespace = "kube-system"
    annotations = {
      "eks.amazonaws.com/role-arn" = aws_iam_role.ecr_token_renew[0].arn
    }
  }
}

# Role to manage secrets in target namespace
resource "kubernetes_role" "ecr_renew" {
  count = local.ecr_secret_enabled ? 1 : 0

  metadata {
    name      = "ecr-renew-role"
    namespace = local.ecr_namespace
  }

  rule {
    api_groups = [""]
    resources  = ["secrets"]
    verbs      = ["get", "create", "delete", "patch"]
  }

  depends_on = [kubernetes_namespace.ecr_target]
}

resource "kubernetes_role_binding" "ecr_renew" {
  count = local.ecr_secret_enabled ? 1 : 0

  metadata {
    name      = "ecr-renew-rolebinding"
    namespace = local.ecr_namespace
  }

  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "Role"
    name      = kubernetes_role.ecr_renew[0].metadata[0].name
  }

  subject {
    kind      = "ServiceAccount"
    name      = kubernetes_service_account.ecr_renew[0].metadata[0].name
    namespace = "kube-system"
  }

  depends_on = [kubernetes_namespace.ecr_target]
}

# CronJob to renew ECR token every 10 hours
resource "kubernetes_cron_job_v1" "ecr_secret_renew" {
  count = local.ecr_secret_enabled ? 1 : 0

  metadata {
    name      = "ecr-secret-renewal"
    namespace = "kube-system"
  }

  spec {
    schedule                      = "0 */10 * * *" # Every 10 hours
    successful_jobs_history_limit = 3
    failed_jobs_history_limit     = 3

    job_template {
      metadata {}
      spec {
        template {
          metadata {}
          spec {
            service_account_name = kubernetes_service_account.ecr_renew[0].metadata[0].name
            restart_policy       = "OnFailure"

            container {
              name  = "ecr-renew"
              image = "amazon/aws-cli:2.15.10"

              env {
                name  = "AWS_REGION"
                value = var.aws_region
              }
              env {
                name  = "AWS_ACCOUNT_ID"
                value = data.aws_caller_identity.current.account_id
              }
              env {
                name  = "SECRET_NAME"
                value = local.ecr_secret_name
              }
              env {
                name  = "TARGET_NAMESPACE"
                value = local.ecr_namespace
              }

              command = ["/bin/bash", "-c"]
              args = [<<-EOT
                set -e
                
                echo "Starting ECR secret renewal..."
                echo "Target namespace: $TARGET_NAMESPACE"
                echo "Secret name: $SECRET_NAME"
                
                # Install kubectl
                curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
                chmod +x kubectl
                mv kubectl /usr/local/bin/
                
                # Get ECR password
                ECR_PASSWORD=$(aws ecr get-login-password --region $AWS_REGION)
                ECR_REGISTRY="$AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com"
                
                # Create docker config.json
                cat > /tmp/config.json <<EOF
                {
                  "auths": {
                    "$ECR_REGISTRY": {
                      "auth": "$(echo -n AWS:$ECR_PASSWORD | base64 -w 0)"
                    }
                  }
                }
                EOF
                
                # Delete old secret if exists
                kubectl delete secret $SECRET_NAME -n $TARGET_NAMESPACE --ignore-not-found=true
                
                # Create new secret
                kubectl create secret generic $SECRET_NAME \
                  --from-file=.dockerconfigjson=/tmp/config.json \
                  --type=kubernetes.io/dockerconfigjson \
                  -n $TARGET_NAMESPACE
                
                echo "✓ ECR secret renewed successfully at $(date)"
              EOT
              ]

              resources {
                requests = {
                  memory = "64Mi"
                  cpu    = "100m"
                }
                limits = {
                  memory = "128Mi"
                  cpu    = "200m"
                }
              }
            }
          }
        }
      }
    }
  }

  depends_on = [
    kubernetes_role_binding.ecr_renew,
    kubernetes_namespace.ecr_target
  ]
}

# Create initial ECR secret via null_resource
# This runs once to create the initial secret before the CronJob takes over
resource "null_resource" "ecr_secret_initial" {
  count = local.ecr_secret_enabled ? 1 : 0

  provisioner "local-exec" {
    command = <<-EOT
      # Get ECR token and create secret
      ECR_PASSWORD=$(aws ecr get-login-password --region ${var.aws_region})
      ECR_REGISTRY="${data.aws_caller_identity.current.account_id}.dkr.ecr.${var.aws_region}.amazonaws.com"
      
      # Create docker config
      mkdir -p /tmp/ecr-secret-$$
      cat > /tmp/ecr-secret-$$/config.json <<EOF
      {
        "auths": {
          "$ECR_REGISTRY": {
            "auth": "$(echo -n AWS:$ECR_PASSWORD | base64)"
          }
        }
      }
      EOF
      
      # Create or update secret
      kubectl create secret generic ${local.ecr_secret_name} \
        --from-file=.dockerconfigjson=/tmp/ecr-secret-$$/config.json \
        --type=kubernetes.io/dockerconfigjson \
        --namespace=${local.ecr_namespace} \
        --dry-run=client -o yaml | kubectl apply -f -
      
      rm -rf /tmp/ecr-secret-$$
      echo "Initial ECR secret created successfully"
    EOT

    environment = {
      KUBECONFIG = "" # Use current kubeconfig
    }
  }

  depends_on = [
    kubernetes_namespace.ecr_target,
    kubernetes_role_binding.ecr_renew
  ]

  triggers = {
    # Re-run if these change
    region                = var.aws_region
    secret_name           = local.ecr_secret_name
    namespace             = local.ecr_namespace
    ecr_repository_change = join(",", var.ecr_repository_arns)
  }
}

