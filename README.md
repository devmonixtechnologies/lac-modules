- `terraform/docs/examples/dashboard-dev.json`: Example rendered CloudWatch dashboard body for documentation/testing references.
# LAC Modules

Production-ready Infrastructure as Code (IaC) building blocks for Landing & Application Components (LAC). The repository provides modular Terraform for AWS foundations, environment compositions, observability, governance, and CI automation so platform teams can standardise delivery across dev/stage/prod.

---

## Table of Contents
1. [Repository Layout](#repository-layout)
2. [Architecture & Design Principles](#architecture--design-principles)
3. [Core Terraform Modules](#core-terraform-modules)
4. [Environment Stacks](#environment-stacks)
5. [Observability Enhancements](#observability-enhancements)
6. [Policy & Governance](#policy--governance)
7. [Getting Started](#getting-started)
8. [Testing Strategy](#testing-strategy)
9. [CI/CD Pipelines](#cicd-pipelines)
10. [Examples & Reference Artifacts](#examples--reference-artifacts)
11. [Contribution Guidelines](#contribution-guidelines)

---

## Repository Layout

```
terraform/
  modules/                # Reusable Terraform modules grouped by domain
    networking/           # VPC, subnet sets, and networking primitives
    security/             # IAM baseline controls
    compute/              # ECS cluster/service modules
    observability/        # Logging, alarms, dashboards, log processors
      logging/            # CloudWatch log groups & subscription filters
      alarms/             # ECS CPU & memory alarms
      dashboards/         # Dashboard templating utilities
      log_processor_lambda/   # Managed Lambda log processor
      log_processor_firehose/ # Kinesis Firehose delivery stream
  environments/           # Composable stacks (global, dev, stage, prod)
  tests/                  # Terratest suites, fixtures, and policies
  pipelines/              # GitHub Actions workflows for validation/plan/apply
  docs/                   # Architecture, observability, and module guidelines
  examples/               # Example configurations (e.g. Lambda processor)
```

---

## Architecture & Design Principles

- **Composable modules:** Networking, security, compute, and observability modules expose minimal inputs/outputs so they can be recombined across environments.
- **Environment parity:** Shared `app_stack` module wires core services once and is parameterised for dev/stage/prod. Differences are handled through variables, not divergent code paths.
- **Observability built-in:** Logging, alarms, and dashboards ship as first-class modules with optional automation for log delivery destinations.
- **Policy enforcement:** OPA policies and tagging helpers guarantee consistent controls (e.g. mandatory tags) during plan/test time.
- **CI-first workflows:** GitHub Actions pipeline validates formatting, security, policies, unit tests, and produces reusable plan artifacts and dashboard JSON.

---

## Core Terraform Modules

| Module | Purpose |
| --- | --- |
| `modules/networking/vpc` | Creates VPC with optional flow logs and additional CIDR blocks. |
| `modules/networking/subnet_set` | Generates tiered subnets (public/private) per AZ. |
| `modules/security/iam-baseline` | Applies account guardrails (password policy, Access Analyzer). |
| `modules/compute/ecs_cluster` | Provisions ECS cluster with Service Connect & Exec options. |
| `modules/compute/ecs_service` | Defines Fargate services with deployment controls and networking. |
| `modules/observability/logging` | CloudWatch log group plus optional subscription filter and IAM role automation. |
| `modules/observability/alarms` | ECS CPU/memory alarms with configurable thresholds/actions. |
| `modules/observability/dashboards` | Renders dashboards from JSON templates and merges tagging. |
| `modules/observability/log_processor_lambda` | Packages Lambda code (from directory or pre-built zip), manages IAM role/policies, and returns ARNs for log subscriptions. |
| `modules/observability/log_processor_firehose` | Creates Firehose delivery stream targeting S3 with buffering, compression, and role management. |

See `terraform/docs/` for deep dives into module usage and architectural decisions.

---

## Environment Stacks

- **Global**: Shared providers, tagging locals, and optional global services.
- **Dev**: Demonstrates Lambda-based log processing (`create_log_processor_lambda = true`) and enables dashboards by default for iterative development.
- **Stage**: Mirrors production topology while enabling Firehose delivery into staging S3 buckets for pre-production validation.
- **Prod**: Production-ready configuration with Firehose delivery, longer log retention, higher desired task counts, and hardened defaults.

Each environment stack consumes the shared `app_stack` module, injecting environment-specific variables (network ranges, observability preferences, alarms, etc.). Remote state backends are injected via `.hcl` templates stored outside the repo and passed in at init time.

---

## Observability Enhancements

- **Log subscriptions**: Toggle Lambda or Firehose processors without editing the logging module. When destinations are omitted, the app stack auto-wires ARNs from the selected processor module and injects least-privilege policy statements.
- **Dashboards**: Choose between `overview` (CPU/memory) and `health` (ALB latency/ECS error) templates using `dashboard_template_variant`, or point to a custom JSON file.
- **Artifacts**: Rendered dashboard JSON is uploaded as a CI artifact when generated and also stored under `terraform/docs/examples/dashboard-dev.json` for quick previews.
- **Documentation**: `terraform/docs/observability.md` outlines IAM policies, processor configuration, and environment guidance.

---

## Policy & Governance

- **Tag Enforcement**: OPA policies in `terraform/tests/policy` ensure required tags exist across resources.
- **Security Scans**: `tfsec` and `checkov` run during CI to flag misconfigurations.
- **IAM Baseline**: `modules/security/iam-baseline` configures minimum password complexity and Access Analyzer.

---

## Getting Started

1. **Install toolchain**
   - Terraform ≥ 1.6.0
   - Go ≥ 1.21 (for Terratest)
   - Optional: OPA CLI for local policy testing
2. **Prepare remote state**
   - Copy `terraform/environments/<env>/backend.hcl.example` to `backend.hcl` and fill in S3/DynamoDB values.
   - Run `terraform -chdir=terraform/environments/dev init -backend-config=backend.hcl`.
3. **Plan & apply**
   ```bash
   terraform -chdir=terraform/environments/dev plan
   terraform -chdir=terraform/environments/dev apply
   ```
4. **Configure CI secrets**
   - `AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY`, `AWS_SESSION_TOKEN` (optional), `AWS_DEFAULT_REGION`
   - `DEV_BACKEND_CONFIG`, `STAGE_BACKEND_CONFIG`, `PROD_BACKEND_CONFIG`

---

## Testing Strategy

- **Terratest**: `terraform/tests/unit` executes plan-based tests validating module outputs, IAM policies, and dashboard rendering. Tests skip gracefully if Terraform is unavailable (matching CI behaviour).
- **Fixtures**: Located under `terraform/tests/fixtures` to provide self-contained Terraform configurations (e.g. app stack with dashboards, log processors).
- **OPA policies**: Run via `opa test terraform/tests/policy` to enforce organisation-level rules.

Run all tests locally:

```bash
cd terraform/tests
go test ./...
```

---

## CI/CD Pipelines

The GitHub Actions workflow (`terraform/pipelines/terraform.yml`) provides three jobs:

1. **validate** – Runs `terraform fmt`, provider init/validate for each environment, `tfsec`, `checkov`, OPA tests, and Terratest.
2. **plan** – Injects backend configs from secrets, runs environment-specific plans, and uploads plan files plus any rendered dashboard JSON artifacts.
3. **apply** – Executes environment applies on pushes to `main`, rehydrating backend configs before applying.

Dashboard artifacts are only uploaded when JSON files are produced, keeping PR artifacts noise-free.

---

## Examples & Reference Artifacts

- `terraform/examples/logging/lambda-processor` – Sample module showing how to package and deploy a Lambda-based log processor (zip packaging, IAM role, outputs).
- `terraform/docs/examples/dashboard-dev.json` – Rendered dashboard body for development environment.
- Additional guidance lives under `terraform/docs/` (architecture, observability, module guidelines).

---

## Contribution Guidelines

1. **Code quality** – Run `terraform fmt -recursive`, `terraform validate`, `tfsec terraform`, and `checkov -d terraform`.
2. **Tests** – Execute `go test ./...` from `terraform/tests` and `opa test terraform/tests/policy`.
3. **Documentation** – Update relevant files under `terraform/docs` or this README when introducing module behaviour changes.
4. **Pull requests** – Include links to plan artifacts (uploaded automatically) and describe environment impacts (dev/stage/prod).

---

For deeper architectural context and module walkthroughs, explore the documents in `terraform/docs/`. Observability specifics (IAM templates, processor configuration, dashboards) are captured in `terraform/docs/observability.md`.
