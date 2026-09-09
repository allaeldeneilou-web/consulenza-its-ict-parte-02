variable "environment" {
  type = string
}

variable "prefix" {
  type = string
}

resource "aws_s3_bucket" "sito" {
  bucket = "${var.prefix}-sito"

  tags = {
    Progetto         = "portale-its"
    Ambiente         = var.environment
    Owner            = "ITS-ICT"
    Repository       = "consulenza-its-ict"
    TechnicalContact = "allaeldene.ilou"
  }
}

resource "aws_s3_bucket_website_configuration" "sito" {
  bucket = aws_s3_bucket.sito.id
  index_document { suffix = "index.html" }
  error_document { key = "index.html" }
}

resource "aws_s3_bucket_versioning" "sito" {
  bucket = aws_s3_bucket.sito.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_public_access_block" "sito" {
  bucket                  = aws_s3_bucket.sito.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_server_side_encryption_configuration" "sito" {
  bucket = aws_s3_bucket.sito.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

output "sito_url" {
  value = aws_s3_bucket_website_configuration.sito.website_endpoint
}
