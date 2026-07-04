locals {
  tags = merge(var.common_tags, var.tags)

  eks_managed_policy_attachments = length(var.eks_roles) == 0 ? {} : merge([
    for role_key, role in var.eks_roles : {
      for policy_arn in role.managed_policy_arns : "${role_key}-${md5(policy_arn)}" => {
        role_key   = role_key
        policy_arn = policy_arn
      }
    }
  ]...)
}
