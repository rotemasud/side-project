data "aws_iam_policy" "ebs_csi_policy" {
  arn = "arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy"
}

module "irsa_ebs_csi" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-assumable-role-with-oidc"
  version = "5.39.0"

  create_role                   = true
  role_name                     = "AmazonEKSTFEBSCSIRole-${var.cluster_name}"
  provider_url                  = var.provider_url
  role_policy_arns              = [data.aws_iam_policy.ebs_csi_policy.arn]
  oidc_fully_qualified_subjects = var.oidc_fully_qualified_subjects
}

output "iam_role_arn" {
  value = module.irsa_ebs_csi.iam_role_arn
}

variable "cluster_name" { type = string }
variable "provider_url" { type = string }
variable "oidc_fully_qualified_subjects" {
  type    = list(string)
  default = ["system:serviceaccount:kube-system:ebs-csi-controller-sa"]
}


