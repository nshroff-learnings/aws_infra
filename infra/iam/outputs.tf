output "iam_roles" {
  description = "Generic IAM role details keyed by logical name."
  value = {
    for name, role in module.iam_roles : name => {
      name = role.role_name
      arn  = role.role_arn
    }
  }
}

output "eks_roles" {
  description = "EKS role details keyed by logical name."
  value = {
    for name, role in aws_iam_role.eks : name => {
      name = role.name
      arn  = role.arn
    }
  }
}

output "custom_policy_arns" {
  description = "Customer managed policy ARNs keyed by logical name."
  value       = { for name, policy in aws_iam_policy.custom : name => policy.arn }
}

output "eks_admin_access_roles" {
  description = "EKS admin access role details keyed by logical name."
  value = {
    for name, role in aws_iam_role.eks_admin_access : name => {
      name       = role.name
      arn        = role.arn
      group_name = var.eks_admin_access_roles[name].group_name
    }
  }
}
