data "aws_iam_policy_document" "karpenter_controller_trust" {
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]
    principals {
      type        = "Federated"
      identifiers = [data.aws_iam_openid_connect_provider.this.arn]
    }
    condition {
      test     = "StringEquals"
      variable = "${replace(var.oidc_provider, "https://", "")}:sub"
      values   = ["system:serviceaccount:karpenter:karpenter"]
    }
    condition {
      test     = "StringEquals"
      variable = "${replace(var.oidc_provider, "https://", "")}:aud"
      values   = ["sts.amazonaws.com"]
    }
  }
}

data "aws_iam_openid_connect_provider" "this" {
  url = var.oidc_provider
}

resource "aws_iam_role" "karpenter_controller" {
  count              = var.karpenter_enabled ? 1 : 0
  name               = "KarpenterControllerRole-${var.cluster_name}"
  assume_role_policy = data.aws_iam_policy_document.karpenter_controller_trust.json
}

# Minimal controller policy (based on Karpenter docs)
data "aws_iam_policy_document" "karpenter_controller_policy" {
  statement {
    sid = "AllowEC2ReadAndProvisioning"
    actions = [
      "ec2:CreateLaunchTemplate",
      "ec2:DeleteLaunchTemplate",
      "ec2:CreateFleet",
      "ec2:RunInstances",
      "ec2:CreateTags",
      "ec2:Describe*",
      "ssm:GetParameter",
      "pricing:GetProducts"
    ]
    resources = ["*"]
  }
  statement {
    sid       = "AllowPassNodeRole"
    actions   = ["iam:PassRole"]
    resources = var.karpenter_enabled ? [aws_iam_role.karpenter_node[0].arn] : []
  }
  statement {
    sid = "AllowInterruptionQueueAccess"
    actions = [
      "sqs:DeleteMessage",
      "sqs:GetQueueAttributes",
      "sqs:ReceiveMessage"
    ]
    resources = var.karpenter_enabled ? [aws_sqs_queue.karpenter_interruption[0].arn] : []
  }
}

resource "aws_iam_policy" "karpenter_controller" {
  count  = var.karpenter_enabled ? 1 : 0
  name   = "KarpenterControllerPolicy-${var.cluster_name}"
  policy = data.aws_iam_policy_document.karpenter_controller_policy.json
}

resource "aws_iam_role_policy_attachment" "karpenter_controller_attach" {
  count      = var.karpenter_enabled ? 1 : 0
  role       = aws_iam_role.karpenter_controller[0].name
  policy_arn = aws_iam_policy.karpenter_controller[0].arn
}

# Node role and instance profile
resource "aws_iam_role" "karpenter_node" {
  count = var.karpenter_enabled ? 1 : 0
  name  = "KarpenterNodeRole-${var.cluster_name}"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect = "Allow",
      Principal = {
        Service = ["ec2.amazonaws.com"]
      },
      Action = ["sts:AssumeRole"]
    }]
  })
}

resource "aws_iam_role_policy_attachment" "node_eks_worker" {
  count      = var.karpenter_enabled ? 1 : 0
  role       = aws_iam_role.karpenter_node[0].name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
}

resource "aws_iam_role_policy_attachment" "node_cni" {
  count      = var.karpenter_enabled ? 1 : 0
  role       = aws_iam_role.karpenter_node[0].name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
}

resource "aws_iam_role_policy_attachment" "node_ecr" {
  count      = var.karpenter_enabled ? 1 : 0
  role       = aws_iam_role.karpenter_node[0].name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}

resource "aws_iam_instance_profile" "karpenter_node" {
  count = var.karpenter_enabled ? 1 : 0
  name  = "KarpenterNodeInstanceProfile-${var.cluster_name}"
  role  = aws_iam_role.karpenter_node[0].name
}


