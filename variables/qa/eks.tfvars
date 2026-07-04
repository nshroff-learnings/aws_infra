eks_clusters = {
  primary = {
    name               = "aws-infra-qa-primary"
    cluster_role_arn   = "REPLACE_WITH_INFRA_IAM_OUTPUT_EKS_CLUSTER_ROLE_ARN"
    kubernetes_version = "1.34"
    subnet_ids = [
      "REPLACE_WITH_INFRA_NETWORKING_OUTPUT_PRIVATE_SUBNET_ID_A",
      "REPLACE_WITH_INFRA_NETWORKING_OUTPUT_PRIVATE_SUBNET_ID_B"
    ]
    endpoint_private_access   = true
    endpoint_public_access    = false
    enabled_cluster_log_types = ["api", "audit", "authenticator", "controllerManager", "scheduler"]

    access_entries = {
      github_actions_bootstrap = {
        principal_arn = "REPLACE_WITH_GITHUB_ACTIONS_AWS_ROLE_ARN"
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
        name          = "system"
        node_role_arn = "REPLACE_WITH_INFRA_IAM_OUTPUT_EKS_NODE_ROLE_ARN"
        subnet_ids = [
          "REPLACE_WITH_INFRA_NETWORKING_OUTPUT_PRIVATE_SUBNET_ID_A",
          "REPLACE_WITH_INFRA_NETWORKING_OUTPUT_PRIVATE_SUBNET_ID_B"
        ]
        instance_types  = ["t3.medium"]
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
