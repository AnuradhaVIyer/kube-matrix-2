terraform {
  backend "s3" {
    bucket         = "km-terraform-state-113020250920"
    key            = "envs/prod/vpc/terraform.tfstate"
    region         = "us-west-2"
    dynamodb_table = "km-terraform-locks"
    encrypt        = true
  }
}