variable "project_name" {
  description = "Short project name used in resource names."
  type        = string

  validation {
    condition     = length(trimspace(var.project_name)) > 0
    error_message = "project_name must not be empty."
  }
}

variable "environment" {
  description = "Environment name."
  type        = string

  validation {
    condition     = contains(["dev", "qa", "staging", "prod"], var.environment)
    error_message = "environment must be one of dev, qa, staging, or prod."
  }
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
  description = "Additional networking-specific tags."
  type        = map(string)
  default     = {}
}

variable "vpc_cidr" {
  description = "IPv4 CIDR block for the VPC."
  type        = string

  validation {
    condition     = can(cidrnetmask(var.vpc_cidr))
    error_message = "vpc_cidr must be a valid IPv4 CIDR block."
  }
}

variable "private_subnet_cidrs" {
  description = "Private subnet CIDR blocks."
  type        = list(string)

  validation {
    condition     = alltrue([for cidr in var.private_subnet_cidrs : can(cidrnetmask(cidr))])
    error_message = "Each private subnet CIDR must be valid."
  }
}

variable "public_subnet_cidrs" {
  description = "Public subnet CIDR blocks."
  type        = list(string)
  default     = []

  validation {
    condition     = alltrue([for cidr in var.public_subnet_cidrs : can(cidrnetmask(cidr))])
    error_message = "Each public subnet CIDR must be valid."
  }
}

variable "availability_zones" {
  description = "Optional availability zones for subnet placement."
  type        = list(string)
  default     = []
}

variable "map_public_ip_on_launch" {
  description = "Whether public subnets assign public IPs on launch."
  type        = bool
  default     = false
}

variable "network_acls" {
  description = "Network ACLs keyed by logical name."
  type = map(object({
    subnet_keys = list(string)
    ingress_rules = list(object({
      rule_no    = number
      action     = string
      protocol   = string
      cidr_block = string
      from_port  = number
      to_port    = number
    }))
    egress_rules = list(object({
      rule_no    = number
      action     = string
      protocol   = string
      cidr_block = string
      from_port  = number
      to_port    = number
    }))
  }))
  default = {}
}
