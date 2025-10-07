terraform {
  required_providers {
    helm = {
      source = "hashicorp/helm"
    }
  }
}

module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "20.8.5"

  cluster_name    = var.cluster_name
  cluster_version = var.cluster_version

  cluster_endpoint_public_access           = var.cluster_endpoint_public_access
  enable_cluster_creator_admin_permissions = var.enable_cluster_creator_admin_permissions

  cluster_addons = var.cluster_addons

  vpc_id     = var.vpc_id
  subnet_ids = var.subnet_ids

  eks_managed_node_group_defaults = var.eks_managed_node_group_defaults
  eks_managed_node_groups         = var.eks_managed_node_groups
}

output "cluster_name" {
  value = module.eks.cluster_name
}

output "oidc_provider" {
  value = module.eks.oidc_provider
}

output "cluster_endpoint" {
  value = module.eks.cluster_endpoint
}

output "cluster_certificate_authority_data" {
  value = module.eks.cluster_certificate_authority_data
}

output "cluster_security_group_id" {
  value = module.eks.cluster_security_group_id
}

// Karpenter and other tooling variables/resources moved to eks-tools module

variable "cluster_name" { type = string }
variable "cluster_version" { type = string }
variable "cluster_endpoint_public_access" { type = bool }
variable "enable_cluster_creator_admin_permissions" { type = bool }
variable "cluster_addons" { type = any }
variable "vpc_id" { type = string }
variable "subnet_ids" { type = list(string) }
variable "eks_managed_node_group_defaults" { type = any }
variable "eks_managed_node_groups" { type = any }


