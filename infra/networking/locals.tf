locals {
  name_prefix = "${var.project_name}-${var.environment}"
  tags        = merge(var.common_tags, var.tags)

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

  network_acl_ingress_rules = length(var.network_acls) == 0 ? {} : merge([
    for acl_name, acl in var.network_acls : {
      for rule in acl.ingress_rules : "${acl_name}-${rule.rule_no}" => merge(rule, {
        acl_name = acl_name
      })
    }
  ]...)

  network_acl_egress_rules = length(var.network_acls) == 0 ? {} : merge([
    for acl_name, acl in var.network_acls : {
      for rule in acl.egress_rules : "${acl_name}-${rule.rule_no}" => merge(rule, {
        acl_name = acl_name
      })
    }
  ]...)
}
