resource "aws_ec2_tag" "private_subnets_discovery" {
  for_each = toset(module.vpc.private_subnets)
  resource_id = each.value
  key         = "karpenter.sh/discovery"
  value       = local.cluster_name
}

# Tag the cluster security group with discovery tag (uses module.eks output if needed)
data "aws_security_group" "cluster" {
  id = module.eks.cluster_security_group_id
}

resource "aws_ec2_tag" "cluster_sg_discovery" {
  resource_id = data.aws_security_group.cluster.id
  key         = "karpenter.sh/discovery"
  value       = local.cluster_name
}


