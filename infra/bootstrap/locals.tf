locals {
  tags = merge(
    var.common_tags,
    var.tags,
    {
      Environment = var.environment
      Project     = var.project_name
      Component   = "bootstrap"
      ManagedBy   = "terraform"
    }
  )

  platform_cluster_name = var.platform_cluster_name != null ? var.platform_cluster_name : data.terraform_remote_state.compute.outputs.eks_clusters[var.platform_cluster_key].name

  argocd_values = {
    configs = {
      cm = {
        "application.resourceTrackingMethod" = "annotation"
        "resource.customizations"            = <<-LUA
          "*.crossplane.io/*":
            health.lua: |
              health_status = { status = "Progressing", message = "Provisioning ..." }
              local has_no_status = {
                Composition = true,
                CompositionRevision = true,
                DeploymentRuntimeConfig = true,
                ProviderConfig = true,
                ProviderConfigUsage = true
              }
              if obj.status == nil or next(obj.status) == nil then
                if has_no_status[obj.kind] then
                  return { status = "Healthy", message = "Resource is up-to-date." }
                end
                return health_status
              end
              if obj.status.conditions == nil then
                return health_status
              end
              for _, condition in ipairs(obj.status.conditions) do
                if condition.type == "Ready" and condition.status == "True" then
                  return { status = "Healthy", message = "Resource is ready." }
                end
                if condition.type == "Synced" and condition.status == "False" then
                  return { status = "Degraded", message = condition.message }
                end
              end
              return health_status
        LUA
      }
    }
    server = {
      replicas = var.argocd_replicas
    }
    repoServer = {
      replicas = var.argocd_replicas
    }
    applicationSet = {
      replicas = var.argocd_replicas
    }
    controller = {
      replicas = 1
    }
  }
}

