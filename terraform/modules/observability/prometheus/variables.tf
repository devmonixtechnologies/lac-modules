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

variable "namespace" {
  description = "Kubernetes namespace for Prometheus"
  type        = string
  default     = null
}

variable "create_namespace" {
  description = "Whether to create the Kubernetes namespace"
  type        = bool
  default     = true
}

variable "release_name" {
  description = "Helm release name"
  type        = string
  default     = "prometheus"
}

variable "helm_chart_version" {
  description = "Version of the kube-prometheus-stack Helm chart"
  type        = string
  default     = "45.0.0"
}

variable "retention_period" {
  description = "Prometheus data retention period"
  type        = string
  default     = "15d"
}

variable "enable_persistence" {
  description = "Enable persistent storage for Prometheus"
  type        = bool
  default     = true
}

variable "storage_class" {
  description = "Storage class for Prometheus persistent volume"
  type        = string
  default     = "gp2"
}

variable "storage_size" {
  description = "Storage size for Prometheus"
  type        = string
  default     = "50Gi"
}

variable "prometheus_resources" {
  description = "Resource limits and requests for Prometheus"
  type = object({
    limits = object({
      cpu    = string
      memory = string
    })
    requests = object({
      cpu    = string
      memory = string
    })
  })
  default = {
    limits = {
      cpu    = "1000m"
      memory = "2Gi"
    }
    requests = {
      cpu    = "500m"
      memory = "1Gi"
    }
  }
}

variable "enable_grafana" {
  description = "Enable Grafana deployment"
  type        = bool
  default     = true
}

variable "grafana_admin_password" {
  description = "Admin password for Grafana"
  type        = string
  default     = "admin"
  sensitive   = true
}

variable "grafana_persistence_enabled" {
  description = "Enable persistent storage for Grafana"
  type        = bool
  default     = true
}

variable "grafana_storage_size" {
  description = "Storage size for Grafana"
  type        = string
  default     = "10Gi"
}

variable "grafana_storage_class" {
  description = "Storage class for Grafana"
  type        = string
  default     = "gp2"
}

variable "grafana_service_type" {
  description = "Service type for Grafana"
  type        = string
  default     = "ClusterIP"
}

variable "grafana_ingress_enabled" {
  description = "Enable Grafana ingress"
  type        = bool
  default     = false
}

variable "grafana_ingress_hosts" {
  description = "Grafana ingress hosts"
  type        = list(string)
  default     = []
}

variable "grafana_ingress_tls" {
  description = "Grafana ingress TLS configuration"
  type        = list(any)
  default     = []
}

variable "enable_alertmanager" {
  description = "Enable Alertmanager"
  type        = bool
  default     = true
}

variable "slack_webhook_url" {
  description = "Slack webhook URL for Alertmanager"
  type        = string
  default     = ""
  sensitive   = true
}

variable "slack_channel" {
  description = "Slack channel for alerts"
  type        = string
  default     = "#alerts"
}

variable "enable_node_exporter" {
  description = "Enable Node Exporter"
  type        = bool
  default     = true
}

variable "node_exporter_host_root_fs" {
  description = "Mount host root filesystem for Node Exporter"
  type        = bool
  default     = false
}

variable "enable_kube_state_metrics" {
  description = "Enable kube-state-metrics"
  type        = bool
  default     = true
}

variable "create_iam_role" {
  description = "Create IAM role for Prometheus"
  type        = bool
  default     = true
}

variable "enable_xray_integration" {
  description = "Enable AWS X-Ray integration"
  type        = bool
  default     = false
}

variable "create_cloudwatch_alarms" {
  description = "Create CloudWatch alarms for Prometheus targets"
  type        = bool
  default     = true
}

variable "prometheus_target_alarms" {
  description = "Configuration for Prometheus target alarms"
  type = list(object({
    name                = string
    job                 = string
    comparison_operator = string
    evaluation_periods  = number
    period              = number
    threshold           = number
    description         = string
  }))
  default = [
    {
      name                = "ecs-metrics"
      job                 = "ecs-metrics"
      comparison_operator = "LessThanThreshold"
      evaluation_periods  = 2
      period              = 300
      threshold           = 1
      description         = "ECS metrics target is down"
    },
    {
      name                = "cloudwatch-exporter"
      job                 = "cloudwatch-exporter"
      comparison_operator = "LessThanThreshold"
      evaluation_periods  = 2
      period              = 300
      threshold           = 1
      description         = "CloudWatch exporter target is down"
    }
  ]
}

variable "alarm_sns_topic_arns" {
  description = "SNS topic ARNs for alarm notifications"
  type        = list(string)
  default     = []
}

variable "custom_values" {
  description = "Custom values to pass to Helm chart"
  type        = map(string)
  default     = {}
}

variable "region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}
