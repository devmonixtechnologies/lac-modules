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

variable "enable_security_hub" {
  description = "Enable AWS Security Hub"
  type        = bool
  default     = true
}

variable "enable_cis_benchmark" {
  description = "Enable CIS AWS Foundations Benchmark"
  type        = bool
  default     = true
}

variable "enable_pci_dss" {
  description = "Enable PCI DSS standard"
  type        = bool
  default     = false
}

variable "enable_nist_csf" {
  description = "Enable NIST Cybersecurity Framework"
  type        = bool
  default     = false
}

variable "enable_aws_foundational" {
  description = "Enable AWS Foundational Security Best Practices"
  type        = bool
  default     = true
}

variable "auto_enable_members" {
  description = "Auto-enable organization members"
  type        = bool
  default     = false
}

variable "auto_enable_standards" {
  description = "Auto-enable standards for new members"
  type        = bool
  default     = false
}

variable "default_region" {
  description = "Default region for organization configuration"
  type        = string
  default     = "us-east-1"
}

variable "member_accounts" {
  description = "List of member account IDs"
  type        = list(string)
  default     = []
}

variable "member_email_domain" {
  description = "Email domain for member accounts"
  type        = string
  default     = "example.com"
}

variable "enable_custom_actions" {
  description = "Enable custom Security Hub actions"
  type        = bool
  default     = true
}

variable "enable_automation_rules" {
  description = "Enable Security Hub automation rules"
  type        = bool
  default     = true
}

variable "enable_guardduty" {
  description = "Enable Amazon GuardDuty"
  type        = bool
  default     = true
}

variable "guardduty_s3_logs" {
  description = "Enable S3 logs protection in GuardDuty"
  type        = bool
  default     = true
}

variable "guardduty_kubernetes_audit_logs" {
  description = "Enable Kubernetes audit logs in GuardDuty"
  type        = bool
  default     = false
}

variable "guardduty_malware_scan_ebs" {
  description = "Enable EBS malware scanning in GuardDuty"
  type        = bool
  default     = true
}

variable "disable_guardduty_email_notifications" {
  description = "Disable GuardDuty email notifications"
  type        = bool
  default     = false
}

variable "enable_threat_intel" {
  description = "Enable threat intelligence integration"
  type        = bool
  default     = false
}

variable "threat_intel_s3_bucket" {
  description = "S3 bucket location for threat intelligence lists"
  type        = string
  default     = ""
}

variable "enable_macie" {
  description = "Enable Amazon Macie"
  type        = bool
  default     = false
}

variable "macie_finding_frequency" {
  description = "Macie finding publishing frequency"
  type        = string
  default     = "FIFTEEN_MINUTES"
}

variable "macie_auto_enable_members" {
  description = "Auto-enable Macie for member accounts"
  type        = bool
  default     = false
}

variable "enable_s3_data_discovery" {
  description = "Enable S3 data discovery job"
  type        = bool
  default     = false
}

variable "s3_discovery_buckets" {
  description = "List of S3 buckets to scan for data discovery"
  type        = list(string)
  default     = []
}

variable "s3_exclusion_patterns" {
  description = "S3 bucket name patterns to exclude from discovery"
  type        = list(string)
  default     = ["logs", "backup", "archive"]
}

variable "s3_sampling_percentage" {
  description = "Sampling percentage for S3 data discovery"
  type        = number
  default     = 100
}

variable "enable_enhanced_cloudtrail" {
  description = "Enable enhanced CloudTrail logging"
  type        = bool
  default     = true
}

variable "cloudtrail_s3_bucket" {
  description = "S3 bucket for CloudTrail logs"
  type        = string
  default     = ""
}

variable "cloudtrail_multi_region" {
  description = "Enable multi-region CloudTrail"
  type        = bool
  default     = true
}

variable "cloudtrail_cw_log_group_arn" {
  description = "CloudWatch Log Group ARN for CloudTrail"
  type        = string
  default     = ""
}

variable "cloudtrail_cw_role_arn" {
  description = "CloudWatch Role ARN for CloudTrail"
  type        = string
  default     = ""
}

variable "enable_config_rules" {
  description = "Enable AWS Config rules"
  type        = bool
  default     = true
}

variable "config_s3_bucket" {
  description = "S3 bucket for AWS Config delivery"
  type        = string
  default     = ""
}

variable "config_sns_topic_arn" {
  description = "SNS topic ARN for AWS Config notifications"
  type        = string
  default     = ""
}

variable "region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}
