# Infrastructure Architecture Overview

## Scope

Phase 1 covers AWS foundational landing zones with environment isolation (dev, stage, prod). Core capabilities include networking, identity & access management, compute, observability, and shared tagging/governance.

## Environments

- **global** – bootstrap resources shared across the organization (Terraform state backend, IAM guardrails).
- **dev** – developer sandbox with reduced capacity and relaxed guardrails.
- **stage** – pre-production environment mirroring production topology.
- **prod** – production workloads with full guardrails and monitoring.

Environment stacks consume reusable modules exposed under `terraform/modules`.

## Module Domains

- **Networking** – VPC, subnet sets, routing, flow logging.
- **Security** – IAM baseline (SCP-like guardrails via IAM), reusable IAM role patterns.
- **Compute** – ECS cluster primitives and ECS service deployment bundle.
- **Observability**

- Centralized logging and alarms.
- Shared – Tagging conventions and helpers.

### Advanced observability add-ons

- Application log groups are managed via the `observability/logging` module, supporting optional KMS encryption and retention controls.
- Service-level alarms leverage the `observability/alarms` module to monitor ECS CPU and memory utilization; alarms emit to configurable SNS or PagerDuty integrations via `alarm_actions`.
- Future enhancements:
  - Central metrics dashboards (CloudWatch dashboards or Grafana) consuming module outputs.
  - Log subscription filters to forward structured events into analytics pipelines (e.g., Kinesis Firehose / OpenSearch).
  - Trace collection via AWS Distro for OpenTelemetry sidecars with configurable exporters.

## State & Backends

Terraform uses remote state per environment hosted in S3 with DynamoDB locking. The `global` stack provisions backend infrastructure; other environments reference it via backend configuration.

## Policy & Compliance

- fmt/validate enforced in CI.
- tfsec & checkov security scans per change.
- OPA policies target naming, tagging, and guardrail enforcement.

## Testing Strategy

- **Unit** tests via Terratest for module interfaces.
- **Integration** tests for environment compositions.
- **Policy** tests executed as part of CI to ensure compliance.

## CI/CD Flow

1. Pull request triggers formatting, validation, security scans, and unit tests.
2. Terraform plan generated per environment with artifacts stored.
3. Manual approval step required for stage/prod applies.

## Future Phases

- Extend modules to Azure/GCP with shared interface contracts.
- Add data services (RDS, S3 data lake, messaging) and advanced observability.
- Introduce compliance packs (CIS, PCI) and drift remediation automation.
