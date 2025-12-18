terraform {
  backend "s3" {
    bucket         = "km-terraform-state-113020250920"
    key            = "envs/stage/vpc/terraform.tfstate"
    region         = "us-east-2"
    dynamodb_table = "km-terraform-locks"
    encrypt        = true
  }
}






