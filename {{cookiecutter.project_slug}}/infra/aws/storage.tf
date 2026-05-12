{% if cookiecutter.cloud_provider == "aws" or cookiecutter.cloud_provider == "both" -%}
resource "aws_s3_bucket" "media" {
  bucket        = var.media_bucket
  force_destroy = !var.deletion_protection

  tags = { Name = var.media_bucket }
}

resource "aws_s3_bucket_versioning" "media" {
  bucket = aws_s3_bucket.media.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_public_access_block" "media" {
  bucket = aws_s3_bucket.media.id

  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

resource "aws_s3_bucket_cors_configuration" "media" {
  bucket = aws_s3_bucket.media.id

  cors_rule {
    allowed_headers = ["Content-Type", "x-amz-resumable"]
    allowed_methods = ["GET", "HEAD", "OPTIONS"]
    allowed_origins = length(var.cors_origins) > 0 ? var.cors_origins : ["*"]
    max_age_seconds = 3600
  }
}

resource "aws_s3_bucket_policy" "media_public_read" {
  bucket = aws_s3_bucket.media.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Sid       = "PublicReadGetObject"
      Effect    = "Allow"
      Principal = "*"
      Action    = "s3:GetObject"
      Resource  = "${aws_s3_bucket.media.arn}/*"
    }]
  })

  depends_on = [aws_s3_bucket_public_access_block.media]
}

# Tofu state bucket — only created in prod (is_primary=true).
resource "aws_s3_bucket" "tofu_state" {
  count = var.is_primary ? 1 : 0

  bucket        = "{{ cookiecutter.project_slug }}-tofu-state"
  force_destroy = false

  tags = { Name = "{{ cookiecutter.project_slug }}-tofu-state" }

  lifecycle {
    prevent_destroy = true
  }
}

resource "aws_s3_bucket_versioning" "tofu_state" {
  count  = var.is_primary ? 1 : 0
  bucket = one(aws_s3_bucket.tofu_state[*].id)

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_public_access_block" "tofu_state" {
  count  = var.is_primary ? 1 : 0
  bucket = one(aws_s3_bucket.tofu_state[*].id)

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}
{% endif -%}
