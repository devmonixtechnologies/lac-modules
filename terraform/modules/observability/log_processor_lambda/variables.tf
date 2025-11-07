variable "function_name" {
  description = "Name of the Lambda function"
  type        = string
}

variable "runtime" {
  description = "Lambda runtime"
  type        = string
  default     = "python3.11"
}

variable "handler" {
  description = "Lambda handler"
  type        = string
  default     = "handler.lambda_handler"
}

variable "source_dir" {
  description = "Directory containing Lambda source code"
  type        = string
  default     = ""
}

variable "package_file" {
  description = "Pre-built ZIP package for Lambda (mutually exclusive with source_dir)"
  type        = string
  default     = ""
}

variable "create_role" {
  description = "Whether to create an IAM role for the Lambda"
  type        = bool
  default     = true
}

variable "role_name" {
  description = "Custom name for the IAM role when create_role is true"
  type        = string
  default     = ""
}

variable "role_arn" {
  description = "Existing IAM role ARN when create_role is false"
  type        = string
  default     = ""
}

variable "role_policy_statements" {
  description = "Inline policy statements applied to the created role"
  type = list(object({
    effect    = optional(string, "Allow")
    actions   = list(string)
    resources = list(string)
  }))
  default = []
}

variable "environment_variables" {
  description = "Environment variables for the Lambda function"
  type        = map(string)
  default     = {}
}

variable "timeout" {
  description = "Lambda timeout in seconds"
  type        = number
  default     = 60
}

variable "memory_size" {
  description = "Lambda memory in MB"
  type        = number
  default     = 128
}

variable "tags" {
  description = "Tags applied to IAM role and Lambda function"
  type        = map(string)
  default     = {}
}
