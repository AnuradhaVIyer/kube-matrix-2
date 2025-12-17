#########################################
# VPC / NETWORK MODULE
#########################################

module "network" {
  source      = "./modules/network"
  project     = var.project
  component   = var.component
  environment = var.environment
  region      = var.region
  vpc_cidr    = var.vpc_cidr
  az_count    = var.az_count
  public_subnet_cidrs  = var.public_subnet_cidrs
  private_subnet_cidrs = var.private_subnet_cidrs
  enable_nat_per_az    = var.enable_nat_per_az
  access_cidr      = var.access_cidr
  tags                 = var.tags
}

#########################################
# ECR REPOSITORIES
#########################################

 module "ecr_frontend" {
  source = "./modules/ecr"
  name   = "${local.name_prefix}-frontend"
}

module "ecr_backend" {
  source = "./modules/ecr"
  name   = "${local.name_prefix}-backend"
}

module "ecr_database" {
  source = "./modules/ecr"
  name   = "${local.name_prefix}-database"
}

#########################################
# AURORA SERVERLESS v2
#########################################

 module "database" {
  source = "./modules/database"

  project            = var.project
  environment        = var.environment
  vpc_id             = module.network.vpc_id
  private_subnet_ids = module.network.private_subnet_ids

  database_name   = var.aurora_database_name
  master_username = var.aurora_master_username
  master_password = var.aurora_master_password
  engine_version  = var.aurora_engine_version

  min_capacity = var.aurora_min_capacity
  max_capacity = var.aurora_max_capacity

  allowed_security_group_ids = [module.eks.cluster_security_group_id]

  tags = var.tags

  depends_on = [module.network, module.eks]
} 

#########################################
# EKS CLUSTER
#########################################

module "eks" {
  source = "./modules/eks"

  project     = var.project
  environment = var.environment
  cluster_name = "${local.name_prefix}-eks"
  eks_cluster_version = var.eks_cluster_version

  vpc_id             = module.network.vpc_id
  private_subnet_ids = module.network.private_subnet_ids
  public_subnet_ids  = module.network.public_subnet_ids

  # MUST MATCH MODULE VARIABLES EXACTLY
  node_instance_type      = var.eks_node_instance_type
  node_group_desired_size = var.eks_node_desired_size
  node_group_min_size     = var.eks_node_min_size
  node_group_max_size     = var.eks_node_max_size

  disk_size = var.eks_disk_size

  aurora_db_sg_id = null

  tags = var.tags
  github_actions_role_arn = "arn:aws:iam::123456789012:role/Your-GitHub-Role"
  depends_on = [module.network]
}

#########################################
# Subnet Tagging
#########################################
module "subnet_tags" {
  source            = "./modules/subnet-tags"
  cluster_name       = module.eks.cluster_name
  public_subnet_ids  = module.network.public_subnets
  private_subnet_ids = module.network.private_subnets
  depends_on = [module.network, module.eks]
}

#########################################
# ALB Controller
#########################################
module "alb_controller" {
  source                = "./modules/alb-controller"
  cluster_name          = module.eks.cluster_name
  region                = var.region
  project               = var.project
  vpc_id                = module.network.vpc_id
  name_prefix           = var.name_prefix
  environment           = var.environment
  cluster_oidc_provider = module.eks.cluster_oidc_provider_arn
  tags                  = var.tags
  depends_on = [module.eks]
}


#########################################
# Cluster Autoscaler
#########################################
module "cluster_autoscaler" {
  source                = "./modules/cluster-autoscaler"
  cluster_name          = module.eks.cluster_name
  region                = var.region
  name_prefix           = var.name_prefix
  project               = var.project
  environment           = var.environment
  cluster_oidc_provider = module.eks.cluster_oidc_provider_arn
  tags                  = var.tags
  depends_on = [module.eks]
}




