output "eks_clusters" {
  description = "EKS cluster details keyed by logical name."
  value = {
    for name, cluster in aws_eks_cluster.this : name => {
      name     = cluster.name
      arn      = cluster.arn
      endpoint = cluster.endpoint
      version  = cluster.version
    }
  }
}

output "eks_node_groups" {
  description = "EKS node group details keyed by cluster-node-group name."
  value = {
    for name, node_group in aws_eks_node_group.this : name => {
      name   = node_group.node_group_name
      arn    = node_group.arn
      status = node_group.status
    }
  }
}

output "eks_access_entries" {
  description = "EKS access entries keyed by cluster-entry name."
  value = {
    for name, entry in aws_eks_access_entry.this : name => {
      cluster_name  = entry.cluster_name
      principal_arn = entry.principal_arn
      type          = entry.type
    }
  }
}
