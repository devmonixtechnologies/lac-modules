variable "name" {
  description = "Name of the ECS cluster"
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
  description = "Component identifier"
  type        = string
  default     = "ecs-cluster"
}

variable "enable_container_insights" {
  description = "Enable CloudWatch Container Insights"
  type        = bool
  default     = true
}

variable "execute_command_configuration" {
  description = "Configuration for ECS Exec"
  type = object({
    kms_key_id = optional(string)
    logging    = optional(string)
    log_configuration = optional(object({
      cloud_watch_encryption_enabled = optional(bool)
      cloud_watch_log_group_name     = optional(string)
      s3_bucket_name                 = optional(string)
      s3_encryption_enabled          = optional(bool)
      s3_key_prefix                  = optional(string)
    }))
  })
  default = null
}

variable "service_connect_defaults" {
  description = "Default Service Connect namespace configuration"
  type = object({
    namespace = string
  })
  default = null
}

variable "capacity_providers" {
  description = "List of capacity providers to associate"
  type        = list(string)
  default     = []
}

variable "default_capacity_provider_strategy" {
  description = "Default capacity provider strategies"
  type = list(object({
    capacity_provider = string
    weight            = optional(number)
    base              = optional(number)
  }))
  default = []
}

variable "tags" {
  description = "Additional tags"
  type        = map(string)
  default     = {}
}

variable "tags_override" {
  description = "Tags that override module defaults"
  type        = map(string)
  default     = {}
}
