variable "environment" {
  description = "Environment identifier"
  type        = string
}

variable "service" {
  description = "Service or team owning IAM baseline"
  type        = string
  default     = "security"
}

variable "name_prefix" {
  description = "Prefix for IAM entities created in this module"
  type        = string
  default     = "baseline"
}

variable "account_alias" {
  description = "Optional IAM account alias"
  type        = string
  default     = ""
}

variable "password_policy" {
  description = "Password policy configuration"
  type = object({
    minimum_length    = number
    require_lowercase = bool
    require_numbers   = bool
    require_symbols   = bool
    require_uppercase = bool
    allow_user_change = bool
    hard_expiry       = bool
    max_age           = number
    reuse_prevention  = number
  })
  default = {
    minimum_length    = 14
    require_lowercase = true
    require_numbers   = true
    require_symbols   = true
    require_uppercase = true
    allow_user_change = true
    hard_expiry       = false
    max_age           = 90
    reuse_prevention  = 24
  }
}

variable "enable_access_analyzer" {
  description = "Toggle deployment of IAM Access Analyzer"
  type        = bool
  default     = true
}

variable "access_log_retention_days" {
  description = "Retention period for IAM access log group"
  type        = number
  default     = 365
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
