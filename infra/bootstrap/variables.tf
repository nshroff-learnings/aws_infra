variable "project_name" {
  description = "Short project name used in resource names."
  type        = string
}

variable "environment" {
  description = "Environment name."
  type        = string
}

variable "aws_region" {
  description = "AWS region for this root module."
  type        = string
}

variable "common_tags" {
  description = "Tags shared by all components in an environment."
  type        = map(string)
  default     = {}
}

variable "tags" {
  description = "Additional bootstrap-specific tags."
  type        = map(string)
  default     = {}
}

variable "platform_cluster_name" {
  description = "Optional explicit platform EKS cluster name where Argo CD is bootstrapped. Defaults from compute remote state."
  type        = string
  default     = null
}

variable "platform_cluster_key" {
  description = "Compute layer EKS cluster key used to look up the platform cluster name from remote state."
  type        = string
  default     = "primary"
}

variable "tf_state_bucket" {
  description = "S3 bucket containing upstream Terraform state for dependency lookups."
  type        = string

  validation {
    condition     = length(trimspace(var.tf_state_bucket)) > 0
    error_message = "tf_state_bucket must be provided."
  }
}

variable "tf_state_region" {
  description = "AWS region for the Terraform state bucket."
  type        = string
}

variable "argocd_namespace" {
  description = "Namespace where platform Argo CD is installed."
  type        = string
  default     = "argocd"
}

variable "argocd_chart_version" {
  description = "Argo CD Helm chart version from https://argoproj.github.io/argo-helm."
  type        = string
  default     = "8.1.3"
}

variable "argocd_replicas" {
  description = "Replica count for horizontally scalable Argo CD components."
  type        = number
  default     = 2

  validation {
    condition     = var.argocd_replicas >= 1
    error_message = "argocd_replicas must be at least 1."
  }
}

variable "platform_repo_url" {
  description = "Git repository URL for the separate platform repository."
  type        = string

  validation {
    condition     = length(regexall("YOUR_ORG|YOUR_REPO|YOUR_PLATFORM_REPO", var.platform_repo_url)) == 0
    error_message = "platform_repo_url must be replaced with the real platform repository URL."
  }
}

variable "platform_repo_revision" {
  description = "Git revision Argo CD should track for the platform repository."
  type        = string
  default     = "main"
}

variable "platform_root_app_path" {
  description = "Path in the platform repository that contains Argo CD child Applications."
  type        = string
  default     = "argocd/apps"
}

variable "platform_root_app_name" {
  description = "Name of the root Argo CD Application."
  type        = string
  default     = "platform-root"
}
