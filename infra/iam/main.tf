data "aws_caller_identity" "current" {}

module "iam_roles" {
  for_each = var.iam_roles

  source = "git::https://github.com/nshroff-learnings/aws_modules.git//modules/iam-role?ref=16a80d96f53a968f26946f80cdd37acc9a46eb40"

  name_prefix                    = var.project_name
  environment                    = var.environment
  role_suffix                    = each.value.role_suffix
  role_name                      = each.value.role_name
  description                    = each.value.description
  path                           = each.value.path
  trusted_services               = each.value.trusted_services
  trusted_aws_principals         = each.value.trusted_aws_principals
  trusted_federated_principals   = each.value.trusted_federated_principals
  federated_conditions           = each.value.federated_conditions
  custom_assume_role_policy_json = each.value.custom_assume_role_policy_json
  managed_policy_arns            = each.value.managed_policy_arns
  inline_policies                = each.value.inline_policies
  permissions_boundary_arn       = each.value.permissions_boundary_arn
  max_session_duration           = each.value.max_session_duration
  force_detach_policies          = each.value.force_detach_policies
  create_instance_profile        = each.value.create_instance_profile
  instance_profile_name          = each.value.instance_profile_name
  tags                           = merge(local.tags, each.value.tags)
}

resource "aws_iam_role" "eks" {
  for_each = var.eks_roles

  name                 = each.value.role_name
  description          = each.value.description
  assume_role_policy   = data.aws_iam_policy_document.eks_assume_role[each.key].json
  permissions_boundary = each.value.permissions_boundary_arn

  tags = merge(local.tags, each.value.tags)
}

data "aws_iam_policy_document" "eks_assume_role" {
  for_each = var.eks_roles

  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = each.value.trusted_services
    }
  }
}

resource "aws_iam_role_policy_attachment" "eks_managed" {
  for_each = local.eks_managed_policy_attachments

  role       = aws_iam_role.eks[each.value.role_key].name
  policy_arn = each.value.policy_arn
}

resource "aws_iam_policy" "custom" {
  for_each = var.custom_policies

  name        = each.value.name
  description = each.value.description
  policy      = each.value.policy_json
  path        = each.value.path

  tags = merge(local.tags, each.value.tags)
}

data "aws_iam_group" "eks_admin_access" {
  for_each = var.eks_admin_access_roles

  group_name = each.value.group_name
}

data "aws_iam_policy_document" "eks_admin_access_assume_role" {
  for_each = var.eks_admin_access_roles

  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"]
    }
  }
}

resource "aws_iam_role" "eks_admin_access" {
  for_each = var.eks_admin_access_roles

  name                 = each.value.role_name
  description          = each.value.description
  assume_role_policy   = data.aws_iam_policy_document.eks_admin_access_assume_role[each.key].json
  max_session_duration = each.value.max_session_duration

  tags = merge(local.tags, each.value.tags)
}

data "aws_iam_policy_document" "eks_admin_access_group_assume_role" {
  for_each = var.eks_admin_access_roles

  statement {
    effect    = "Allow"
    actions   = ["sts:AssumeRole"]
    resources = [aws_iam_role.eks_admin_access[each.key].arn]
  }
}

resource "aws_iam_group_policy" "eks_admin_access_assume_role" {
  for_each = var.eks_admin_access_roles

  name   = "${each.value.role_name}-assume-role"
  group  = data.aws_iam_group.eks_admin_access[each.key].group_name
  policy = data.aws_iam_policy_document.eks_admin_access_group_assume_role[each.key].json
}
