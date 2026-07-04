output "argocd_namespace" {
  description = "Namespace where Argo CD was installed."
  value       = var.argocd_namespace
}

output "argocd_root_application" {
  description = "Root Argo CD Application bootstrapped by Terraform."
  value       = var.platform_root_app_name
}

output "platform_repo_url" {
  description = "Platform repository URL tracked by the root Argo CD Application."
  value       = var.platform_repo_url
}

