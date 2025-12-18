locals {
  name_prefix = "${var.project}-${var.environment}"
}

# EKS Cluster IAM Role
resource "aws_iam_role" "cluster" {
  name = "${local.name_prefix}-eks-cluster-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "eks.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = var.tags
}

resource "aws_iam_role_policy_attachment" "cluster" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = aws_iam_role.cluster.name
}

# EKS Cluster
resource "aws_eks_cluster" "main" {
  name     = "${local.name_prefix}-eks"
  version  = var.eks_cluster_version
  role_arn = aws_iam_role.cluster.arn

  vpc_config {
  subnet_ids              = var.private_subnet_ids
  endpoint_private_access = true
  endpoint_public_access  = true
}
  # This is the critical setting for the new Access Entry features to work
  access_config {
    authentication_mode                         = "API_AND_CONFIG_MAP"
    bootstrap_cluster_creator_admin_permissions = true
  }
  enabled_cluster_log_types = ["api", "audit", "authenticator", "controllerManager", "scheduler"]

  tags = merge(
    var.tags,
    {
      Name = "${local.name_prefix}-eks"
    }
  )

  depends_on = [aws_iam_role_policy_attachment.cluster]
}

# Node Group IAM Role
resource "aws_iam_role" "node_group" {
  name = "${local.name_prefix}-eks-node-group-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = var.tags
}

resource "aws_iam_role_policy_attachment" "node_group_worker" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role       = aws_iam_role.node_group.name
}

resource "aws_iam_role_policy_attachment" "node_group_cni" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = aws_iam_role.node_group.name
}

resource "aws_iam_role_policy_attachment" "node_group_registry" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = aws_iam_role.node_group.name
}

resource "aws_iam_role_policy_attachment" "node_group_ssm" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
  role       = aws_iam_role.node_group.name
}

# SSM Parameter Store Access Policy for Nodes
resource "aws_iam_role_policy" "node_ssm" {
  name = "${local.name_prefix}-node-ssm-policy"
  role = aws_iam_role.node_group.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ssm:GetParameter",
          "ssm:GetParameters",
          "ssm:GetParametersByPath"
        ]
        Resource = "arn:aws:ssm:*:*:parameter/${local.name_prefix}/*"
      }
    ]
  })
}

# Node Group
resource "aws_eks_node_group" "main" {
  cluster_name    = aws_eks_cluster.main.name
  node_group_name = "${local.name_prefix}-node-group"
  node_role_arn   = aws_iam_role.node_group.arn
  subnet_ids      = var.private_subnet_ids
  version         = var.eks_cluster_version

  scaling_config {
    desired_size = var.node_group_desired_size
    min_size     = var.node_group_min_size
    max_size     = var.node_group_max_size
  }

  instance_types = [var.node_instance_type]

  tags = merge(
    var.tags,
    {
      Name = "${local.name_prefix}-node-group"
      # Required for cluster-autoscaler
    "k8s.io/cluster-autoscaler/enabled"               = "true"
    "k8s.io/cluster-autoscaler/${var.cluster_name}"   = "owned"

    # Recommended AWS/EKS tagging
    "kubernetes.io/cluster/${var.cluster_name}"       = "owned"
    }
    
  )

  depends_on = [
    aws_iam_role_policy_attachment.node_group_worker,
    aws_iam_role_policy_attachment.node_group_cni,
    aws_iam_role_policy_attachment.node_group_registry,
    aws_iam_role_policy_attachment.node_group_ssm
  ]
}

# OIDC Provider for Pod IAM Roles
data "tls_certificate" "cluster" {
  url = aws_eks_cluster.main.identity[0].oidc[0].issuer
}

resource "aws_iam_openid_connect_provider" "cluster" {
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = [data.tls_certificate.cluster.certificates[0].sha1_fingerprint]
  url             = aws_eks_cluster.main.identity[0].oidc[0].issuer

  tags = var.tags
}

# 2. Add the Access Entry for GitHub
resource "aws_eks_access_entry" "github_actions" {
  cluster_name      = aws_eks_cluster.main.name
  principal_arn     = var.github_actions_role_arn
  type              = "STANDARD"
}

# 3. Grant the Admin Policy to that Role
resource "aws_eks_access_policy_association" "github_actions_admin" {
  cluster_name  = aws_eks_cluster.main.name
  policy_arn    = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"
  principal_arn = aws_eks_access_entry.github_actions.principal_arn

  access_scope {
    type = "cluster"
  }
}

# AWS Cloudwatch Observability
data "aws_eks_addon_version" "current" {
  addon_name       = "amazon-cloudwatch-observability"
  kubernetes_version = aws_eks_cluster.main.version # reference your cluster's K8s version
  most_recent      = true
}
# 1. Define the Log Group manually in Terraform
resource "aws_cloudwatch_log_group" "eks_logs" {
  # The name must match exactly what the add-on expects
  name              = "/aws/containerinsights/${var.cluster_name}/performance"
  retention_in_days = 7
  
  # Ensure it is deleted on destroy
  skip_destroy = false 
}

resource "aws_eks_addon" "cloudwatch_observability" {
  cluster_name             = aws_eks_cluster.main.name
  addon_name               = "amazon-cloudwatch-observability"
  addon_version            = data.aws_eks_addon_version.current.version
  service_account_role_arn = var.cloudwatch_observability_role_arn
  # This ensures the log group is created first and tracked
  depends_on = [aws_cloudwatch_log_group.eks_logs]
}



