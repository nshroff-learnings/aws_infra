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

variable "github_actions_role_name" {
  description = "IAM role name used by GitHub Actions for optional EKS cluster admin access entry."
  type        = string
  default     = "aws-infra-github-actions"
}

variable "common_tags" {
  description = "Tags shared by all components in an environment."
  type        = map(string)
  default     = {}
}

variable "tags" {
  description = "Additional compute-specific tags."
  type        = map(string)
  default     = {}
}

variable "eks_clusters" {
  description = "EKS clusters keyed by logical name. Role and subnet inputs default from networking/iam remote state when omitted."
  type = map(object({
    name                                        = string
    cluster_role_arn                            = optional(string)
    cluster_role_key                            = optional(string, "cluster")
    kubernetes_version                          = optional(string, "1.34")
    subnet_ids                                  = optional(list(string))
    subnet_keys                                 = optional(list(string), ["private-01", "private-02"])
    security_group_ids                          = optional(list(string), [])
    endpoint_private_access                     = optional(bool, true)
    endpoint_public_access                      = optional(bool, false)
    public_access_cidrs                         = optional(list(string), [])
    enabled_cluster_log_types                   = optional(list(string), ["api", "audit", "authenticator", "controllerManager", "scheduler"])
    kms_key_arn                                 = optional(string)
    authentication_mode                         = optional(string, "API_AND_CONFIG_MAP")
    bootstrap_cluster_creator_admin_permissions = optional(bool, false)
    access_entries = optional(map(object({
      principal_arn       = optional(string)
      principal_role_name = optional(string)
      type                = optional(string, "STANDARD")
      policy_associations = optional(map(object({
        policy_arn        = string
        access_scope_type = optional(string, "cluster")
        namespaces        = optional(list(string), [])
      })), {})
    })), {})
    tags = optional(map(string), {})
    node_groups = map(object({
      name               = string
      node_role_arn      = optional(string)
      node_role_key      = optional(string, "node")
      subnet_ids         = optional(list(string))
      subnet_keys        = optional(list(string), ["private-01", "private-02"])
      kubernetes_version = optional(string)
      ami_type           = optional(string, "AL2023_x86_64_STANDARD")
      capacity_type      = optional(string, "ON_DEMAND")
      disk_size          = optional(number, 50)
      instance_types     = optional(list(string), ["t3.micro"])
      desired_size       = number
      min_size           = number
      max_size           = number
      max_unavailable    = optional(number, 1)
      labels             = optional(map(string), {})
      taints = optional(list(object({
        key    = string
        value  = string
        effect = string
      })), [])
      tags = optional(map(string), {})
    }))
  }))
  default = {}

  validation {
    condition = alltrue([
      for cluster in values(var.eks_clusters) : cluster.endpoint_private_access || cluster.endpoint_public_access
    ])
    error_message = "Each EKS cluster must enable at least one endpoint access mode."
  }


  validation {
    condition = alltrue([
      for cluster in values(var.eks_clusters) : length(setsubtract(
        toset(["api", "audit", "authenticator", "controllerManager", "scheduler"]),
        toset(cluster.enabled_cluster_log_types)
      )) == 0
    ])
    error_message = "Each EKS cluster must enable api, audit, authenticator, controllerManager, and scheduler control plane logs."
  }

  validation {
    condition = alltrue([
      for cluster in values(var.eks_clusters) : contains(["1.33", "1.34", "1.35", "1.36"], cluster.kubernetes_version)
    ])
    error_message = "Each EKS cluster must use a Kubernetes version in current EKS standard support: 1.33, 1.34, 1.35, or 1.36."
  }
}



