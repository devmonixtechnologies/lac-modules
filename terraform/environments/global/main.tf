module "tags" {
  source          = "../../modules/shared/tags"
  environment     = "global"
  service         = "platform"
  component       = "terraform-backend"
  additional_tags = var.tags
}

resource "aws_s3_bucket" "state" {
  bucket = var.state_bucket_name

  force_destroy = var.state_bucket_force_destroy

  tags = merge(module.tags.tags, {
    Name = var.state_bucket_name
  })
}

resource "aws_s3_bucket_versioning" "state" {
  bucket = aws_s3_bucket.state.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "state" {
  bucket = aws_s3_bucket.state.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "state" {
  bucket = aws_s3_bucket.state.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_lifecycle_configuration" "state" {
  bucket = aws_s3_bucket.state.id

  rule {
    id     = "incomplete-multipart-uploads"
    status = "Enabled"

    abort_incomplete_multipart_upload {
      days_after_initiation = 7
    }
  }
}

resource "aws_dynamodb_table" "state_lock" {
  name         = var.state_dynamodb_table_name
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }

  tags = merge(module.tags.tags, {
    Name = var.state_dynamodb_table_name
  })
}

output "state_bucket_name" {
  description = "S3 bucket that stores Terraform state"
  value       = aws_s3_bucket.state.id
}

output "state_lock_table" {
  description = "DynamoDB table used for Terraform state locking"
  value       = aws_dynamodb_table.state_lock.name
}
