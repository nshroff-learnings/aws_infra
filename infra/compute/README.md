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

Before planning compute, the `networking` and `iam` layers must already be applied for the same Terraform workspace/environment.

This module reads upstream values from Terraform remote state instead of requiring copied IDs in `variables/<env>/eks.tfvars`:

- private subnet IDs from `infra/networking`
- EKS cluster role ARN from `infra/iam`
- EKS node role ARN from `infra/iam`

The workflow passes remote-state settings through environment variables:

```yaml
TF_VAR_tf_state_bucket: ${{ vars.TF_STATE_BUCKET }}
TF_VAR_tf_state_region: ${{ vars.TF_STATE_REGION || vars.AWS_REGION || 'us-east-1' }}
```

Local runs need the same variables:

```powershell
$env:TF_VAR_tf_state_bucket = "<state-bucket>"
$env:TF_VAR_tf_state_region = "<state-region>"
```

`eks.tfvars` can still override `cluster_role_arn`, `node_role_arn`, `subnet_ids`, or `principal_arn` explicitly, but normal environment files should omit them and use the remote-state defaults.
## Important Cluster Properties

| Property | Purpose |
| --- | --- |
| `eks_clusters` | Map of clusters keyed by logical name. Add a new map item for another cluster. |
| `name` | EKS cluster name. Keep it deterministic and environment-specific. |
| `cluster_role_arn` | IAM role ARN assumed by the EKS control plane. Defaults from IAM remote state when omitted. |
| `kubernetes_version` | Optional Kubernetes version. Defaults to a currently supported EKS version; pin intentionally and plan upgrades. |
| `subnet_ids` | Subnets used by the EKS control plane. Defaults from networking remote state when omitted. |
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
| `node_role_arn` | IAM role ARN assumed by worker nodes. Defaults from IAM remote state when omitted. |
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
