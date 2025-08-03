output "repository_url" {
  description = "The URL of the ECR repository"
  value       = var.create_repository ? aws_ecr_repository.repo[0].repository_url : data.aws_ecr_repository.existing_repo.repository_url
}

output "repository_arn" {
  description = "The ARN of the ECR repository"
  value       = var.create_repository ? aws_ecr_repository.repo[0].arn : data.aws_ecr_repository.existing_repo.arn
}

output "repository_name" {
  description = "The name of the ECR repository"
  value       = var.create_repository ? aws_ecr_repository.repo[0].name : data.aws_ecr_repository.existing_repo.name
}
