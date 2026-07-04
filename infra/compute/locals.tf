locals {
  tags = merge(var.common_tags, var.tags)

  eks_node_groups = length(var.eks_clusters) == 0 ? {} : merge([
    for cluster_key, cluster in var.eks_clusters : {
      for node_group_key, node_group in cluster.node_groups : "${cluster_key}-${node_group_key}" => merge(node_group, {
        cluster_key    = cluster_key
        node_group_key = node_group_key
      })
    }
  ]...)

  eks_access_entries = length(var.eks_clusters) == 0 ? {} : merge([
    for cluster_key, cluster in var.eks_clusters : {
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
