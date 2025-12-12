locals {
  sa_name   = "aws-load-balancer-controller"
  ns        = "kube-system"
  role_name = "${var.project}-${var.environment}-alb-irsa"
}

data "aws_eks_cluster" "this" {
  name = var.cluster_name
}

data "aws_caller_identity" "current" {}

locals {
  oidc_url  = data.aws_eks_cluster.this.identity[0].oidc[0].issuer
  oidc_host = replace(local.oidc_url, "https://", "")
  oidc_provider_arn = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:oidc-provider/${local.oidc_host}"
}

# Lookup existing OIDC provider created by EKS
data "aws_iam_openid_connect_provider" "eks" {
  arn = local.oidc_provider_arn
}

resource "aws_iam_role" "alb_irsa" {
  name = local.role_name

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Federated = data.aws_iam_openid_connect_provider.eks.arn
      }
      Action    = "sts:AssumeRoleWithWebIdentity"
      Condition = {
        StringEquals = {
          "${local.oidc_host}:sub" = "system:serviceaccount:${local.ns}:${local.sa_name}"
          "${local.oidc_host}:aud" = "sts.amazonaws.com"
        }
      }
    }]
  })

  tags = var.tags
}

resource "aws_iam_policy" "alb_controller" {
  name        = "AWSLoadBalancerControllerIAMPolicy"
  description = "IAM policy for AWS Load Balancer Controller"
  policy      = file("${path.module}/iam_policy.json")
}

resource "aws_iam_role_policy_attachment" "alb_attach" {
  role       = aws_iam_role.alb_irsa.name
  policy_arn = aws_iam_policy.alb_controller.arn
}

resource "kubernetes_service_account_v1" "alb" {
  metadata {
    name      = local.sa_name
    namespace = local.ns
    annotations = {
      "eks.amazonaws.com/role-arn" = aws_iam_role.alb_irsa.arn
    }
  }
}

resource "helm_release" "aws_load_balancer_controller" {
  name       = "aws-load-balancer-controller"
  repository = "https://aws.github.io/eks-charts"
  chart      = "aws-load-balancer-controller"
  namespace  = local.ns
  version    = "1.8.1" # pick the latest stable version
  
  depends_on = [
    kubernetes_service_account_v1.alb
  ]
  
  values = [
    yamlencode({
      clusterName = var.cluster_name
      region      = var.region
      vpcId       = var.vpc_id

      serviceAccount = {
        create = false
        name   = kubernetes_service_account_v1.alb.metadata[0].name
      }
    })
  ]
}
