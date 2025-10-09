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

output "eks_cluster_security_group_id" {
  value = module.eks.cluster_security_group_id
}

output "ecr_repository_url" {
  value       = module.ecr.aws_ecr_repository_url
  description = "URL of the ECR repository"
}

