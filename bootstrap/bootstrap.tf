terraform {
  required_version = ">= 1.5.6"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0"
    }
    time = {
      source  = "hashicorp/time"
      version = ">= 0.9"
    }
  }
}

provider "aws" {
  region = var.region
}

# Timestamp
resource "time_static" "s3_suffix" {}

locals {
  bucket_suffix        = replace(time_static.s3_suffix.rfc3339, "/[-T:Z]/", "")
  unique_bucket_name   = "${var.bucket_prefix}-${var.env}-${local.bucket_suffix}"
  unique_dynamodb_name = "${var.dynamodb_table_name}-${var.env}-${local.bucket_suffix}"
}

# S3 Bucket
resource "aws_s3_bucket" "terraform_state" {
  bucket = local.unique_bucket_name

  tags = merge(
    var.tags,
    {
      Name = "${var.prefix}-${var.env}-terraform-state"
    }
  )
}

resource "aws_s3_bucket_versioning" "state_versioning" {
  bucket = aws_s3_bucket.terraform_state.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_public_access_block" "state_public_block" {
  bucket = aws_s3_bucket.terraform_state.id

  block_public_acls       = true
  ignore_public_acls      = true
  block_public_policy     = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_server_side_encryption_configuration" "state_encrypt" {
  bucket = aws_s3_bucket.terraform_state.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# DynamoDB Table
resource "aws_dynamodb_table" "terraform_locks" {
  name         = local.unique_dynamodb_name
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }

  tags = merge(
    var.tags,
    {
      Name = "${var.prefix}-${var.env}-terraform-locks"
    }
  )
}

# Outputs
output "unique_bucket_name" {
  description = "The globally unique S3 bucket name created for Terraform state"
  value       = aws_s3_bucket.terraform_state.bucket
}

output "dynamodb_table_name" {
  value = aws_dynamodb_table.terraform_locks.name
}



# ###############################################################################
# # BOOTSTRAP RESOURCES FOR TERRAFORM STATE MANAGEMENT (WITH UNIQUE BUCKET NAME)
# ###############################################################################

# terraform {
#   required_version = ">= 1.3.0"

#   required_providers {
#     aws = {
#       source  = "hashicorp/aws"
#       version = ">= 5.0"
#     }
#     time = {
#       source = "hashicorp/time"
#       version = ">= 0.9"
#     }
#   }
# }

# provider "aws" {
#   region = var.region
# }

# ###############################################################################
# # Generate a ONE-TIME TIMESTAMP to append to bucket name
# ###############################################################################
# resource "time_static" "s3_suffix" {}

# # Example output: 20250212T093015Z → converted to simple suffix: 20250212093015
# locals {
#   bucket_suffix = replace(time_static.s3_suffix.rfc3339, "/[-T:Z]/", "")
#   unique_bucket_name = "${var.bucket_prefix}-${local.bucket_suffix}"
# }

# ###############################################################################
# # 1. S3 BUCKET (globally unique)
# ###############################################################################
# resource "aws_s3_bucket" "terraform_state" {
#   bucket = local.unique_bucket_name

#   tags = merge(
#     var.tags,
#     {
#       Name = "${var.prefix}-terraform-state"
#     }
#   )
# }

# resource "aws_s3_bucket_versioning" "state_versioning" {
#   bucket = aws_s3_bucket.terraform_state.id

#   versioning_configuration {
#     status = "Enabled"
#   }
# }

# resource "aws_s3_bucket_public_access_block" "state_public_block" {
#   bucket = aws_s3_bucket.terraform_state.id

#   block_public_acls       = true
#   ignore_public_acls      = true
#   block_public_policy     = true
#   restrict_public_buckets = true
# }

# resource "aws_s3_bucket_server_side_encryption_configuration" "state_encrypt" {
#   bucket = aws_s3_bucket.terraform_state.id

#   rule {
#     apply_server_side_encryption_by_default {
#       sse_algorithm = "AES256"
#     }
#   }
# }

# ###############################################################################
# # 2. DYNAMODB TABLE FOR STATE LOCKING
# ###############################################################################
# resource "aws_dynamodb_table" "terraform_locks" {
#   name         = var.dynamodb_table_name
#   billing_mode = "PAY_PER_REQUEST"
#   hash_key     = "LockID"

#   attribute {
#     name = "LockID"
#     type = "S"
#   }

#   tags = merge(
#     var.tags,
#     {
#       Name = "${var.prefix}-terraform-locks"
#     }
#   )
# }

# ###############################################################################
# # OUTPUTS
# ###############################################################################

# output "unique_bucket_name" {
#   description = "The globally unique S3 bucket name created for Terraform state"
#   value       = aws_s3_bucket.terraform_state.bucket
# }

# output "dynamodb_table_name" {
#   value = aws_dynamodb_table.terraform_locks.name
# }
