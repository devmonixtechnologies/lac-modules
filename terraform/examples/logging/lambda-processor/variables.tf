variable "region" {
  description = "AWS region for deployment"
  type        = string
}

variable "name" {
  description = "Base name for Lambda resources"
  type        = string
}

variable "environment_variables" {
  description = "Environment variables passed to the Lambda function"
  type        = map(string)
  default     = {}
}
