data "aws_ecr_repository" "existing_repo" {
  name = var.repository_name
}

resource "aws_ecr_repository" "repo" {
  count                = var.create_repository ? 1 : 0
  name                 = var.repository_name
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }

  tags = var.tags
}

# Add a lifecycle policy to manage image retention
resource "aws_ecr_lifecycle_policy" "repo_policy" {
  repository = var.create_repository ? aws_ecr_repository.repo[0].name : data.aws_ecr_repository.existing_repo.name

  policy = jsonencode({
    rules = [
      {
        rulePriority = 1
        description  = "Keep last 10 images"
        selection = {
          tagStatus     = "any"
          countType     = "imageCountMoreThan"
          countNumber   = 10
        }
        action = {
          type = "expire"
        }
      }
    ]
  })
}
