variable "env" {
  type        = string
  description = "Environment: dev, stage, prod"
}

variable "region" {
  type        = string
  description = "AWS region for this environment"
}

variable "prefix" {
  type        = string
  description = "Prefix for naming resources"
  default     = "km"
}

variable "bucket_prefix" {
  type        = string
  description = "Base prefix for the S3 bucket before timestamp is added"
  default     = "km-terraform-state"
}

variable "dynamodb_table_name" {
  type        = string
  description = "Name of the DynamoDB table for tfstate locking"
}

variable "tags" {
  type    = map(string)
  default = {}
}



# variable "region" {
#   type        = string
#   description = "AWS region"
# }

# variable "prefix" {
#   type        = string
#   description = "Prefix for naming resources"
# }

# variable "bucket_prefix" {
#   type        = string
#   description = "Base prefix for the S3 bucket before timestamp is added"
# }

# variable "dynamodb_table_name" {
#   type        = string
#   description = "Name of the DynamoDB table for tfstate locking"
# }

# variable "tags" {
#   type    = map(string)
#   default = {}
# }
