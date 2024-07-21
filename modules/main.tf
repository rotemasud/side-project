module "ecr" {
  source = "terraform-aws-modules/ecr/aws"
  version = "2.2.1"

  repository_name = "rotem-repo"
  repository_read_write_access_arns = ["arn:aws:iam::012345678901:role/terraform"]
  repository_lifecycle_policy = jsonencode({
    rules = [
      {
        rulePriority = 1
        description = "Keep last 30 images"
        selection = {
          tagStatus = "tagged"
          tagPrefixList = ["v"]
          countType = "imageCountMoreThan"
          countNumber = 30
        }
        action = { type = "expire" }
      }
    ]
  })

  tags = {
    Terraform = "true"
    Environment = "dev"
  }
}

