resource "aws_eks_cluster" "this" {
  for_each = var.eks_clusters

  name     = each.value.name
  role_arn = each.value.cluster_role_arn
  version  = each.value.kubernetes_version

  vpc_config {
    subnet_ids              = each.value.subnet_ids
    endpoint_private_access = each.value.endpoint_private_access
    endpoint_public_access  = each.value.endpoint_public_access
    public_access_cidrs     = each.value.public_access_cidrs
    security_group_ids      = each.value.security_group_ids
  }

  enabled_cluster_log_types = each.value.enabled_cluster_log_types

  dynamic "encryption_config" {
    for_each = each.value.kms_key_arn == null ? [] : [each.value.kms_key_arn]

    content {
      provider {
        key_arn = encryption_config.value
      }
      resources = ["secrets"]
    }
  }

  access_config {
    authentication_mode                         = each.value.authentication_mode
    bootstrap_cluster_creator_admin_permissions = each.value.bootstrap_cluster_creator_admin_permissions
  }

  tags = merge(local.tags, each.value.tags)
}

resource "aws_eks_node_group" "this" {
  for_each = local.eks_node_groups

  cluster_name    = aws_eks_cluster.this[each.value.cluster_key].name
  node_group_name = each.value.name
  node_role_arn   = each.value.node_role_arn
  subnet_ids      = each.value.subnet_ids
  version         = each.value.kubernetes_version
  ami_type        = each.value.ami_type
  capacity_type   = each.value.capacity_type
  disk_size       = each.value.disk_size
  instance_types  = each.value.instance_types

  scaling_config {
    desired_size = each.value.desired_size
    max_size     = each.value.max_size
    min_size     = each.value.min_size
  }

  update_config {
    max_unavailable = each.value.max_unavailable
  }

  labels = each.value.labels

  dynamic "taint" {
    for_each = each.value.taints

    content {
      key    = taint.value.key
      value  = taint.value.value
      effect = taint.value.effect
    }
  }

  tags = merge(local.tags, each.value.tags)

  depends_on = [aws_eks_cluster.this]
}

resource "aws_eks_access_entry" "this" {
  for_each = local.eks_access_entries

  cluster_name  = aws_eks_cluster.this[each.value.cluster_key].name
  principal_arn = each.value.principal_arn
  type          = each.value.type

  tags = local.tags
}

resource "aws_eks_access_policy_association" "this" {
  for_each = local.eks_access_policy_associations

  cluster_name  = aws_eks_cluster.this[each.value.cluster_key].name
  principal_arn = each.value.principal_arn
  policy_arn    = each.value.policy_arn

  access_scope {
    type       = each.value.access_scope_type
    namespaces = each.value.access_scope_type == "namespace" ? each.value.namespaces : null
  }

  depends_on = [aws_eks_access_entry.this]
}
