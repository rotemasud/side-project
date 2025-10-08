resource "aws_ec2_tag" "private_subnets_discovery" {
  for_each = toset(var.private_subnets)
  resource_id = each.value
  key         = "karpenter.sh/discovery"
  value       = var.cluster_name
}

# Tag the cluster security group with discovery tag
data "aws_security_group" "cluster" {
  id = var.cluster_security_group_id
}

resource "aws_ec2_tag" "cluster_sg_discovery" {
  resource_id = data.aws_security_group.cluster.id
  key         = "karpenter.sh/discovery"
  value       = var.cluster_name
}
