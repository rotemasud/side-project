output "vpc_id" {
  value = module.vpc.vpc_id
}

output "private_subnets" {
  value = module.vpc.private_subnets
}

output "eks_cluster_name" {
  value = module.eks.cluster_name
}

output "eks_oidc_provider" {
  value = module.eks.oidc_provider
}

output "irsa_ebs_csi_role_arn" {
  value = module.irsa_ebs_csi.iam_role_arn
}

output "ecr_repository_url" {
  value       = module.ecr.aws_ecr_repository_url
  description = "URL of the ECR repository"
}

