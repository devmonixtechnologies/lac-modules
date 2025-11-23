# Example: EKS Cluster with Prometheus Monitoring Stack
# This example demonstrates the advanced v2.0 features for Kubernetes workloads

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = ">= 2.20.0"
    }
    helm = {
      source  = "hashicorp/helm"
      version = ">= 2.10.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

# VPC Configuration
module "vpc" {
  source = "../../modules/networking/vpc"

  environment = var.environment
  service     = "eks-example"
  component   = "vpc"

  cidr_block           = var.vpc_cidr
  enable_flow_logs     = true
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Project     = "LAC-Modules-v2"
    Example     = "EKS-Prometheus"
    ManagedBy   = "Terraform"
  }
}

# Subnet Configuration
module "subnets" {
  source = "../../modules/networking/subnet_set"

  environment = var.environment
  service     = "eks-example"
  component   = "subnets"

  vpc_id = module.vpc.vpc_id

  availability_zones = var.availability_zones

  public_subnet_cidrs  = var.public_subnet_cidrs
  private_subnet_cidrs = var.private_subnet_cidrs

  tags = {
    Project     = "LAC-Modules-v2"
    Example     = "EKS-Prometheus"
    ManagedBy   = "Terraform"
  }
}

# EKS Cluster
module "eks_cluster" {
  source = "../../modules/compute/eks_cluster"

  environment = var.environment
  service     = "eks-example"
  component   = "eks"

  name = "${var.environment}-eks-cluster"

  vpc_id     = module.vpc.vpc_id
  subnet_ids = concat(module.subnets.private_subnet_ids, module.subnets.public_subnet_ids)

  kubernetes_version = var.kubernetes_version

  endpoint_private_access = true
  endpoint_public_access  = false

  enable_secrets_encryption = true
  kms_admin_arns           = [data.aws_caller_identity.current.arn]

  create_node_group = true
  node_group_name   = "managed-nodes"
  node_subnet_ids   = module.subnets.private_subnet_ids

  desired_size = var.desired_node_count
  max_size     = var.max_node_count
  min_size     = var.min_node_count

  instance_types = var.instance_types
  capacity_type = var.capacity_type

  enable_vpc_cni_addon = true
  enable_coredns_addon = true
  enable_kube_proxy_addon = true

  enable_aws_lb_controller = true

  tags = {
    Project     = "LAC-Modules-v2"
    Example     = "EKS-Prometheus"
    ManagedBy   = "Terraform"
  }
}

# Prometheus Monitoring Stack
module "prometheus" {
  source = "../../modules/observability/prometheus"

  environment = var.environment
  service     = "eks-example"
  component   = "prometheus"

  create_namespace = true
  namespace       = "monitoring"

  enable_grafana = true
  grafana_admin_password = var.grafana_admin_password
  grafana_persistence_enabled = true

  enable_alertmanager = true
  slack_webhook_url  = var.slack_webhook_url
  slack_channel      = "#monitoring"

  enable_persistence = true
  storage_size      = "100Gi"
  storage_class     = "gp3"

  retention_period = "30d"

  prometheus_target_alarms = [
    {
      name                = "kubernetes-nodes"
      job                 = "kubernetes-nodes"
      comparison_operator = "LessThanThreshold"
      evaluation_periods  = 2
      period              = 300
      threshold           = 1
      description         = "Kubernetes nodes target is down"
    }
  ]

  tags = {
    Project     = "LAC-Modules-v2"
    Example     = "EKS-Prometheus"
    ManagedBy   = "Terraform"
  }

  depends_on = [module.eks_cluster]
}

# Security Hub Integration
module "security_hub" {
  source = "../../modules/security/security-hub"

  environment = var.environment
  service     = "eks-example"
  component   = "security"

  enable_security_hub = true
  enable_cis_benchmark = true
  enable_aws_foundational = true

  enable_guardduty = true
  guardduty_s3_logs = true
  guardduty_malware_scan_ebs = true

  enable_enhanced_cloudtrail = true
  cloudtrail_s3_bucket = var.cloudtrail_s3_bucket

  enable_config_rules = true
  config_s3_bucket = var.config_s3_bucket

  tags = {
    Project     = "LAC-Modules-v2"
    Example     = "EKS-Prometheus"
    ManagedBy   = "Terraform"
  }
}

# Cost Optimization
module "cost_optimization" {
  source = "../../modules/governance/cost-optimization"

  environment = var.environment
  service     = "eks-example"
  component   = "cost"

  enable_cost_anomaly_detection = true
  monitored_services = ["Amazon EKS", "Amazon EC2", "Amazon RDS"]
  anomaly_notification_email = var.cost_notification_email

  budgets = {
    eks_monthly = {
      budget_type       = "COST"
      time_unit         = "MONTHLY"
      time_period_start = "2024-01-01T00:00:00Z"
      limit_amount = {
        amount = 500
        unit   = "USD"
      }
      cost_filters = {
        Service = ["Amazon EKS", "Amazon EC2"]
      }
      notifications = [
        {
          comparison_operator        = "GREATER_THAN"
          threshold                  = 80
          threshold_type             = "PERCENTAGE"
          notification_type          = "ACTUAL"
          subscriber_email_addresses = [var.cost_notification_email]
          subscriber_sns_topic_arns  = []
        }
      ]
    }
  }

  tags = {
    Project     = "LAC-Modules-v2"
    Example     = "EKS-Prometheus"
    ManagedBy   = "Terraform"
  }
}

# Example application deployment
resource "kubernetes_namespace" "application" {
  metadata {
    name = "application"
    labels = {
      name = "application"
    }
  }
}

resource "kubernetes_deployment" "example_app" {
  metadata {
    name      = "example-app"
    namespace = kubernetes_namespace.application.metadata.name
    labels = {
      app = "example-app"
    }
  }

  spec {
    replicas = 3

    selector {
      match_labels = {
        app = "example-app"
      }
    }

    template {
      metadata {
        labels = {
          app = "example-app"
        }
      }

      spec {
        container {
          name  = "example-app"
          image = "nginx:1.21"

          port {
            container_port = 80
          }

          resources {
            limits = {
              cpu    = "200m"
              memory = "256Mi"
            }
            requests = {
              cpu    = "100m"
              memory = "128Mi"
            }
          }

          liveness_probe {
            http_get {
              path = "/"
              port = 80
            }
            initial_delay_seconds = 30
            period_seconds        = 10
          }

          readiness_probe {
            http_get {
              path = "/"
              port = 80
            }
            initial_delay_seconds = 5
            period_seconds        = 5
          }
        }
      }
    }
  }
}

resource "kubernetes_service" "example_app" {
  metadata {
    name      = "example-app"
    namespace = kubernetes_namespace.application.metadata.name
    labels = {
      app = "example-app"
    }
  }

  spec {
    selector = {
      app = "example-app"
    }

    port {
      port        = 80
      target_port = 80
    }

    type = "ClusterIP"
  }
}

# Service Monitor for Prometheus
resource "kubernetes_manifest" "example_app_service_monitor" {
  manifest = {
    apiVersion = "monitoring.coreos.com/v1"
    kind       = "ServiceMonitor"
    metadata = {
      name      = "example-app"
      namespace = kubernetes_namespace.application.metadata.name
      labels = {
        app = "example-app"
      }
    }
    spec = {
      selector = {
        matchLabels = {
          app = "example-app"
        }
      }
      endpoints = [
        {
          port = "metrics"
          path = "/metrics"
        }
      ]
    }
  }

  depends_on = [module.prometheus]
}

data "aws_caller_identity" "current" {}

# Outputs
output "eks_cluster_name" {
  description = "EKS cluster name"
  value       = module.eks_cluster.cluster_name
}

output "eks_cluster_endpoint" {
  description = "EKS cluster endpoint"
  value       = module.eks_cluster.cluster_endpoint
}

output "prometheus_endpoint" {
  description = "Prometheus endpoint"
  value       = module.prometheus.prometheus_service_endpoint
}

output "grafana_endpoint" {
  description = "Grafana endpoint"
  value       = module.prometheus.grafana_service_endpoint
}

output "security_hub_arn" {
  description = "Security Hub ARN"
  value       = module.security_hub.security_hub_arn
}
