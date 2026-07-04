output "ecr_repositories" {
  description = "ECR repository details keyed by logical name."
  value = {
    for name, repo in module.ecr_repositories : name => {
      name = repo.repository_name
      arn  = repo.repository_arn
      url  = repo.repository_url
    }
  }
}

output "secret_arns" {
  description = "Secrets Manager secret ARNs keyed by logical name."
  value       = { for name, secret in aws_secretsmanager_secret.this : name => secret.arn }
}
