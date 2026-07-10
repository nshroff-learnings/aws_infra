locals {
  name_prefix = "${var.project_name}-${var.environment}"
  tags        = merge(var.common_tags, var.tags)

  subnet_cidrs_by_key = merge(
    { for idx, cidr in var.private_subnet_cidrs : format("private-%02d", idx + 1) => cidr },
    { for idx, cidr in var.public_subnet_cidrs : format("public-%02d", idx + 1) => cidr }
  )

  network_acls = {
    for name, acl in var.network_acls : name => merge(acl, {
      subnet_ids = distinct(flatten([
        for subnet_key in acl.subnet_keys : concat(
          try([module.vpc.private_subnet_ids[subnet_key]], []),
          try([module.vpc.public_subnet_ids[subnet_key]], [])
        )
      ]))
    })
  }

  network_acl_ingress_rules = length(var.network_acls) == 0 ? {} : merge(flatten([
    for acl_name, acl in var.network_acls : [
      for rule in acl.ingress_rules : length(rule.cidr_subnet_keys) > 0 ? {
        for idx, subnet_key in rule.cidr_subnet_keys : "${acl_name}-${rule.rule_no}-${subnet_key}" => merge(rule, {
          acl_name   = acl_name
          rule_no    = rule.rule_no + idx
          cidr_block = local.subnet_cidrs_by_key[subnet_key]
        })
        } : {
        "${acl_name}-${rule.rule_no}" = merge(rule, {
          acl_name = acl_name
        })
      }
    ]
  ])...)

  network_acl_egress_rules = length(var.network_acls) == 0 ? {} : merge(flatten([
    for acl_name, acl in var.network_acls : [
      for rule in acl.egress_rules : length(rule.cidr_subnet_keys) > 0 ? {
        for idx, subnet_key in rule.cidr_subnet_keys : "${acl_name}-${rule.rule_no}-${subnet_key}" => merge(rule, {
          acl_name   = acl_name
          rule_no    = rule.rule_no + idx
          cidr_block = local.subnet_cidrs_by_key[subnet_key]
        })
        } : {
        "${acl_name}-${rule.rule_no}" = merge(rule, {
          acl_name = acl_name
        })
      }
    ]
  ])...)
}
