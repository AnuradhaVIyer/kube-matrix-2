# ---------------------------------------
# Project / Environment
# ---------------------------------------
project             = "km"
environment         = "prod"

# Use the same region as the prod S3 backend
region              = "us-east-1"
region_short        = "use1"

az_count            = 2
az1                 = "use1a"
az2                 = "use1b"

tags = {
  Project     = "km"
  Environment = "prod"
  Owner       = "ProdTeam"
}

# ---------------------------------------
# VPC Settings
# ---------------------------------------
vpc_cidr            = "10.10.0.0/16"

public_subnet_cidrs  = [
  "10.10.1.0/24",
  "10.10.2.0/24"
]

private_subnet_cidrs = [
  "10.10.101.0/24",
  "10.10.102.0/24"
]

# ---------------------------------------
# EC2 Bastion / Admin (if used)
# ---------------------------------------
instance_type        = "t3.micro"
ssh_public_key       = "~/.ssh/id_rsa.pub"
ec2_admin_username   = "ec2-user"
admin_password       = "ProdSecurePassword123!"

# ---------------------------------------
# EKS Cluster
# ---------------------------------------
eks_cluster_version            = "1.34"
eks_node_instance_type         = "t3.small"
eks_node_min_size              = 1
eks_node_max_size              = 3
eks_node_desired_size          = 2
eks_disk_size                  = 30
github_actions_role_arn        = "arn:aws:iam::749635699241:role/github-actions-eks-deployer-role"

# Security group will be created by module, no manual values needed

# ---------------------------------------
# Aurora MySQL Serverless V2
# ---------------------------------------
aurora_database_name          = "km_prod"
aurora_master_username        = "mysqladmin"
aurora_master_password        = "ProdSecureDBPassword123!"
aurora_engine_version         = "8.0.mysql_aurora.3.08.2"

aurora_min_capacity           = 0.5
aurora_max_capacity           = 4

aurora_backup_retention_days  = 7

aurora_serverless_v2_scaling_min = 0.5
aurora_serverless_v2_scaling_max = 4

# Used by module to create secure param
db_master_password_ssm_key   = "/km/prod/db/master_password"
db_username                  = "/km/prod/db/username"
db_host                      = "/km/prod/db/host"
db_name                      = "/km/prod/db/name"

#EKS
cluster_name="eks"
name_prefix="km"
