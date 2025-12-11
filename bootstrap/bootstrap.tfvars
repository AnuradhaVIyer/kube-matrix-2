region              = "us-east-1"
prefix              = "km"
bucket_prefix       = "km-terraform-state-dev"
dynamodb_table_name = "km-terraform-locks-dev"
tags = {
  Project     = "kube-matrix"
  Environment = "bootstrap"
  ManagedBy   = "terraform"
}
