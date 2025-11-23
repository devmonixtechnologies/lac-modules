terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0"
    }
    helm = {
      source  = "hashicorp/helm"
      version = ">= 2.10.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = ">= 2.20.0"
    }
  }
}

module "tags" {
  source          = "../../shared/tags"
  environment     = var.environment
  service         = var.service
  component       = "prometheus"
  additional_tags = var.tags
}

locals {
  prometheus_namespace = coalesce(var.namespace, "${var.environment}-monitoring")
  create_namespace     = var.create_namespace
}

resource "aws_iam_role" "prometheus" {
  count = var.create_iam_role ? 1 : 0
  name  = "${var.environment}-${var.service}-prometheus"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      },
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "eks.amazonaws.com"
        }
      }
    ]
  })

  tags = merge(module.tags.tags, var.tags_override)
}

resource "aws_iam_role_policy_attachment" "prometheus_cloudwatch" {
  count      = var.create_iam_role ? 1 : 0
  role       = aws_iam_role.prometheus[0].name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchReadOnlyAccess"
}

resource "aws_iam_role_policy_attachment" "prometheus_xray" {
  count      = var.create_iam_role && var.enable_xray_integration ? 1 : 0
  role       = aws_iam_role.prometheus[0].name
  policy_arn = "arn:aws:iam::aws:policy/AWSXRayDaemonWriteAccess"
}

resource "kubernetes_namespace" "prometheus" {
  count = local.create_namespace ? 1 : 0
  name  = local.prometheus_namespace

  metadata {
    labels = merge(
      module.tags.tags,
      {
        name = local.prometheus_namespace
      }
    )
  }
}

resource "helm_release" "prometheus" {
  name       = "prometheus"
  repository = "https://prometheus-community.github.io/helm-charts"
  chart      = "kube-prometheus-stack"
  namespace  = local.create_namespace ? kubernetes_namespace.prometheus[0].name : local.prometheus_namespace
  version    = var.helm_chart_version

  values = [
    yamlencode({
      prometheus = {
        prometheusSpec = {
          serviceMonitorSelectorNilUsesHelmValues = false
          serviceMonitorSelector = {
            matchLabels = {
              release = var.release_name
            }
          }
          ruleSelectorNilUsesHelmValues = false
          ruleSelector = {
            matchLabels = {
              release = var.release_name
            }
          }
          retention = var.retention_period
          resources = var.prometheus_resources
          storageSpec = var.enable_persistence ? {
            volumeClaimTemplate = {
              spec = {
                storageClassName = var.storage_class
                accessModes      = ["ReadWriteOnce"]
                resources = {
                  requests = {
                    storage = var.storage_size
                  }
                }
              }
            }
          } : null
        }
      }
      grafana = {
        enabled = var.enable_grafana
        adminPassword = var.grafana_admin_password
        persistence = {
          enabled = var.grafana_persistence_enabled
          size = var.grafana_storage_size
          storageClassName = var.grafana_storage_class
        }
        service = {
          type = var.grafana_service_type
          port = 3000
        }
        ingress = {
          enabled = var.grafana_ingress_enabled
          hosts = var.grafana_ingress_hosts
          tls = var.grafana_ingress_tls
        }
        sidecar = {
          dashboards = {
            enabled = true
            label = "grafana_dashboard"
          }
          datasources = {
            enabled = true
            label = "grafana_datasource"
          }
        }
      }
      alertmanager = {
        enabled = var.enable_alertmanager
        config = {
          global = {
            slack_api_url = var.slack_webhook_url
          }
          route = {
            group_by = ["alertname", "cluster"]
            group_wait = "10s"
            group_interval = "10s"
            repeat_interval = "1h"
            receiver = "slack-notifications"
          }
          receivers = [
            {
              name = "slack-notifications"
              slack_configs = [
                {
                  channel = var.slack_channel
                  send_resolved = true
                  title = "{{ .CommonLabels.alertname }} - {{ .Status }}"
                  text = "{{ range .Alerts }}{{ .Annotations.description }}{{ end }}"
                }
              ]
            }
          ]
        }
      }
      nodeExporter = {
        enabled = var.enable_node_exporter
        hostRootFs = var.node_exporter_host_root_fs
      }
      kubeStateMetrics = {
        enabled = var.enable_kube_state_metrics
      }
    })
  ]

  depends_on = [kubernetes_namespace.prometheus]

  dynamic "set" {
    for_each = var.custom_values
    content {
      name  = set.key
      value = set.value
    }
  }
}

resource "aws_cloudwatch_metric_alarm" "prometheus_targets" {
  count = var.create_cloudwatch_alarms ? length(var.prometheus_target_alarms) : 0

  alarm_name          = "${var.environment}-${var.service}-prometheus-target-${var.prometheus_target_alarms[count.index].name}"
  comparison_operator = var.prometheus_target_alarms[count.index].comparison_operator
  evaluation_periods  = var.prometheus_target_alarms[count.index].evaluation_periods
  metric_name         = "prometheus_target_up"
  namespace           = "Prometheus"
  period              = var.prometheus_target_alarms[count.index].period
  statistic           = "Average"
  threshold           = var.prometheus_target_alarms[count.index].threshold
  alarm_description   = var.prometheus_target_alarms[count.index].description
  treat_missing_data  = "breaching"

  dimensions = {
    job = var.prometheus_target_alarms[count.index].job
  }

  alarm_actions = var.alarm_sns_topic_arns
  ok_actions    = var.alarm_sns_topic_arns

  tags = merge(module.tags.tags, var.tags_override)
}

output "prometheus_service_endpoint" {
  description = "Prometheus service endpoint"
  value       = helm_release.prometheus.status == "deployed" ? "http://${helm_release.prometheus.name}.${helm_release.prometheus.namespace}.svc.cluster.local:9090" : null
}

output "grafana_service_endpoint" {
  description = "Grafana service endpoint"
  value       = var.enable_grafana && helm_release.prometheus.status == "deployed" ? "http://${helm_release.prometheus.name}-grafana.${helm_release.prometheus.namespace}.svc.cluster.local:3000" : null
}

output "prometheus_iam_role_arn" {
  description = "ARN of the IAM role for Prometheus"
  value       = var.create_iam_role ? aws_iam_role.prometheus[0].arn : null
}
