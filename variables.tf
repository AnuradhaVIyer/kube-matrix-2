#########################################
# Locals
#########################################
locals {
  name_prefix = "${var.project}-${var.environment}" # compound name prefix
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

variable "github_actions_role_arn" {
  description = "The ARN of the IAM role assumed by GitHub Actions"
  type        = string
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

variable "db_username" {
  description = "SSM parameter name to store DB username securely"
  type        = string
}
variable "db_host" {
  description = "SSM parameter name to store DB host securely"
  type        = string
}
variable "db_name" {
  description = "SSM parameter name to store DB name securely"
  type        = string
}

