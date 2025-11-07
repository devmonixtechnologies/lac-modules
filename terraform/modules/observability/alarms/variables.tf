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
  description = "Component label for tagging"
  type        = string
  default     = "service-alarms"
}

variable "cluster_name" {
  description = "ECS cluster name"
  type        = string
}

variable "service_name" {
  description = "ECS service name"
  type        = string
}

variable "enable_cpu_alarm" {
  description = "Enable high CPU alarm"
  type        = bool
  default     = true
}

variable "cpu_alarm_name" {
  description = "Override name for CPU alarm"
  type        = string
  default     = ""
}

variable "cpu_alarm_description" {
  description = "Description for CPU alarm"
  type        = string
  default     = "ECS service CPU utilization high"
}

variable "cpu_threshold" {
  description = "CPU utilization threshold"
  type        = number
  default     = 80
}

variable "cpu_evaluation_periods" {
  description = "Evaluation periods for CPU alarm"
  type        = number
  default     = 3
}

variable "cpu_period" {
  description = "Period in seconds for CPU metric"
  type        = number
  default     = 60
}

variable "enable_memory_alarm" {
  description = "Enable high memory alarm"
  type        = bool
  default     = true
}

variable "memory_alarm_name" {
  description = "Override name for memory alarm"
  type        = string
  default     = ""
}

variable "memory_alarm_description" {
  description = "Description for memory alarm"
  type        = string
  default     = "ECS service memory utilization high"
}

variable "memory_threshold" {
  description = "Memory utilization threshold"
  type        = number
  default     = 80
}

variable "memory_evaluation_periods" {
  description = "Evaluation periods for memory alarm"
  type        = number
  default     = 3
}

variable "memory_period" {
  description = "Period in seconds for memory metric"
  type        = number
  default     = 60
}

variable "alarm_actions" {
  description = "Actions to execute when alarm triggered"
  type        = list(string)
  default     = []
}

variable "ok_actions" {
  description = "Actions to execute when alarm OK"
  type        = list(string)
  default     = []
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
