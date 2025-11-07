variable "name" {
  description = "Name of the ECS service"
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
  default     = "ecs-service"
}

variable "cluster_arn" {
  description = "ARN of the ECS cluster"
  type        = string
}

variable "task_definition_arn" {
  description = "ARN of the task definition"
  type        = string
}

variable "desired_count" {
  description = "Number of tasks to desired run"
  type        = number
  default     = 2
}

variable "launch_type" {
  description = "Launch type (EC2 or FARGATE)"
  type        = string
  default     = "FARGATE"
  validation {
    condition     = contains(["EC2", "FARGATE"], var.launch_type)
    error_message = "launch_type must be EC2 or FARGATE"
  }
}

variable "platform_version" {
  description = "Platform version for Fargate"
  type        = string
  default     = "LATEST"
}

variable "scheduling_strategy" {
  description = "Service scheduling strategy"
  type        = string
  default     = "REPLICA"
}

variable "deployment_minimum_healthy_percent" {
  description = "Minimum healthy percentage for deployments"
  type        = number
  default     = 100
}

variable "deployment_maximum_percent" {
  description = "Maximum healthy percentage for deployments"
  type        = number
  default     = 200
}

variable "enable_execute_command" {
  description = "Enable ECS Exec"
  type        = bool
  default     = true
}

variable "force_new_deployment" {
  description = "Force new deployment on changes"
  type        = bool
  default     = false
}

variable "propagate_tags" {
  description = "Propagate tags to tasks"
  type        = string
  default     = "SERVICE"
}

variable "enable_ecs_managed_tags" {
  description = "Enable ECS managed tags"
  type        = bool
  default     = true
}

variable "wait_for_steady_state" {
  description = "Wait for the service to reach steady state"
  type        = bool
  default     = false
}

variable "health_check_grace_period_seconds" {
  description = "Health check grace period"
  type        = number
  default     = null
}

variable "subnets" {
  description = "Subnet IDs for awsvpc network mode"
  type        = list(string)
  default     = []
}

variable "security_groups" {
  description = "Security group IDs"
  type        = list(string)
  default     = []
}

variable "assign_public_ip" {
  description = "Assign public IP when using awsvpc"
  type        = bool
  default     = false
}

variable "load_balancers" {
  description = "Load balancer configurations"
  type = list(object({
    target_group_arn = string
    container_name   = string
    container_port   = number
  }))
  default = []
}

variable "service_registries" {
  description = "Service discovery registries"
  type = list(object({
    registry_arn   = string
    port           = optional(number)
    container_name = optional(string)
    container_port = optional(number)
  }))
  default = []
}

variable "deployment_circuit_breaker" {
  description = "Deployment circuit breaker configuration"
  type = object({
    enable   = bool
    rollback = bool
  })
  default = null
}

variable "deployment_controller" {
  description = "Deployment controller configuration"
  type = object({
    type = string
  })
  default = null
}

variable "capacity_provider_strategy" {
  description = "Capacity provider strategy"
  type = list(object({
    capacity_provider = string
    weight            = optional(number)
    base              = optional(number)
  }))
  default = []
}

variable "ordered_placement_strategy" {
  description = "Ordered placement strategies"
  type = list(object({
    type  = string
    field = optional(string)
  }))
  default = []
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
