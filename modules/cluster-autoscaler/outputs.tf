output "autoscaler_irsa_role_arn" {
  description = "IAM Role ARN used by the Cluster Autoscaler service account"
  value       = aws_iam_role.autoscaler_irsa.arn
}

output "autoscaler_service_account_name" {
  description = "Kubernetes service account name for Cluster Autoscaler"
  value       = kubernetes_service_account_v1.autoscaler.metadata[0].name
}

output "autoscaler_helm_release_name" {
  description = "Helm release name for Cluster Autoscaler"
  value       = helm_release.cluster_autoscaler.name
}
