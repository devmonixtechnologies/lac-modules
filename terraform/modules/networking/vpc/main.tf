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

resource "aws_vpc" "this" {
  cidr_block           = var.cidr_block
  enable_dns_support   = var.enable_dns_support
  enable_dns_hostnames = var.enable_dns_hostnames

  tags = merge(
    module.tags.tags,
    {
      Name = var.name
    },
    var.tags_override
  )
}

resource "aws_vpc_ipv4_cidr_block_association" "secondary" {
  for_each   = toset(var.secondary_cidr_blocks)
  vpc_id     = aws_vpc.this.id
  cidr_block = each.value
}

resource "aws_default_security_group" "default" {
  vpc_id = aws_vpc.this.id

  revoke_rules_on_delete = true

  tags = merge(module.tags.tags, var.tags_override, { Name = "${var.name}-default-sg" })
}

resource "aws_cloudwatch_log_group" "flow_logs" {
  count             = var.enable_flow_logs && var.flow_log_destination_type == "cloud-watch-logs" ? 1 : 0
  name              = var.flow_log_cloudwatch_log_group_name == "" ? "/aws/vpc/${var.name}/flow" : var.flow_log_cloudwatch_log_group_name
  retention_in_days = var.flow_log_cloudwatch_retention_days

  tags = merge(module.tags.tags, var.tags_override)
}

resource "aws_flow_log" "this" {
  count = var.enable_flow_logs ? 1 : 0

  log_destination_type = var.flow_log_destination_type
  traffic_type         = var.flow_log_traffic_type
  vpc_id               = aws_vpc.this.id

  iam_role_arn = var.flow_log_destination_type == "cloud-watch-logs" ? var.flow_log_cloudwatch_role_arn : null

  log_destination = (
    var.flow_log_destination_type == "cloud-watch-logs"
    ? aws_cloudwatch_log_group.flow_logs[0].arn
    : var.flow_log_s3_arn
  )

  tags = merge(module.tags.tags, var.tags_override)
}

output "vpc_id" {
  description = "ID of the VPC"
  value       = aws_vpc.this.id
}

output "vpc_arn" {
  description = "ARN of the VPC"
  value       = aws_vpc.this.arn
}

output "vpc_cidr_block" {
  description = "Primary IPv4 CIDR block"
  value       = aws_vpc.this.cidr_block
}

output "secondary_cidr_blocks" {
  description = "Associated secondary CIDR blocks"
  value       = [for association in aws_vpc_ipv4_cidr_block_association.secondary : association.cidr_block]
}
