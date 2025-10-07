data "aws_iam_policy_document" "karpenter_controller_trust" {
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]
    principals {
      type        = "Federated"
      identifiers = [data.aws_iam_openid_connect_provider.this.arn]
    }
    condition {
      test     = "StringEquals"
      variable = "${replace(module.eks.oidc_provider, "https://", "")}:sub"
      values   = ["system:serviceaccount:karpenter:karpenter"]
    }
    condition {
      test     = "StringEquals"
      variable = "${replace(module.eks.oidc_provider, "https://", "")}:aud"
      values   = ["sts.amazonaws.com"]
    }
  }
}

data "aws_iam_openid_connect_provider" "this" {
  url = module.eks.oidc_provider
}

resource "aws_iam_role" "karpenter_controller" {
  name               = "KarpenterControllerRole-${local.cluster_name}"
  assume_role_policy = data.aws_iam_policy_document.karpenter_controller_trust.json
}

# Minimal controller policy (based on Karpenter docs)
data "aws_iam_policy_document" "karpenter_controller_policy" {
  statement {
    sid     = "AllowEC2ReadAndProvisioning"
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
    sid     = "AllowPassNodeRole"
    actions = ["iam:PassRole"]
    resources = [aws_iam_role.karpenter_node.arn]
  }
  statement {
    sid     = "AllowInterruptionQueueAccess"
    actions = [
      "sqs:DeleteMessage",
      "sqs:GetQueueAttributes",
      "sqs:ReceiveMessage"
    ]
    resources = [aws_sqs_queue.karpenter_interruption.arn]
  }
}

resource "aws_iam_policy" "karpenter_controller" {
  name   = "KarpenterControllerPolicy-${local.cluster_name}"
  policy = data.aws_iam_policy_document.karpenter_controller_policy.json
}

resource "aws_iam_role_policy_attachment" "karpenter_controller_attach" {
  role       = aws_iam_role.karpenter_controller.name
  policy_arn = aws_iam_policy.karpenter_controller.arn
}

# Node role and instance profile
resource "aws_iam_role" "karpenter_node" {
  name = "KarpenterNodeRole-${local.cluster_name}"
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
  role       = aws_iam_role.karpenter_node.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
}

resource "aws_iam_role_policy_attachment" "node_cni" {
  role       = aws_iam_role.karpenter_node.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
}

resource "aws_iam_role_policy_attachment" "node_ecr" {
  role       = aws_iam_role.karpenter_node.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}

resource "aws_iam_instance_profile" "karpenter_node" {
  name = "KarpenterNodeInstanceProfile-${local.cluster_name}"
  role = aws_iam_role.karpenter_node.name
}


