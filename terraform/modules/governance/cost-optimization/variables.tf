variable "environment" {
  description = "Environment name (e.g., dev, stage, prod)"
  type        = string
}

variable "service" {
  description = "Service name"
  type        = string
}

variable "tags" {
  description = "Additional tags to apply to resources"
  type        = map(string)
  default     = {}
}

variable "tags_override" {
  description = "Tags that override default tags"
  type        = map(string)
  default     = {}
}

variable "enable_cost_anomaly_detection" {
  description = "Enable AWS Cost Anomaly Detection"
  type        = bool
  default     = true
}

variable "monitored_services" {
  description = "List of AWS services to monitor for cost anomalies"
  type        = list(string)
  default     = ["Amazon EC2", "Amazon ECS", "Amazon EKS", "Amazon RDS"]
}

variable "anomaly_detection_frequency" {
  description = "Frequency of anomaly detection notifications"
  type        = string
  default     = "DAILY"
}

variable "anomaly_notification_email" {
  description = "Email address for anomaly notifications"
  type        = string
  default     = ""
}

variable "anomaly_sns_topic_arn" {
  description = "SNS topic ARN for anomaly notifications"
  type        = string
  default     = ""
}

variable "anomaly_severity_levels" {
  description = "Severity levels for anomaly detection"
  type        = list(string)
  default     = ["HIGH", "MEDIUM", "LOW"]
}

variable "cost_allocation_tags" {
  description = "Cost allocation tags configuration"
  type = map(object({
    active = bool
  }))
  default = {}
}

variable "budgets" {
  description = "AWS Budgets configuration"
  type = map(object({
    budget_type       = string
    time_unit         = string
    time_period_start = string
    limit_amount      = object({
      amount = number
      unit   = optional(string, "USD")
    })
    cost_filters = optional(map(list(string)), {})
    cost_types   = optional(object({
      include_credit             = optional(bool, true)
      include_discount          = optional(bool, true)
      include_other_subscription = optional(bool, true)
      include_recurring         = optional(bool, true)
      include_refund             = optional(bool, true)
      include_subscription      = optional(bool, true)
      include_support           = optional(bool, true)
      include_tax               = optional(bool, true)
      include_upfront           = optional(bool, true)
      use_amortized             = optional(bool, false)
      use_blended              = optional(bool, false)
    }), null)
    notifications = list(object({
      comparison_operator        = string
      threshold                  = number
      threshold_type             = string
      notification_type          = string
      subscriber_email_addresses = list(string)
      subscriber_sns_topic_arns  = list(string)
    }))
  }))
  default = {}
}

variable "create_sns_topic" {
  description = "Create SNS topic for budget notifications"
  type        = bool
  default     = true
}

variable "enable_automated_optimization" {
  description = "Enable automated cost optimization Lambda"
  type        = bool
  default     = false
}

variable "optimization_schedule" {
  description = "Schedule for cost optimization Lambda (cron expression)"
  type        = string
  default     = "rate(24 hours)"
}

variable "optimization_log_level" {
  description = "Log level for cost optimization Lambda"
  type        = string
  default     = "INFO"
}

variable "enable_spot_datafeed" {
  description = "Enable Spot Instance data feed"
  type        = bool
  default     = false
}

variable "spot_datafeed_bucket" {
  description = "S3 bucket for Spot Instance data feed"
  type        = string
  default     = ""
}

variable "spot_datafeed_prefix" {
  description = "Prefix for Spot Instance data feed"
  type        = string
  default     = "spot-datafeed"
}

variable "enable_cost_categories" {
  description = "Enable AWS Cost Categories"
  type        = bool
  default     = false
}

variable "cost_category_rules" {
  description = "Cost category rules"
  type = list(object({
    value = string
    inherited_value = optional(object({
      dimension_name = string
      dimension_key  = string
    }), null)
    type = optional(object({
      dimension      = string
      key            = string
      match_options  = list(string)
      values         = list(string)
    }), null)
  }))
  default = []
}

variable "region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}
