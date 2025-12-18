region              = "us-east-1"
env                 = "dev"
prefix              = "km"
bucket_prefix       = "km-terraform-state"
dynamodb_table_name = "terraform-locks"
tags = {
  Project     = "kube-matrix"
  Environment = "dev"
  ManagedBy   = "terraform"
}
