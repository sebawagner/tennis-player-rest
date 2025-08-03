variable "cluster_name" {
  description = "Name of the ECS cluster"
  type        = string
  default     = "tennis-player-cluster"
}

variable "aws_region" {
  description = "AWS region to deploy resources in"
  type        = string
}

variable "availability_zones" {
  description = "List of availability zones to use for the subnets"
  type        = list(string)
  default     = ["us-east-1a", "us-east-1b"]
}

variable "container_image" {
  description = "ECR image URI for the application container"
  type        = string
  default     = "121022298217.dkr.ecr.us-east-1.amazonaws.com/tennis-player-rest:0.0.1-SNAPSHOT"
}

variable "task_cpu" {
  description = "CPU units for the ECS task (1 vCPU = 1024 CPU units)"
  type        = number
  default     = 256
}

variable "task_memory" {
  description = "Memory for the ECS task in MiB"
  type        = number
  default     = 512
}

variable "desired_count" {
  description = "Number of instances of the task to run"
  type        = number
  default     = 1
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}
