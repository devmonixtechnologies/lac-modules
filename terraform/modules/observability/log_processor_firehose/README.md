# Log Processor Firehose Module

Deploys a Kinesis Firehose delivery stream configured for S3 delivery with optional IAM role creation.

## Inputs

- `stream_name` – Firehose stream name.
- `s3_bucket_arn` – Destination S3 bucket ARN.
- Buffer, compression, prefix, and encryption parameters.
- IAM role configuration via `role_arn`, `role_name`, and `role_policy_statements`.

## Outputs

- `delivery_stream_arn`
- `delivery_stream_name`
- `role_arn`
