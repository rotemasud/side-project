provider "aws" {
  region = "il-central-1"
  
}

terraform {
  backend "s3" {
    bucket  = "my-terraform-backend-store-side-project"
    encrypt = true
    key     = "terraform.tfstate"
    region  = "il-central-1"
    dynamodb_table = "terraform-state-lock-dynamo"
  }
}

resource "aws_dynamodb_table" "dynamodb-terraform-state-lock-side-project" {
  name           = "terraform-state-lock-dynamo"
  hash_key       = "LockID"
  read_capacity  = 3
  write_capacity = 3
  attribute {
    name = "LockID"
    type = "S"
  }
  tags = {
    Name = "DynamoDB Terraform State Lock Table"
  }
}

# Filter out local zones, which are not currently supported 
# with managed node groups
data "aws_availability_zones" "available" {
  filter {
    name   = "opt-in-status"
    values = ["opt-in-not-required"]
  }
}

locals {
  cluster_name = var.cluster_name
}

resource "random_string" "suffix" {
  length  = 8
  special = false
}

module "vpc" {
  source = "./modules/vpc"

  name = var.vpc_name

  cidr = var.vpc_cidr
  azs  = slice(data.aws_availability_zones.available.names, 0, 3)

  private_subnets = var.vpc_private_subnets
  public_subnets  = var.vpc_public_subnets

  enable_nat_gateway   = var.vpc_enable_nat_gateway
  single_nat_gateway   = var.vpc_single_nat_gateway
  enable_dns_hostnames = var.vpc_enable_dns_hostnames

  public_subnet_tags = {
    "kubernetes.io/role/elb" = 1
  }

  private_subnet_tags = {
    "kubernetes.io/role/internal-elb" = 1
  }
}

module "eks" {
  source = "./modules/eks"

  providers = {
    helm = helm.eks
  }

  cluster_name    = local.cluster_name
  cluster_version = var.cluster_version

  cluster_endpoint_public_access           = true
  enable_cluster_creator_admin_permissions = true

  # No cluster_addons here; EBS CSI is installed via eks-tools module
  cluster_addons = {}

  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnets

  eks_managed_node_group_defaults = {
    ami_type = "AL2_x86_64"

  }

  eks_managed_node_groups = {
    one = {
      name = "node-group-1"

      instance_types = var.node_group_instance_types

      min_size     = var.node_group_min_size
      max_size     = var.node_group_max_size
      desired_size = var.node_group_desired_size
    }
  }

  # Tooling (Istio, ArgoCD, Karpenter, EBS CSI) moved to eks-tools module


}

data "aws_eks_cluster" "this" {
  name       = local.cluster_name
  depends_on = [module.eks]
}

data "aws_eks_cluster_auth" "this" {
  name       = local.cluster_name
  depends_on = [module.eks]
}

provider "kubernetes" {
  alias                  = "eks"
  host                   = data.aws_eks_cluster.this.endpoint
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.this.certificate_authority[0].data)
  token                  = data.aws_eks_cluster_auth.this.token
}

provider "helm" {
  alias = "eks"
  
  kubernetes {
    host                   = data.aws_eks_cluster.this.endpoint
    cluster_ca_certificate = base64decode(data.aws_eks_cluster.this.certificate_authority[0].data)
    token                  = data.aws_eks_cluster_auth.this.token
  }
}

provider "kubectl" {
  alias                  = "eks"
  host                   = data.aws_eks_cluster.this.endpoint
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.this.certificate_authority[0].data)
  token                  = data.aws_eks_cluster_auth.this.token
  load_config_file       = false
}

# https://aws.amazon.com/blogs/containers/amazon-ebs-csi-driver-is-now-generally-available-in-amazon-eks-add-ons/ 
module "ecr" {
  source = "./modules/ecr"
}

module "eks_tools" {
  source = "./modules/eks-tools"

  providers = {
    helm        = helm.eks
    kubernetes  = kubernetes.eks
    kubectl     = kubectl.eks
  }

  cluster_name = module.eks.cluster_name
  oidc_provider = module.eks.oidc_provider
  aws_region   = var.region
  vpc_id       = module.vpc.vpc_id

  # Discovery tags
  private_subnets = module.vpc.private_subnets
  cluster_security_group_id = module.eks.cluster_security_group_id

  # EBS CSI
  ebs_csi_enabled       = true
  ebs_csi_irsa_enabled  = true

  # AWS Load Balancer Controller
  aws_lb_controller_enabled = var.aws_lb_controller_enabled

  # Karpenter
  karpenter_enabled                   = var.karpenter_enabled
  karpenter_namespace                 = "karpenter"
  karpenter_controller_role_arn       = null
  karpenter_interruption_queue_name   = null
  karpenter_values_file               = var.karpenter_values_file

  # Karpenter manifests
  apply_karpenter_yaml = var.apply_karpenter_yaml
  karpenter_yaml_path  = null  # Use module's local karpenter.yaml

  # Istio
  istio_enabled             = var.istio_enabled
  istio_namespace           = var.istio_namespace
  istio_repository          = var.istio_repository
  istiod_values_file        = var.istiod_values_file
  istio_ingress_enabled     = var.istio_ingress_enabled
  istio_ingress_values_file = var.istio_ingress_values_file

  # Argo CD
  argocd_enabled     = var.argocd_enabled
  argocd_namespace   = var.argocd_namespace
  argocd_repository  = var.argocd_repository
  argocd_values_file = var.argocd_values_file
}

