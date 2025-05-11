provider "aws" {
  region = "us-east-1"
}

resource "aws_s3_bucket" "tf_state" {
  bucket = "mccn-tf-state-bucket"

  versioning {
    enabled = true
  }

  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm = "AES256"
      }
    }
  }

  lifecycle {
    prevent_destroy = true
  }

  tags = {
    Name = "Terraform State Bucket"
  }
}

resource "aws_s3_bucket" "code_bucket" {
  bucket = "mcloud-code-bucket"

  versioning {
    enabled = true
  }
  
  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm = "AES256"
      }
    }
  }

  lifecycle {
    prevent_destroy = true
  }

  tags = {
    Name = "Code Bucket"
  }
}

resource "aws_dynamodb_table" "tf_lock" {
  name         = "mccn-tf-lock-table"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }

  tags = {
    Name = "Terraform Lock Table"
  }
}
