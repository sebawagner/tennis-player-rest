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

  cluster_name          = var.ecs_cluster_name
  aws_region            = var.aws_region
  container_image       = var.container_image != "" ? var.container_image : module.ecr.repository_url
  desired_count         = var.desired_count
  task_cpu              = var.task_cpu
  task_memory           = var.task_memory
  new_relic_license_key = var.new_relic_license_key
  tags                  = var.tags
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

# Output AWS region
output "aws_region" {
  description = "The AWS region where resources are deployed"
  value       = var.aws_region
}

# Output ECS cluster name
output "ecs_cluster_name" {
  description = "The name of the ECS cluster"
  value       = module.ecs.cluster_name
}

# Output ECS service name
output "ecs_service_name" {
  description = "The name of the ECS service"
  value       = module.ecs.service_name
}
