locals {
  tags = merge(var.common_tags, var.tags)

  upstream_private_subnet_ids = data.terraform_remote_state.networking.outputs.private_subnet_ids
  upstream_public_subnet_ids  = data.terraform_remote_state.networking.outputs.public_subnet_ids
  upstream_subnet_ids         = merge(local.upstream_private_subnet_ids, local.upstream_public_subnet_ids)
  upstream_eks_roles          = data.terraform_remote_state.iam.outputs.eks_roles

  eks_clusters = {
    for cluster_key, cluster in var.eks_clusters : cluster_key => merge(cluster, {
      cluster_role_arn = cluster.cluster_role_arn != null ? cluster.cluster_role_arn : local.upstream_eks_roles[cluster.cluster_role_key].arn
      subnet_ids = cluster.subnet_ids != null ? cluster.subnet_ids : [
        for subnet_key in cluster.subnet_keys : local.upstream_subnet_ids[subnet_key]
      ]
      access_entries = {
        for entry_key, entry in cluster.access_entries : entry_key => merge(entry, {
          principal_arn = entry.principal_arn != null ? entry.principal_arn : (
            entry.principal_role_name != null ? "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/${entry.principal_role_name}" : (
              try(entry.principal_role_name_regex, null) != null ? one(data.aws_iam_roles.eks_access["${cluster_key}-${entry_key}"].arns) : data.aws_iam_role.github_actions.arn
            )
          )
        })
      }
      node_groups = {
        for node_group_key, node_group in cluster.node_groups : node_group_key => merge(node_group, {
          node_role_arn = node_group.node_role_arn != null ? node_group.node_role_arn : local.upstream_eks_roles[node_group.node_role_key].arn
          subnet_ids = node_group.subnet_ids != null ? node_group.subnet_ids : [
            for subnet_key in node_group.subnet_keys : local.upstream_subnet_ids[subnet_key]
          ]
        })
      }
    })
  }

  eks_node_groups = length(local.eks_clusters) == 0 ? {} : merge([
    for cluster_key, cluster in local.eks_clusters : {
      for node_group_key, node_group in cluster.node_groups : "${cluster_key}-${node_group_key}" => merge(node_group, {
        cluster_key    = cluster_key
        node_group_key = node_group_key
      })
    }
  ]...)

  eks_access_entries = length(local.eks_clusters) == 0 ? {} : merge([
    for cluster_key, cluster in local.eks_clusters : {
      for entry_key, entry in cluster.access_entries : "${cluster_key}-${entry_key}" => merge(entry, {
        cluster_key = cluster_key
        entry_key   = entry_key
      })
    }
  ]...)

  eks_access_policy_associations = length(local.eks_access_entries) == 0 ? {} : merge([
    for access_entry_key, access_entry in local.eks_access_entries : {
      for policy_key, policy in access_entry.policy_associations : "${access_entry_key}-${policy_key}" => merge(policy, {
        access_entry_key = access_entry_key
        cluster_key      = access_entry.cluster_key
        principal_arn    = access_entry.principal_arn
      })
    }
  ]...)
}




