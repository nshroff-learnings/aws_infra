module "vpc" {
  source = "git::https://github.com/nshroff-learnings/aws_modules.git//modules/vpc?ref=16a80d96f53a968f26946f80cdd37acc9a46eb40"

  name_prefix             = var.project_name
  environment             = var.environment
  vpc_cidr                = var.vpc_cidr
  private_subnet_cidrs    = var.private_subnet_cidrs
  public_subnet_cidrs     = var.public_subnet_cidrs
  availability_zones      = var.availability_zones
  map_public_ip_on_launch = var.map_public_ip_on_launch
  tags                    = local.tags
}

resource "aws_network_acl" "this" {
  #checkov:skip=CKV2_AWS_1:Subnet associations are resolved from module output IDs; enforce non-empty associations with a Terraform precondition.
  for_each = local.network_acls

  vpc_id     = module.vpc.vpc_id
  subnet_ids = each.value.subnet_ids

  tags = merge(local.tags, {
    Name = "${local.name_prefix}-${each.key}-nacl"
  })

  lifecycle {
    precondition {
      condition     = length(each.value.subnet_ids) > 0
      error_message = "Each network ACL must resolve at least one subnet from subnet_keys."
    }
  }
}

resource "aws_network_acl_rule" "ingress" {
  for_each = local.network_acl_ingress_rules

  network_acl_id = aws_network_acl.this[each.value.acl_name].id
  egress         = false
  rule_number    = each.value.rule_no
  rule_action    = each.value.action
  protocol       = each.value.protocol
  cidr_block     = each.value.cidr_block
  from_port      = each.value.from_port
  to_port        = each.value.to_port
}

resource "aws_network_acl_rule" "egress" {
  for_each = local.network_acl_egress_rules

  network_acl_id = aws_network_acl.this[each.value.acl_name].id
  egress         = true
  rule_number    = each.value.rule_no
  rule_action    = each.value.action
  protocol       = each.value.protocol
  cidr_block     = each.value.cidr_block
  from_port      = each.value.from_port
  to_port        = each.value.to_port
}
