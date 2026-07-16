# bootstrap/main.tf
# tfstate管理用のS3バケットとDynamoDBテーブルを作成する
# このディレクトリは一度だけ手動でapplyする

# ===================================================
# S3 Bucket for tfstate
# ===================================================
resource "aws_s3_bucket" "tfstate" {
  bucket = "standard-3tier-tfstate"

  tags = {
    Name = "standard-3tier-tfstate"
  }
}

resource "aws_s3_bucket_versioning" "tfstate" {
  bucket = aws_s3_bucket.tfstate.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "tfstate" {
  bucket = aws_s3_bucket.tfstate.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "tfstate" {
  bucket                  = aws_s3_bucket.tfstate.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# ===================================================
# DynamoDB Table for State Lock
# ===================================================
resource "aws_dynamodb_table" "tfstate_lock" {
  name         = "standard-3tier-tfstate-lock"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }

  tags = {
    Name = "standard-3tier-tfstate-lock"
  }
}
