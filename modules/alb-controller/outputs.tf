output "alb_irsa_role_arn" {
  description = "IAM Role ARN used by the ALB Controller service account"
  value       = aws_iam_role.alb_irsa.arn
}

output "alb_service_account_name" {
  description = "Kubernetes service account name for ALB Controller"
  value       = kubernetes_service_account_v1.alb.metadata[0].name
}

/* output "alb_helm_release_name" {
  description = "Helm release name for ALB Controller"
  value       = helm_release.alb_controller.name
} */

