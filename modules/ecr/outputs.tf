output "ecr_repository_url" {
  value = aws_ecr_repository.this.repository_url
}

output "ecr_policy_arn" {
  value = aws_iam_policy.push_pull_policy.arn
}
