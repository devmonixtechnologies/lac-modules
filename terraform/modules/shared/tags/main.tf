locals {
  base_tags = {
    Environment = var.environment
    Service     = var.service
    Component   = var.component
  }

  merged_tags = merge(
    { for k, v in local.base_tags : k => v if try(trim(v), "") != "" },
    var.additional_tags,
  )
}

output "tags" {
  description = "Normalized tag map merged with additional tags"
  value       = local.merged_tags
}

