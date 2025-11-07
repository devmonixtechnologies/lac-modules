variable "name" {
  description = "Friendly name assigned to VPC"
  type        = string
}

variable "environment" {
  description = "Environment identifier (dev, stage, prod)"
  type        = string
}

variable "service" {
  description = "Service or application name"
  type        = string
  default     = "network"
}

variable "component" {
  description = "Component name for tagging"
  type        = string
  default     = "vpc"
}

variable "cidr_block" {
  description = "Primary IPv4 CIDR block"
  type        = string
}

variable "secondary_cidr_blocks" {
  description = "Optional secondary CIDR blocks"
  type        = list(string)
  default     = []
}

variable "enable_dns_support" {
  description = "Enable DNS support within the VPC"
  type        = bool
  default     = true
}

variable "enable_dns_hostnames" {
  description = "Enable DNS hostnames"
  type        = bool
  default     = true
}

variable "enable_flow_logs" {
  description = "Toggle creation of VPC flow logs"
  type        = bool
  default     = true
}

variable "flow_log_destination_type" {
  description = "Destination for VPC flow logs (cloud-watch-logs or s3)"
  type        = string
  default     = "cloud-watch-logs"
  validation {
    condition     = contains(["cloud-watch-logs", "s3"], var.flow_log_destination_type)
    error_message = "flow_log_destination_type must be cloud-watch-logs or s3"
  }
}

variable "flow_log_cloudwatch_log_group_name" {
  description = "Optional existing CloudWatch log group name"
  type        = string
  default     = ""
}

variable "flow_log_cloudwatch_role_arn" {
  description = "IAM role ARN allowing flow logs to publish to CloudWatch"
  type        = string
  default     = ""
}

variable "flow_log_s3_arn" {
  description = "S3 bucket ARN for flow logs when destination type is s3"
  type        = string
  default     = ""
}

variable "flow_log_cloudwatch_retention_days" {
  description = "Retention in days for CloudWatch log group"
  type        = number
  default     = 90
}

variable "flow_log_traffic_type" {
  description = "Type of traffic to capture (ACCEPT, REJECT, ALL)"
  type        = string
  default     = "ALL"
}

variable "tags" {
  description = "Additional shared tags"
  type        = map(string)
  default     = {}
}

variable "tags_override" {
  description = "Tags that override module defaults"
  type        = map(string)
  default     = {}
}
