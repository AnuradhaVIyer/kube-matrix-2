#########################################
# Locals
#########################################
locals {
  name_prefix = "${var.name_prefix}-${var.project}-${var.environment}" # compound name prefix
}

#########################################
# Global Settings
#########################################
variable "project" {
  description = "Project name"
  type        = string
  default     = "km"
}

variable "environment" {
  description = "Environment (dev/stage/prod)"
  type        = string
  default     = "dev"
  validation {
    condition     = can(regex("^(dev|stage|prod)$", var.environment))
    error_message = "Environment must be dev, stage, or prod"
  }
}

variable "region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "region_short" {
  description = "Short AWS region code"
  type        = string
  default     = "use1"
}

variable "tags" {
  description = "Additional resource tags"
  type        = map(string)
  default     = { Project = "km", Environment = "dev", Owner = "DevTeam" }
}

variable "component" {
  description = "Module component name (used by network module)"
  type        = string
  default     = "vpc"
}

#########################################
# Availability Zones
#########################################
variable "az_count" {
  description = "Number of AZs"
  type        = number
  default     = 2
}

variable "az1" {
  description = "Availability Zone 1"
  type        = string
}

variable "az2" {
  description = "Availability Zone 2"
  type        = string
}

variable "azs" {
  description = "Specific Availability Zones to use"
  type        = list(string)
  default     = []
}

#########################################
# VPC Settings
#########################################
variable "vpc_cidr" {
  description = "VPC CIDR block"
  type        = string
  default     = "10.10.0.0/16"
}

variable "public_subnet_cidrs" {
  description = "Public subnet CIDR blocks"
  type        = list(string)
  default     = ["10.10.1.0/24", "10.10.2.0/24"]
}

variable "private_subnet_cidrs" {
  description = "Private subnet CIDR blocks"
  type        = list(string)
  default     = ["10.10.101.0/24", "10.10.102.0/24"]
}

variable "enable_nat_per_az" {
  description = "Enable 1 NAT gateway per AZ"
  type        = bool
  default     = false
}

variable "access_cidr" {
  description = "Allowed CIDR for SSH or administrative access"
  type        = string
  default     = "34.229.141.205/32"
}

#########################################
# EC2 Bastion / Admin
#########################################
variable "instance_type" {
  description = "Bastion / Admin EC2 instance type"
  type        = string
}

variable "ssh_public_key" {
  description = "Public key for SSH access"
  type        = string
}

variable "ec2_admin_username" {
  description = "Admin username for EC2"
  type        = string
}

variable "admin_password" {
  description = "Admin password for EC2"
  type        = string
  sensitive   = true
}

#########################################
# EKS Cluster
#########################################
variable "name_prefix" {
  description = "Name prefix for resources"
  type        = string
}

variable "cluster_name" {
  description = "EKS Cluster Name"
  type        = string
}

variable "eks_cluster_version" {
  description = "Kubernetes version"
  type        = string
  default     = "1.34"
}

variable "eks_node_instance_type" {
  description = "EKS Node instance type"
  type        = string
}

variable "eks_node_instance_types" {
  description = "EKS Node instance types (list)"
  type        = list(string)
  default     = ["t3.medium"]
}

variable "eks_node_min_size" {
  description = "Minimum number of EKS nodes"
  type        = number
}

variable "eks_node_max_size" {
  description = "Maximum number of EKS nodes"
  type        = number
}

variable "eks_node_desired_size" {
  description = "Desired number of EKS nodes"
  type        = number
}

variable "eks_disk_size" {
  description = "Node disk size in GB"
  type        = number
}

#########################################
# Aurora Serverless v2
#########################################
variable "aurora_database_name" {
  description = "Aurora MySQL DB name"
  type        = string
}

variable "aurora_master_username" {
  description = "Aurora master username"
  type        = string
  sensitive   = true
}

variable "aurora_master_password" {
  description = "Aurora master password"
  type        = string
  sensitive   = true
}

variable "aurora_engine_version" {
  description = "Aurora MySQL engine version"
  type        = string
  default     = "8.0.mysql_aurora.3.08.2"
}

variable "aurora_min_capacity" {
  description = "Serverless v2 minimum ACUs"
  type        = number
  default     = 0.5
}

variable "aurora_max_capacity" {
  description = "Serverless v2 maximum ACUs"
  type        = number
  default     = 4
}

variable "aurora_backup_retention_days" {
  description = "Aurora backup retention in days"
  type        = number
  default     = 7
}

variable "aurora_serverless_v2_scaling_min" {
  description = "Aurora Serverless v2 min scaling"
  type        = number
  default     = 0.5
}

variable "aurora_serverless_v2_scaling_max" {
  description = "Aurora Serverless v2 max scaling"
  type        = number
  default     = 4
}

variable "db_master_password_ssm_key" {
  description = "SSM parameter name to store DB master password securely"
  type        = string
}




# locals {
#   name_prefix  = "${var.name_prefix}-${var.project}-${var.environment}" # if you want name_prefix compounded
  
# }

# # Read the EKS cluster created by module.eks
# /*data "aws_eks_cluster" "main" {
#   name = local.cluster_name
# }

# data "tls_certificate" "cluster" {
#   url = data.aws_eks_cluster.main.identity[0].oidc[0].issuer
# }*/

# # Create OIDC provider for IRSA
# /*resource "aws_iam_openid_connect_provider" "eks" {
#   url             = data.aws_eks_cluster.main.identity[0].oidc[0].issuer
#   client_id_list  = ["sts.amazonaws.com"]
#   thumbprint_list = [data.tls_certificate.cluster.certificates[0].sha1_fingerprint]
# }*/


# #########################################
# # Global Settings
# #########################################

# variable "project" {
#   description = "Project name"
#   type        = string
#   default     = "km"
# }

# variable "environment" {
#   description = "Environment (dev/stage/prod)"
#   type        = string
#   default     = "dev"

#   validation {
#     condition     = can(regex("^(dev|stage|prod)$", var.environment))
#     error_message = "Environment must be dev, stage, or prod"
#   }
# }


# variable "region" {
#   description = "AWS region"
#   type        = string
#   default     = "us-east-1"
# }

# variable "tags" {
#   description = "Additional resource tags"
#   type        = map(string)
#   default     = { Owner = "platform-team", CostCenter = "CC-12345" }
# }


# #########################################
# # VPC Settings
# #########################################
# variable "component" { default = "vpc" }

# variable "vpc_cidr" {
#   description = "VPC CIDR block"
#   type        = string
#   default     = "10.10.0.0/16"
# }

# variable "public_subnet_cidrs" {
#   description = "Public subnet CIDR blocks"
#   type        = list(string)
#   default     = ["10.10.1.0/24", "10.10.2.0/24"]
# }

# variable "private_subnet_cidrs" {
#   description = "Private subnet CIDR blocks"
#   type        = list(string)
#   default     = ["10.10.101.0/24", "10.10.102.0/24"]
# }

# variable "az_count" {
#   description = "Number of AZs (used if AZ list not provided)"
#   type        = number
#   default     = 2
# }

# variable "azs" {
#   description = "Specific Availability Zones to use"
#   type        = list(string)
#   default     = []
# }

# variable "enable_nat_per_az" {
#   description = "Enable 1 NAT gateway per AZ"
#   type        = bool
#   default     = false
# }

# variable "access_cidr" {
#   description = "Allowed CIDR for SSH or administrative access"
#   type        = string
#   default     = "34.229.141.205/32"
# }


# #########################################
# # EKS Settings
# #########################################

# variable "name_prefix" {
#   description = "Name Prefix"
#   type        = string
# }

# variable "cluster_name" {
#   description = "EKS Cluster Name"
#   type        = string
# }

# variable "eks_cluster_version" {
#   description = "Kubernetes version"
#   type        = string
#   default     = "1.34"
# }

# variable "eks_node_instance_types" {
#   description = "Node instance types"
#   type        = list(string)
#   default     = ["t3.medium"]
# }

# variable "eks_node_instance_type" {
#   type = string
# }

# variable "eks_node_desired_size" {
#   type = number
# }

# variable "eks_node_min_size" {
#   type = number
# }

# variable "eks_node_max_size" {
#   type = number
# }

# variable "eks_disk_size" {
#   type = number
# }


# #########################################
# # Aurora Serverless v2 Settings
# #########################################

# variable "aurora_database_name" {
#   description = "Aurora MySQL DB name"
#   type        = string
#   default     = "kubeplatform"
# }

# variable "aurora_master_username" {
#   description = "Aurora master username"
#   type        = string
#   default     = "admin"
#   sensitive   = true
# }

# variable "aurora_master_password" {
#   type      = string
#   sensitive = true
# }

# variable "aurora_engine_version" {
#   description = "Aurora MySQL engine version"
#   type        = string
#   default     = "8.0.mysql_aurora.3.05.2"
# }

# variable "aurora_min_capacity" {
#   description = "Serverless v2 minimum ACUs"
#   type        = number
#   default     = 0.5
# }

# variable "aurora_max_capacity" {
#   description = "Serverless v2 maximum ACUs"
#   type        = number
#   default     = 4
# }
