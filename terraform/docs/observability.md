# Observability Modules

## Logging

Module: `terraform/modules/observability/logging`

- Provisions a CloudWatch log group with optional KMS encryption.
- Supports optional subscription filters to send logs to Kinesis, Firehose, or Lambda destinations.
- Key inputs:
  - `subscription_destination_arn`: destination for forwarded logs.
  - `subscription_role_arn`: IAM role ARN for subscription (optional when destination supports same-account delivery).
  - `subscription_filter_pattern`: filter applied to streamed events.
- Outputs:
  - `log_group_name`, `log_group_arn`, `subscription_filter_arn`.
  - `subscription_role_arn` (created automatically when `subscription_create_role = true`).

### IAM policy templates

When `subscription_create_role = true`, provide policy statements that grant the log service permission to deliver events.

**Lambda destination**

```hcl
subscription_role_policy_statements = [
  {
    actions   = ["lambda:InvokeFunction", "lambda:InvokeAsync"]
    resources = [aws_lambda_function.log_processor.arn]
  }
]
```

**Kinesis Firehose destination**

```hcl
subscription_role_policy_statements = [
  {
    actions = [
      "firehose:PutRecord",
      "firehose:PutRecordBatch"
    ]
    resources = [aws_kinesis_firehose_delivery_stream.logs.arn]
  }
]
```

Provision downstream targets (Lambda, Firehose, or Kinesis streams) using dedicated modules within the application stack or shared infrastructure layers. Ensure the destination policies permit the subscription role to invoke or write data (e.g., add `lambda:InvokeFunction` to the function resource policy). Use environment-specific ARNs to avoid cross-account surprises and rotate destinations via Terraform variables when promoting builds.

### Managing log processors

- **Lambda processor** – Package runtime (Go/Python/Node) functions that transform or route log events. Provide Terraform modules that build the artifact (SAM/Zip) and expose function ARNs consumed by the logging module.
- **Firehose delivery stream** – Configure buffering, compression, and destination (S3/OpenSearch). Attach access policies allowing the subscription role to write batches.
- **Kinesis stream** – Useful for real-time analytics; ensure consumer applications scale with shard changes.
- Include versioned outputs (ARNs, stream names) in environment stacks so observability modules update automatically.

## Alarms

Module: `terraform/modules/observability/alarms`

- Emits CPU and memory utilization alarms for ECS services.
- Accepts custom alarm actions (SNS, PagerDuty, etc.).
- Thresholds configurable via `cpu_threshold`, `memory_threshold`, periods, and evaluation counts.

## Dashboards

Module: `terraform/modules/observability/dashboards`

- Creates CloudWatch dashboards from JSON templates.
- Sample template provided under `templates/service_overview.json`.
- Additional template `templates/service_health.json` exposes ALB response-time and ECS error widgets.
- Usage example:

```hcl
locals {
  dashboard_body = templatefile(
    "${path.module}/templates/service_overview.json",
    {
      cluster_name = module.ecs_cluster.cluster_name
      service_name = module.ecs_service.service_name
      region       = var.region
    }
  )
}

module "service_dashboard" {
  source      = "../../../modules/observability/dashboards"
  name        = "${var.environment}-${var.service_name}-overview"
  environment = var.environment
  service     = var.service_name
  component   = "service-dashboard"
  dashboard_body = local.dashboard_body
}
```

Dashboards inherit tagging conventions and can be extended with additional widgets via JSON templates.

### Environment guidance

- **dev** – module-enabled Lambda processor (via `create_log_processor_lambda`) demonstrates direct function invocation while keeping Firehose disabled by default.
- **stage** – provisions the Firehose processor module to stream service logs into the stage S3 bucket and renders the `service_health` dashboard template for latency/error views.
- **prod** – mirrors stage with Firehose delivery backed by production buckets; toggle the Lambda processor when real-time transforms are required.

To override dashboards per workload, set `dashboard_template_variant` to `overview` or `health`, or provide a bespoke JSON file via `dashboard_template_path`. Combine with `dashboard_template_context` to inject additional widget parameters (e.g., ALB resource ARNs).

Sample rendered dashboard output is captured in `terraform/docs/examples/dashboard-dev.json` for quick visualization.
