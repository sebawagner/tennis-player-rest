provider "aws" {
  region = var.aws_region
}

module "ecr" {
  source = "./modules/ecr"

  repository_name = var.ecr_repository_name
  tags            = var.tags
}

module "ecs" {
  source = "./modules/ecs"

  cluster_name    = var.ecs_cluster_name
  aws_region      = var.aws_region
  container_image = var.container_image != "" ? var.container_image : module.ecr.repository_url
  desired_count   = var.desired_count
  task_cpu        = var.task_cpu
  task_memory     = var.task_memory
  tags            = var.tags
}

# Output the ECR repository URL for easy reference
output "ecr_repository_url" {
  description = "The URL of the ECR repository"
  value       = module.ecr.repository_url
}

# Output the ECS application URL
output "application_url" {
  description = "The URL of the application"
  value       = module.ecs.alb_url
}
