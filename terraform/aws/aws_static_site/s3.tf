# Query the current AWS region so we know its S3 endpoint
data "aws_region" "current" {}

# Encryption
resource "aws_kms_key" "mykey" {
  description             = "This key is used to encrypt bucket objects"
  deletion_window_in_days = 10
  enable_key_rotation     = true
}

# Create the S3 bucket in which the static content for the site should be hosted
resource "aws_s3_bucket" "this" {
  count  = "${var.bucket_override_name == "" ? 1 : 0}"
  bucket = "${local.bucket_name}"
  tags   = "${var.tags}"

  # Enable versioning
  versioning {
    enabled = true
    mfa_delete = true
  }

  logging {
    target_bucket = aws_s3_bucket.this.id
    target_prefix = "log/"
  }

  # encrypted at rest
  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        kms_master_key_id = aws_kms_key.mykey.arn
        sse_algorithm     = "aws:kms"
      }
    }
  }

  # Add a CORS configuration, so that we don't have issues with webfont loading
  cors_rule {
    allowed_headers = ["*"]
    allowed_methods = ["GET"]
    allowed_origins = ["*"]
    max_age_seconds = 3000
  }

  # Enable website hosting
  website {
    index_document = "index.html"
    error_document = "error.html"
  }
}

# Use a bucket policy (instead of the simpler acl = "public-read") so we don't need to always remember to upload objects with:
resource "aws_s3_bucket_policy" "this" {
  depends_on = ["aws_s3_bucket.this"]              
  count      = "${var.bucket_override_name == "" ? 1 : 0}"
  bucket     = "${local.bucket_name}"

  # https://docs.aws.amazon.com/AmazonS3/latest/dev/example-bucket-policies.html#example-bucket-policies-use-case-2
  policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": "*",
      "Action": "s3:GetObject",
      "Resource": "arn:aws:s3:::${local.bucket_name}/*",
      "Condition": {
        "StringEquals": {
          "aws:UserAgent": "${random_string.s3_read_password.result}"
        }
      }
    }
  ]
}
POLICY
}
