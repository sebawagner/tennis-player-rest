variable "repository_name" {
  description = "Name of the ECR repository"
  type        = string
}

variable "create_repository" {
  description = "Whether to create a new ECR repository or use an existing one"
  type        = bool
  default     = true
}

variable "tags" {
  description = "Tags to apply to the ECR repository"
  type        = map(string)
  default     = {}
}
