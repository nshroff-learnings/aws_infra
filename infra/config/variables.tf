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
  description = "Additional config-specific tags."
  type        = map(string)
  default     = {}
}

variable "ecr_repositories" {
  description = "ECR repositories keyed by logical name."
  type = map(object({
    repository_suffix              = optional(string, "app")
    repository_name                = optional(string)
    image_tag_mutability           = optional(string, "IMMUTABLE")
    scan_on_push                   = optional(bool, true)
    kms_key_arn                    = optional(string)
    force_delete                   = optional(bool, false)
    create_lifecycle_policy        = optional(bool, true)
    lifecycle_policy_json          = optional(string)
    untagged_image_expiration_days = optional(number, 14)
    max_tagged_image_count         = optional(number, 30)
    lifecycle_tag_prefixes         = optional(list(string), ["v", "release", "main", "dev"])
    repository_policy_json         = optional(string)
    tags                           = optional(map(string), {})
  }))
  default = {}
}

variable "secrets" {
  description = "Secrets Manager secret metadata keyed by logical name. Secret values are intentionally not managed here."
  type = map(object({
    name                    = string
    description             = optional(string)
    kms_key_id              = optional(string)
    recovery_window_in_days = optional(number, 30)
    tags                    = optional(map(string), {})
  }))
  default = {}
}
