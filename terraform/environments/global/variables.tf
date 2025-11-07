variable "region" {
  description = "AWS region where global resources are deployed"
  type        = string
}

variable "state_bucket_name" {
  description = "S3 bucket for Terraform remote state"
  type        = string
}

variable "state_bucket_force_destroy" {
  description = "Allow destroy of the state bucket"
  type        = bool
  default     = false
}

variable "state_dynamodb_table_name" {
  description = "DynamoDB table for state locking"
  type        = string
}

variable "tags" {
  description = "Shared tags applied to global resources"
  type        = map(string)
  default     = {}
}
