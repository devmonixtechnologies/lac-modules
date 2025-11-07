variable "stream_name" {
  description = "Name of the Firehose delivery stream"
  type        = string
}

variable "s3_bucket_arn" {
  description = "Destination S3 bucket ARN"
  type        = string
}

variable "buffer_size" {
  description = "Buffer size in MB"
  type        = number
  default     = 5
}

variable "buffer_interval_seconds" {
  description = "Buffer interval in seconds"
  type        = number
  default     = 300
}

variable "compression_format" {
  description = "Compression format for delivery"
  type        = string
  default     = "GZIP"
}

variable "prefix" {
  description = "S3 prefix for delivered data"
  type        = string
  default     = "logs/"
}

variable "error_output_prefix" {
  description = "S3 prefix for error data"
  type        = string
  default     = "errors/"
}

variable "kms_key_arn" {
  description = "Optional KMS key ARN for encryption"
  type        = string
  default     = ""
}

variable "role_arn" {
  description = "Existing IAM role ARN used by Firehose"
  type        = string
  default     = ""
}

variable "role_name" {
  description = "IAM role name when creating role"
  type        = string
  default     = ""
}

variable "role_policy_statements" {
  description = "Policy statements applied to created role"
  type        = list(map(any))
  default     = []
}

variable "tags" {
  description = "Tags applied to resources"
  type        = map(string)
  default     = {}
}
