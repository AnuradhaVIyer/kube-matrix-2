region              = "us-east-2"
env                 = "stage"
prefix              = "km"
bucket_prefix       = "km-terraform-state"
dynamodb_table_name = "terraform-locks"
tags = {
  Project     = "kube-matrix"
  Environment = "stage"
  ManagedBy   = "terraform"
}
