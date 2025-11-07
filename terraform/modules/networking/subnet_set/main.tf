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

resource "aws_subnet" "this" {
  for_each = {
    for subnet in var.subnets : subnet.name => subnet
  }

  vpc_id                  = var.vpc_id
  cidr_block              = each.value.cidr_block
  availability_zone       = each.value.az
  map_public_ip_on_launch = lookup(each.value, "map_public_ip_on_launch", false)

  tags = merge(module.tags.tags, {
    Name        = each.value.name
    Tier        = lookup(each.value, "tier", "")
    AZ          = each.value.az
    CidrBlock   = each.value.cidr_block
    SubnetGroup = var.subnet_group
  }, var.tags_override)
}

output "subnet_ids" {
  description = "Map of subnet name to subnet ID"
  value       = { for name, subnet in aws_subnet.this : name => subnet.id }
}

output "availability_zones" {
  description = "Map of subnet name to availability zone"
  value       = { for name, subnet in aws_subnet.this : name => subnet.availability_zone }
}
