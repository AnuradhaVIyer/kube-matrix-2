region              = "us-west-2"
env                 = "prod"
prefix              = "km"
bucket_prefix       = "km-terraform-state"
dynamodb_table_name = "terraform-locks"
tags = {
  Project     = "kube-matrix"
  Environment = "prod"
  ManagedBy   = "terraform"
}
