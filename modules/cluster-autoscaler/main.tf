# modules/cluster-autoscaler/main.tf
locals {
  sa_name   = "cluster-autoscaler"
  ns        = "kube-system"
  role_name = "${var.project}-${var.environment}-autoscaler-irsa"
}

resource "aws_iam_role" "autoscaler_irsa" {
  name = local.role_name

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = { Federated = var.cluster_oidc_provider }
      Action = "sts:AssumeRoleWithWebIdentity"
      Condition = {
        StringEquals = {
          "${replace(var.cluster_oidc_provider, "https://", "")}:sub" = "system:serviceaccount:${local.ns}:${local.sa_name}"
        }
      }
    }]
  })

  tags = var.tags
}

resource "aws_iam_role_policy_attachment" "autoscaler_attach" {
  role       = aws_iam_role.autoscaler_irsa.name
  policy_arn = "arn:aws:iam::aws:policy/AutoScalingFullAccess" # fine for dev; consider least-privilege later
}

resource "kubernetes_service_account_v1" "autoscaler" {
  metadata {
    name      = local.sa_name
    namespace = local.ns
    annotations = {
      "eks.amazonaws.com/role-arn" = aws_iam_role.autoscaler_irsa.arn
    }
  }
}

resource "helm_release" "cluster_autoscaler" {
  name       = "cluster-autoscaler"
  repository = "https://kubernetes.github.io/autoscaler"
  chart      = "cluster-autoscaler"
  namespace  = local.ns
  version    = "9.23.1"
  timeout    = 900
  # Allow cleanup if it fails so you don't get 'sh.helm.release' errors
  cleanup_on_fail = true
  values = [
    yamlencode({
      autoDiscovery = {
        clusterName = var.cluster_name
      }
      awsRegion = var.region
      rbac = {
        serviceAccount = {
          create = false
          name   = kubernetes_service_account_v1.autoscaler.metadata[0].name
        }
      }
      extraArgs = {
        # Optional: helps CA find ASGs by tags
        "skip-nodes-with-local-storage" = "false"
        "balance-similar-node-groups"   = "true"
      }
    })
  ]
}
