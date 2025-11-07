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
  component       = var.component
  additional_tags = var.tags
}

resource "aws_cloudwatch_dashboard" "this" {
  dashboard_name = var.name
  dashboard_body = var.dashboard_body

  tags = merge(
    module.tags.tags,
    {
      Name = var.name
    },
    var.tags_override,
  )
}

output "dashboard_body" {
  description = "Rendered CloudWatch dashboard JSON"
  value       = aws_cloudwatch_dashboard.this.dashboard_body
}
