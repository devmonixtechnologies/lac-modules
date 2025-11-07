variable "environment" {
  description = "Environment identifier (e.g., dev, stage, prod)"
  type        = string
}

variable "service" {
  description = "Service or application name"
  type        = string
  default     = ""
}

variable "component" {
  description = "Component within the service"
  type        = string
  default     = ""
}

variable "additional_tags" {
  description = "Additional tags to merge"
  type        = map(string)
  default     = {}
}
