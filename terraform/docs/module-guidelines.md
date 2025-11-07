## App Stack Module

The `terraform/environments/modules/app_stack` module composes networking, security, compute, and observability primitives for a standard ECS-backed application.

### Required inputs

- `environment`: Environment identifier.
- `region`: AWS region.
- `name_prefix`: Base name for resources (used in VPC, ECS, IAM).
- `service_name`: Tagging/ownership identifier.
- `vpc_cidr_block`, `public_subnets`, `private_subnets`: Network layout.
- `container_image`, `container_port`: ECS task image and port.

### Optional inputs

- Flow log, capacity, container sizing parameters (see module `variables.tf`).
- `log_kms_key_id`, `alarm_*` variables to tune observability.
- `load_balancers`, `service_registries`, `capacity_provider_strategy` for advanced deployments.

### Outputs

- VPC and subnet IDs.
- ECS cluster/service identifiers.
- Task definition ARN.

### Usage example

```hcl
module "app_stack" {
  source = "../../environments/modules/app_stack"

  environment  = "dev"
  region       = "us-east-1"
  name_prefix  = "dev-svc"
  service_name = "orders"

  vpc_cidr_block = "10.42.0.0/20"
  public_subnets = [
    {
      name       = "dev-public-a"
      cidr_block = "10.42.0.0/24"
      az         = "us-east-1a"
    },
    {
      name       = "dev-public-b"
      cidr_block = "10.42.1.0/24"
      az         = "us-east-1b"
    }
  ]
  private_subnets = [
    {
      name       = "dev-private-a"
      cidr_block = "10.42.2.0/24"
      az         = "us-east-1a"
    },
    {
      name       = "dev-private-b"
      cidr_block = "10.42.3.0/24"
      az         = "us-east-1b"
    }
  ]

  container_image = "public.ecr.aws/ecs-sample-image/amazon-ecs-sample"
  container_port  = 3000

  alarm_actions = [aws_sns_topic.ops.arn]
}
```

Refer to `variables.tf` for the complete list of tunables.
