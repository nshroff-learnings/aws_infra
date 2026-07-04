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
  description = "Additional IAM-specific tags."
  type        = map(string)
  default     = {}
}

variable "iam_roles" {
  description = "Generic IAM roles managed by the shared iam-role module."
  type = map(object({
    role_suffix                    = optional(string, "role")
    role_name                      = optional(string)
    description                    = optional(string, "IAM role managed by Terraform.")
    path                           = optional(string, "/")
    trusted_services               = optional(set(string), [])
    trusted_aws_principals         = optional(set(string), [])
    trusted_federated_principals   = optional(set(string), [])
    federated_conditions           = optional(list(object({ test = string, variable = string, values = list(string) })), [])
    custom_assume_role_policy_json = optional(string)
    managed_policy_arns            = optional(set(string), [])
    inline_policies                = optional(map(string), {})
    permissions_boundary_arn       = optional(string)
    max_session_duration           = optional(number, 3600)
    force_detach_policies          = optional(bool, false)
    create_instance_profile        = optional(bool, false)
    instance_profile_name          = optional(string)
    tags                           = optional(map(string), {})
  }))
  default = {}
}

variable "eks_roles" {
  description = "EKS service roles keyed by logical name."
  type = map(object({
    role_name                = string
    description              = optional(string, "EKS IAM role managed by Terraform.")
    trusted_services         = set(string)
    managed_policy_arns      = set(string)
    permissions_boundary_arn = optional(string)
    tags                     = optional(map(string), {})
  }))
  default = {}
}

variable "custom_policies" {
  description = "Customer managed IAM policies keyed by logical name."
  type = map(object({
    name        = string
    description = optional(string)
    path        = optional(string, "/")
    policy_json = string
    tags        = optional(map(string), {})
  }))
  default = {}

  validation {
    condition     = alltrue([for policy in values(var.custom_policies) : can(jsondecode(policy.policy_json))])
    error_message = "Each custom policy_json must be valid JSON."
  }
}
