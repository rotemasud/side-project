resource "aws_ecr_repository" "main" {
  name                 = "side-project-repo"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = false
  }
}

resource "aws_ecr_lifecycle_policy" "main" {
  repository = aws_ecr_repository.main.name

  policy = jsonencode({
    rules = [{
      rulePriority = 1
      description  = "keep last 10 images"
      action = {
        type = "expire"
      }
      selection = {
        tagStatus   = "any"
        countType   = "imageCountMoreThan"
        countNumber = 10
      }
    }]
  })
}

output "aws_ecr_repository_url" {
  value = aws_ecr_repository.main.repository_url
}

output "aws_ecr_repository_arn" {
  value = aws_ecr_repository.main.arn
}

output "aws_ecr_repository_name" {
  value = aws_ecr_repository.main.name
}
