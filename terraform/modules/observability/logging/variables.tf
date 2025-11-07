variable "region" {
  description = "AWS region where the log group resides"
  type        = string
}

variable "name" {
  description = "Name of the CloudWatch log group"
  type        = string
}

variable "environment" {
  description = "Environment identifier"
  type        = string
}

variable "service" {
  description = "Service or application name"
  type        = string
  default     = "platform"
}

variable "component" {
  description = "Component identifier for tagging"
  type        = string
  default     = "logging"
}

variable "retention_in_days" {
  description = "Retention period in days"
  type        = number
  default     = 30
}

variable "kms_key_id" {
  description = "Optional KMS key ARN for log group encryption"
  type        = string
  default     = ""
}

variable "subscription_filter_name" {
  description = "Optional name for the log subscription filter"
  type        = string
  default     = ""
}

variable "subscription_destination_arn" {
  description = "Destination ARN for the log subscription (Kinesis, Firehose, Lambda)"
  type        = string
  default     = ""
}

variable "subscription_role_arn" {
  description = "IAM role ARN assumed when publishing to the subscription destination"
  type        = string
  default     = ""
}

variable "subscription_create_role" {
  description = "Whether to create an IAM role for the subscription when ARN not supplied"
  type        = bool
  default     = false
}

variable "subscription_role_name" {
  description = "Name for the auto-created subscription IAM role"
  type        = string
  default     = ""
}

variable "subscription_role_policy_statements" {
  description = "Policy statements attached to the subscription IAM role"
  type = list(object({
    effect    = optional(string, "Allow")
    actions   = list(string)
    resources = list(string)
  }))
  default = []
}

variable "subscription_filter_pattern" {
  description = "Filter pattern applied to the subscription"
  type        = string
  default     = ""
}

variable "subscription_distribution" {
  description = "Subscription distribution mode"
  type        = string
  default     = "ByLogStream"
}

variable "tags" {
  description = "Additional tags"
  type        = map(string)
  default     = {}
}

variable "tags_override" {
  description = "Tags overriding defaults"
  type        = map(string)
  default     = {}
}
