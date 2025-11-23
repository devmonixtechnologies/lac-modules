terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0"
    }
  }
}

module "tags" {
  source          = "../../shared/tags"
  environment     = var.environment
  service         = var.service
  component       = "security-hub"
  additional_tags = var.tags
}

resource "aws_securityhub_account" "this" {
  count = var.enable_security_hub ? 1 : 0
}

resource "aws_securityhub_standards_subscription" "cis_aws" {
  count      = var.enable_security_hub && var.enable_cis_benchmark ? 1 : 0
  depends_on = [aws_securityhub_account.this]

  standards_arn = "arn:aws:securityhub:::ruleset/cis-aws-foundations-benchmark/v/1.2.0"
}

resource "aws_securityhub_standards_subscription" "pci_dss" {
  count      = var.enable_security_hub && var.enable_pci_dss ? 1 : 0
  depends_on = [aws_securityhub_account.this]

  standards_arn = "arn:aws:securityhub:::ruleset/pci-dss/v/3.2.1"
}

resource "aws_securityhub_standards_subscription" "nist_csf" {
  count      = var.enable_security_hub && var.enable_nist_csf ? 1 : 0
  depends_on = [aws_securityhub_account.this]

  standards_arn = "arn:aws:securityhub:::ruleset/nist-csf/v/1.0.0"
}

resource "aws_securityhub_standards_subscription" "aws_foundational" {
  count      = var.enable_security_hub && var.enable_aws_foundational ? 1 : 0
  depends_on = [aws_securityhub_account.this]

  standards_arn = "arn:aws:securityhub:::ruleset/aws-foundational-security-best-practices/v/1.0.0"
}

resource "aws_securityhub_organization_configuration" "this" {
  count = var.enable_security_hub && var.auto_enable_members ? 1 : 0
  depends_on = [aws_securityhub_account.this]

  auto_enable_organization_members = var.auto_enable_members
  auto_enable_standards           = var.auto_enable_standards
  organization_configuration {
    organization_configuration {
      default_region = var.default_region
    }
  }
}

resource "aws_securityhub_member" "members" {
  for_each = var.enable_security_hub && length(var.member_accounts) > 0 ? toset(var.member_accounts) : toset([])
  depends_on = [aws_securityhub_account.this]

  account_id = each.key
  email      = "${each.key}@${var.member_email_domain}"
  invite     = true
}

resource "aws_securityhub_action_target" "remediate" {
  count = var.enable_security_hub && var.enable_custom_actions ? 1 : 0

  name        = "Remediate"
  identifier  = "remediate"
  description = "Trigger automated remediation for security findings"
}

resource "aws_securityhub_automation_rule" "critical_findings" {
  count = var.enable_security_hub && var.enable_automation_rules ? 1 : 0

  description = "Automatically create remediation tickets for critical findings"
  status      = "ENABLED"
  rule_name   = "${var.environment}-critical-findings-remediation"

  rule_order = 1

  criteria {
    severity_label {
      comparison = "EQUALS"
      value      = "CRITICAL"
    }
  }

  action {
    type = "AUTOMATED_REMEDIATION"
    
    automation_rules_arn = aws_securityhub_action_target.remediate[0].arn
  }
}

resource "aws_guardduty_detector" "this" {
  count = var.enable_guardduty ? 1 : 0

  enable = true

  datasources {
    s3_logs {
      enable = var.guardduty_s3_logs
    }
    kubernetes {
      audit_logs {
        enable = var.guardduty_kubernetes_audit_logs
      }
    }
    malware_protection {
      scan_ec2_instance_with_findings {
        ebs_volumes {
          enable = var.guardduty_malware_scan_ebs
        }
      }
    }
  }

  tags = merge(module.tags.tags, var.tags_override)
}

resource "aws_guardduty_member" "members" {
  for_each = var.enable_guardduty && length(var.member_accounts) > 0 ? toset(var.member_accounts) : toset([])
  detector_id = aws_guardduty_detector.this[0].id
  account_id  = each.key
  email       = "${each.key}@${var.member_email_domain}"
  invite      = true
  disable_email_notifications = var.disable_guardduty_email_notifications
}

resource "aws_guardduty_ipset" "threat_intel" {
  count = var.enable_guardduty && var.enable_threat_intel ? 1 : 0
  detector_id = aws_guardduty_detector.this[0].id
  name        = "${var.environment}-threat-intel"
  format      = "TXT"
  location    = var.threat_intel_s3_bucket
  activate    = true
}

resource "aws_macie2_account" "this" {
  count = var.enable_macie ? 1 : 0

  finding_publishing_frequency = var.macie_finding_frequency
  status                       = "ENABLED"

  auto_enable_member_account_ids = var.macie_auto_enable_members ? var.member_accounts : []

  tags = merge(module.tags.tags, var.tags_override)
}

resource "aws_macie2_member" "members" {
  for_each = var.enable_macie && length(var.member_accounts) > 0 ? toset(var.member_accounts) : toset([])
  account_id = each.key
  email      = "${each.key}@${var.member_email_domain}"
  invite     = true
}

resource "aws_macie2_classification_job" "s3_discovery" {
  count = var.enable_macie && var.enable_s3_data_discovery ? 1 : 0

  job_id        = "${var.environment}-s3-discovery"
  name          = "${var.environment} S3 Data Discovery"
  schedule_type = "SCHEDULED"

  s3_job_definition {
    bucket_definitions {
      account_id          = data.aws_caller_identity.current.account_id
      buckets             = var.s3_discovery_buckets
    }
    
    scoping {
      excludes {
        and {
          simple_scope_term {
            comparator = "CONTAINS"
            property   = "BUCKET_NAME"
            values     = var.s3_exclusion_patterns
          }
        }
      }
    }
  }

  job_type             = "ONE_TIME"
  initial_run          = true
  sampling_percentage  = var.s3_sampling_percentage

  tags = merge(module.tags.tags, var.tags_override)
}

data "aws_caller_identity" "current" {}

resource "aws_cloudtrail" "security_logging" {
  count = var.enable_enhanced_cloudtrail ? 1 : 0

  name                          = "${var.environment}-security-cloudtrail"
  s3_bucket_name                = var.cloudtrail_s3_bucket
  s3_key_prefix                 = "cloudtrail-logs/"
  include_global_service_events = true
  is_multi_region_trail         = var.cloudtrail_multi_region
  enable_log_file_validation    = true
  enable_logging                = true

  cloud_watch_logs_group_arn = var.cloudtrail_cw_log_group_arn
  cloud_watch_logs_role_arn  = var.cloudtrail_cw_role_arn

  advanced_event_selector {
    name = "Management events"

    field_selector {
      field = "eventCategory"
      equals = ["Management"]
    }

    field_selector {
      field = "readOnly"
      equals = ["false"]
    }
  }

  tags = merge(module.tags.tags, var.tags_override)
}

resource "aws_config_configuration_recorder" "this" {
  count = var.enable_config_rules ? 1 : 0

  name     = "${var.environment}-config-recorder"
  role_arn = aws_iam_role.config_recorder[0].arn

  recording_group {
    all_supported = true
  }
}

resource "aws_iam_role" "config_recorder" {
  count = var.enable_config_rules ? 1 : 0
  name  = "${var.environment}-config-recorder"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "config.amazonaws.com"
        }
      }
    ]
  })

  tags = merge(module.tags.tags, var.tags_override)
}

resource "aws_iam_role_policy_attachment" "config_recorder" {
  count      = var.enable_config_rules ? 1 : 0
  role       = aws_iam_role.config_recorder[0].name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWS_ConfigRole"
}

resource "aws_config_delivery_channel" "this" {
  count = var.enable_config_rules ? 1 : 0

  name           = "${var.environment}-config-delivery-channel"
  s3_bucket_name = var.config_s3_bucket
  sns_topic_arn  = var.config_sns_topic_arn

  depends_on = [aws_config_configuration_recorder.this]
}

resource "aws_config_configuration_recorder_status" "this" {
  count = var.enable_config_rules ? 1 : 0
  name   = aws_config_configuration_recorder.this[0].name
  is_enabled = true
}

output "security_hub_arn" {
  description = "ARN of the Security Hub"
  value       = var.enable_security_hub ? aws_securityhub_account.this[0].arn : null
}

output "guardduty_detector_id" {
  description = "ID of the GuardDuty detector"
  value       = var.enable_guardduty ? aws_guardduty_detector.this[0].id : null
}

output "macie_account_id" {
  description = "ID of the Macie account"
  value       = var.enable_macie ? aws_macie2_account.this[0].id : null
}

output "cloudtrail_arn" {
  description = "ARN of the CloudTrail"
  value       = var.enable_enhanced_cloudtrail ? aws_cloudtrail.security_logging[0].arn : null
}
