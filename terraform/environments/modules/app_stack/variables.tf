variable "environment" {
  description = "Deployment environment identifier"
  type        = string
}

variable "region" {
  description = "AWS region for resources"
  type        = string
}

variable "name_prefix" {
  description = "Prefix applied to core resource names"
  type        = string
}

variable "service_name" {
  description = "Service or application name"
  type        = string
}

variable "component_name" {
  description = "Component name used for tagging"
  type        = string
  default     = "app"
}

variable "tags" {
  description = "Base tags applied to all resources"
  type        = map(string)
  default     = {}
}

variable "vpc_cidr_block" {
  description = "Primary CIDR block for the VPC"
  type        = string
}

variable "vpc_secondary_cidr_blocks" {
  description = "Optional secondary CIDR blocks"
  type        = list(string)
  default     = []
}

variable "enable_flow_logs" {
  description = "Whether to enable VPC flow logs"
  type        = bool
  default     = true
}

variable "flow_log_destination_type" {
  description = "Flow log destination (cloud-watch-logs or s3)"
  type        = string
  default     = "cloud-watch-logs"
}

variable "flow_log_cloudwatch_log_group_name" {
  description = "Existing CloudWatch log group name for flow logs"
  type        = string
  default     = ""
}

variable "flow_log_cloudwatch_role_arn" {
  description = "Role ARN for publishing flow logs to CloudWatch"
  type        = string
  default     = ""
}

variable "flow_log_cloudwatch_retention_days" {
  description = "Retention days for CloudWatch flow logs"
  type        = number
  default     = 90
}

variable "flow_log_s3_arn" {
  description = "S3 bucket ARN for flow logs when destination is s3"
  type        = string
  default     = ""
}

variable "flow_log_traffic_type" {
  description = "Traffic type captured by flow logs"
  type        = string
  default     = "ALL"
}

variable "public_subnets" {
  description = "Definitions of public subnets"
  type = list(object({
    name        = string
    cidr_block  = string
    az          = string
    tier        = optional(string)
    map_public_ip_on_launch = optional(bool)
  }))
}

variable "private_subnets" {
  description = "Definitions of private subnets"
  type = list(object({
    name        = string
    cidr_block  = string
    az          = string
    tier        = optional(string)
    map_public_ip_on_launch = optional(bool)
  }))
}

variable "additional_ingress_cidr_blocks" {
  description = "Additional CIDR blocks for ECS security group ingress"
  type        = list(string)
  default     = []
}

variable "additional_ingress_security_group_ids" {
  description = "Security group IDs allowed inbound access"
  type        = list(string)
  default     = []
}

variable "container_port" {
  description = "Container/application port"
  type        = number
}

variable "container_image" {
  description = "Container image for ECS task"
  type        = string
}

variable "container_cpu" {
  description = "CPU units for task definition"
  type        = number
  default     = 256
}

variable "container_memory" {
  description = "Memory (MB) for task definition"
  type        = number
  default     = 512
}

variable "cpu_architecture" {
  description = "CPU architecture for task definition"
  type        = string
  default     = "X86_64"
}

variable "log_retention_in_days" {
  description = "Application log retention in days"
  type        = number
  default     = 30
}

variable "log_kms_key_id" {
  description = "Optional KMS key ARN for application log group"
  type        = string
  default     = ""
}

variable "log_subscription_destination_arn" {
  description = "Destination ARN for application log subscription"
  type        = string
  default     = ""
}

variable "log_subscription_role_arn" {
  description = "IAM role ARN used for log subscription"
  type        = string
  default     = ""
}

variable "log_subscription_create_role" {
  description = "Create IAM role for log subscription when ARN not provided"
  type        = bool
  default     = false
}

variable "log_subscription_role_name" {
  description = "Name for created log subscription IAM role"
  type        = string
  default     = ""
}

variable "log_subscription_role_policy_statements" {
  description = "Policy statements for created log subscription role"
  type = list(object({
    effect    = optional(string, "Allow")
    actions   = list(string)
    resources = list(string)
  }))
  default = []
}

variable "log_subscription_filter_pattern" {
  description = "Filter pattern for log subscription"
  type        = string
  default     = ""
}

variable "log_subscription_distribution" {
  description = "Distribution mode for log subscription"
  type        = string
  default     = "ByLogStream"
}

variable "create_log_processor_lambda" {
  description = "Whether to provision a log processor Lambda via module"
  type        = bool
  default     = false
}

variable "log_processor_lambda_config" {
  description = "Configuration for the optional log processor Lambda"
  type = object({
    function_name           = optional(string)
    runtime                 = optional(string)
    handler                 = optional(string)
    source_dir              = optional(string)
    package_file            = optional(string)
    create_role             = optional(bool)
    role_name               = optional(string)
    role_arn                = optional(string)
    role_policy_statements  = optional(list(object({
      effect    = optional(string, "Allow")
      actions   = list(string)
      resources = list(string)
    })))
    environment_variables   = optional(map(string))
    timeout                 = optional(number)
    memory_size             = optional(number)
    tags                    = optional(map(string))
  })
  default = {
    function_name = null
  }
}

variable "create_log_processor_firehose" {
  description = "Whether to provision a Firehose delivery stream"
  type        = bool
  default     = false
}

variable "log_processor_firehose_config" {
  description = "Configuration for the optional Firehose processor"
  type = object({
    stream_name             = optional(string)
    s3_bucket_arn           = optional(string)
    buffer_size             = optional(number)
    buffer_interval_seconds = optional(number)
    compression_format      = optional(string)
    prefix                  = optional(string)
    error_output_prefix     = optional(string)
    kms_key_arn             = optional(string)
    role_arn                = optional(string)
    role_name               = optional(string)
    role_policy_statements  = optional(list(map(any)))
    tags                    = optional(map(string))
  })
  default = {
    stream_name = null
  }
}

variable "task_environment" {
  description = "Environment variables for the ECS task"
  type        = map(string)
  default     = {}
}

variable "enable_container_insights" {
  description = "Enable ECS container insights"
  type        = bool
  default     = true
}

variable "execute_command_configuration" {
  description = "ECS Exec configuration"
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
  description = "Default namespace for ECS Service Connect"
  type = object({
    namespace = string
  })
  default = null
}

variable "capacity_providers" {
  description = "Cluster capacity providers"
  type        = list(string)
  default     = []
}

variable "default_capacity_provider_strategy" {
  description = "Default capacity provider strategy"
  type = list(object({
    capacity_provider = string
    weight            = optional(number)
    base              = optional(number)
  }))
  default = []
}

variable "desired_count" {
  description = "Desired ECS service task count"
  type        = number
  default     = 2
}

variable "launch_type" {
  description = "ECS launch type"
  type        = string
  default     = "FARGATE"
}

variable "platform_version" {
  description = "Platform version for Fargate tasks"
  type        = string
  default     = "LATEST"
}

variable "scheduling_strategy" {
  description = "Scheduling strategy for ECS service"
  type        = string
  default     = "REPLICA"
}

variable "deployment_minimum_healthy_percent" {
  description = "Minimum healthy percentage during deployments"
  type        = number
  default     = 100
}

variable "deployment_maximum_percent" {
  description = "Maximum healthy percentage during deployments"
  type        = number
  default     = 200
}

variable "enable_execute_command" {
  description = "Enable ECS Exec"
  type        = bool
  default     = true
}

variable "force_new_deployment" {
  description = "Force service redeployment on change"
  type        = bool
  default     = false
}

variable "propagate_tags" {
  description = "Source for tag propagation"
  type        = string
  default     = "SERVICE"
}

variable "enable_ecs_managed_tags" {
  description = "Enable ECS managed tags"
  type        = bool
  default     = true
}

variable "wait_for_steady_state" {
  description = "Wait for ECS service to reach steady state"
  type        = bool
  default     = false
}

variable "health_check_grace_period_seconds" {
  description = "Health check grace period"
  type        = number
  default     = null
}

variable "assign_public_ip" {
  description = "Assign public IPs to tasks"
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
  description = "Service discovery registry configurations"
  type = list(object({
    registry_arn   = string
    port           = optional(number)
    container_name = optional(string)
    container_port = optional(number)
  }))
  default = []
}

variable "deployment_circuit_breaker" {
  description = "Deployment circuit breaker settings"
  type = object({
    enable   = bool
    rollback = bool
  })
  default = null
}

variable "deployment_controller" {
  description = "Deployment controller settings"
  type = object({
    type = string
  })
  default = null
}

variable "capacity_provider_strategy" {
  description = "Capacity provider strategy entries"
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

variable "alarm_enable_cpu" {
  description = "Enable CPU utilization alarm"
  type        = bool
  default     = true
}

variable "alarm_cpu_threshold" {
  description = "CPU utilization threshold percentage"
  type        = number
  default     = 80
}

variable "alarm_cpu_evaluation_periods" {
  description = "Number of evaluation periods for CPU alarm"
  type        = number
  default     = 3
}

variable "alarm_cpu_period" {
  description = "CPU alarm metric period in seconds"
  type        = number
  default     = 60
}

variable "alarm_enable_memory" {
  description = "Enable memory utilization alarm"
  type        = bool
  default     = true
}

variable "alarm_memory_threshold" {
  description = "Memory utilization threshold percentage"
  type        = number
  default     = 80
}

variable "alarm_memory_evaluation_periods" {
  description = "Number of evaluation periods for memory alarm"
  type        = number
  default     = 3
}

variable "alarm_memory_period" {
  description = "Memory alarm metric period in seconds"
  type        = number
  default     = 60
}

variable "alarm_actions" {
  description = "Actions to execute when alarm fires"
  type        = list(string)
  default     = []
}

variable "alarm_ok_actions" {
  description = "Actions to execute when alarm returns to OK"
  type        = list(string)
  default     = []
}

variable "enable_dashboard" {
  description = "Enable creation of service overview dashboard"
  type        = bool
  default     = false
}

variable "dashboard_template_path" {
  description = "Path to dashboard template file"
  type        = string
  default     = ""
  validation {
    condition     = var.dashboard_template_path == "" ? true : fileexists(var.dashboard_template_path)
    error_message = "dashboard_template_path must reference an existing file"
  }
}

variable "dashboard_template_context" {
  description = "Additional variables merged into dashboard template context"
  type        = map(any)
  default     = {}
}

variable "dashboard_template_variant" {
  description = "Named template variant to use when path is not provided (e.g., overview, health)"
  type        = string
  default     = "overview"
  validation {
    condition     = contains(["overview", "health"], var.dashboard_template_variant)
    error_message = "dashboard_template_variant must be one of: overview, health"
  }
}
