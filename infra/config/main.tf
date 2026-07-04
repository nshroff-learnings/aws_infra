module "ecr_repositories" {
  for_each = var.ecr_repositories

  source = "git::https://github.com/nshroff-learnings/aws_modules.git//modules/ecr-repository?ref=16a80d96f53a968f26946f80cdd37acc9a46eb40"

  name_prefix                    = var.project_name
  environment                    = var.environment
  repository_suffix              = each.value.repository_suffix
  repository_name                = each.value.repository_name
  image_tag_mutability           = each.value.image_tag_mutability
  scan_on_push                   = each.value.scan_on_push
  kms_key_arn                    = each.value.kms_key_arn
  force_delete                   = each.value.force_delete
  create_lifecycle_policy        = each.value.create_lifecycle_policy
  lifecycle_policy_json          = each.value.lifecycle_policy_json
  untagged_image_expiration_days = each.value.untagged_image_expiration_days
  max_tagged_image_count         = each.value.max_tagged_image_count
  lifecycle_tag_prefixes         = each.value.lifecycle_tag_prefixes
  repository_policy_json         = each.value.repository_policy_json
  tags                           = merge(local.tags, each.value.tags)
}

resource "aws_secretsmanager_secret" "this" {
  for_each = var.secrets

  name                    = each.value.name
  description             = each.value.description
  kms_key_id              = each.value.kms_key_id
  recovery_window_in_days = each.value.recovery_window_in_days

  tags = merge(local.tags, each.value.tags)
}
