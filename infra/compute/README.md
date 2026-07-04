# Compute

This root module creates EKS compute resources:

- EKS clusters.
- EKS managed node groups.
- EKS access entries and access policy associations.

The shared modules repository does not currently include an EKS module, so this root module creates EKS resources directly.

Run Terraform from this directory with:

```powershell
terraform -chdir=infra/compute init `
  -backend-config="bucket=<state-bucket>" `
  -backend-config="region=<state-region>"

terraform -chdir=infra/compute workspace select dev

terraform -chdir=infra/compute plan `
  -var-file=../../variables/dev/common.tfvars `
  -var-file=../../variables/dev/eks.tfvars
```

## Dependency Requirements

Before planning compute, replace placeholders in `variables/<env>/eks.tfvars` with:

- private subnet IDs from `infra/networking`
- EKS cluster role ARN from `infra/iam`
- EKS node role ARN from `infra/iam`
- GitHub Actions IAM role ARN for bootstrap access, if the bootstrap layer will install Argo CD

Remote state can be added later after the S3 backend/account model is finalized.

## Important Cluster Properties

| Property | Purpose |
| --- | --- |
| `eks_clusters` | Map of clusters keyed by logical name. Add a new map item for another cluster. |
| `name` | EKS cluster name. Keep it deterministic and environment-specific. |
| `cluster_role_arn` | IAM role ARN assumed by the EKS control plane. |
| `kubernetes_version` | Optional Kubernetes version. Pin intentionally and plan upgrades. |
| `subnet_ids` | Subnets used by the EKS control plane. Prefer private subnets for private clusters. |
| `endpoint_private_access` | Enables private API endpoint access inside the VPC. |
| `endpoint_public_access` | Enables public API endpoint access. Defaults should remain false for private clusters. |
| `public_access_cidrs` | CIDRs allowed to reach public endpoint when public endpoint is enabled. |
| `enabled_cluster_log_types` | Control plane log types sent to CloudWatch. |
| `kms_key_arn` | Optional KMS key for Kubernetes secret encryption. |
| `authentication_mode` | EKS access mode. Defaults to `API_AND_CONFIG_MAP`. |
| `bootstrap_cluster_creator_admin_permissions` | Whether cluster creator gets admin permissions. Keep false unless intentionally needed. |
| `access_entries` | Map of IAM principals that should be granted Kubernetes API access through the EKS access API. |

## Important Node Group Properties

| Property | Purpose |
| --- | --- |
| `node_groups` | Map of managed node groups under each cluster. |
| `node_role_arn` | IAM role ARN assumed by worker nodes. |
| `subnet_ids` | Subnets used by nodes. Prefer private subnets. |
| `instance_types` | EC2 instance types for the node group. |
| `capacity_type` | `ON_DEMAND` or `SPOT`. Use spot only for interruption-tolerant workloads. |
| `desired_size`, `min_size`, `max_size` | Managed node group scaling boundaries. |
| `max_unavailable` | Number of nodes that can be unavailable during updates. |
| `labels` | Kubernetes labels applied to nodes. |
| `taints` | Kubernetes taints for workload isolation. |

## Sample EKS Values

```hcl
eks_clusters = {
  primary = {
    name               = "aws-infra-dev-primary"
    cluster_role_arn   = "arn:aws:iam::<account-id>:role/aws-infra-dev-eks-cluster-role"
    kubernetes_version = "1.29"
    subnet_ids = [
      "subnet-0123456789abcdef0",
      "subnet-0fedcba9876543210"
    ]
    endpoint_private_access   = true
    endpoint_public_access    = false
    enabled_cluster_log_types = ["api", "audit", "authenticator", "controllerManager", "scheduler"]

    access_entries = {
      github_actions_bootstrap = {
        principal_arn = "arn:aws:iam::<account-id>:role/<github-actions-role>"
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
        node_role_arn = "arn:aws:iam::<account-id>:role/aws-infra-dev-eks-node-role"
        subnet_ids = [
          "subnet-0123456789abcdef0",
          "subnet-0fedcba9876543210"
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

      apps = {
        name          = "apps"
        node_role_arn = "arn:aws:iam::<account-id>:role/aws-infra-dev-eks-node-role"
        subnet_ids = [
          "subnet-0123456789abcdef0",
          "subnet-0fedcba9876543210"
        ]
        instance_types  = ["t3.large"]
        desired_size    = 2
        min_size        = 1
        max_size        = 6
        max_unavailable = 1
        labels = {
          workload = "apps"
        }
      }
    }
  }
}
```

## Outputs

- `eks_clusters`: name, ARN, endpoint, and version keyed by cluster name.
- `eks_node_groups`: node group name, ARN, and status keyed by cluster-node-group name.
- `eks_access_entries`: EKS access entry details keyed by cluster-entry name.
