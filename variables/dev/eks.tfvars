eks_clusters = {
  primary = {
    name               = "aws-infra-dev-primary"
    kubernetes_version = "1.34"

    endpoint_private_access   = true
    endpoint_public_access    = true
    public_access_cidrs       = ["0.0.0.0/0"]
    enabled_cluster_log_types = ["api", "audit", "authenticator", "controllerManager", "scheduler"]

    access_entries = {
      github_actions_bootstrap = {
        policy_associations = {
          cluster_admin = {
            policy_arn        = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"
            access_scope_type = "cluster"
          }
        }
      }

      aws_admins = {
        principal_role_name = "aws-infra-dev-eks-admin"

        policy_associations = {
          cluster_admin = {
            policy_arn        = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"
            access_scope_type = "cluster"
          }
        }
      }
    }

    node_groups = {
      system = {
        name            = "system"
        instance_types  = ["t3.medium"]
        ami_type        = "AL2023_x86_64_STANDARD"
        desired_size    = 2
        min_size        = 2
        max_size        = 4
        max_unavailable = 1
        labels = {
          workload = "system"
        }
      }
    }
  }
}





