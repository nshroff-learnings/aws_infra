# IAM

This root module creates IAM resources:

- Generic IAM roles through the shared `iam-role` module.
- EKS cluster and node roles.
- Customer-managed IAM policies.
- Managed policy attachments for EKS roles.

Run Terraform from this directory with:

```powershell
terraform -chdir=infra/iam init `
  -backend-config="bucket=<state-bucket>" `
  -backend-config="region=<state-region>"

terraform -chdir=infra/iam workspace select dev

terraform -chdir=infra/iam plan `
  -var-file=../../variables/dev/common.tfvars `
  -var-file=../../variables/dev/iam.tfvars
```

## Important Properties

| Property | Purpose |
| --- | --- |
| `iam_roles` | Generic IAM roles managed by the shared IAM module. Use for application, service, or federated roles. |
| `eks_roles` | EKS-specific service roles. Use this for cluster role and managed node group role. |
| `custom_policies` | Customer-managed IAM policies. Use when AWS-managed policies are too broad or not specific enough. |
| `trusted_services` | AWS service principals allowed to assume the role, such as `eks.amazonaws.com` or `ec2.amazonaws.com`. |
| `managed_policy_arns` | AWS-managed or customer-managed policies attached to the role. Keep this least privilege. |
| `inline_policies` | Inline policies for generic IAM roles. Keep these small and scoped. |
| `permissions_boundary_arn` | Optional boundary to cap maximum role permissions. Useful in enterprise environments. |

## Sample EKS Role Values

```hcl
eks_roles = {
  cluster = {
    role_name        = "aws-infra-dev-eks-cluster-role"
    description      = "EKS cluster service role for dev."
    trusted_services = ["eks.amazonaws.com"]
    managed_policy_arns = [
      "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
    ]
  }

  node = {
    role_name        = "aws-infra-dev-eks-node-role"
    description      = "EKS managed node group role for dev."
    trusted_services = ["ec2.amazonaws.com"]
    managed_policy_arns = [
      "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy",
      "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy",
      "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
    ]
  }
}
```

## Sample Generic Role

```hcl
iam_roles = {
  app_readonly = {
    role_name        = "aws-infra-dev-app-readonly"
    description      = "Example application read-only role."
    trusted_services = ["ec2.amazonaws.com"]
    managed_policy_arns = [
      "arn:aws:iam::aws:policy/ReadOnlyAccess"
    ]
    tags = {
      Component = "app"
    }
  }
}
```

## Sample Custom Policy

```hcl
custom_policies = {
  describe_ecr = {
    name        = "aws-infra-dev-describe-ecr"
    description = "Allow read-only ECR discovery."
    policy_json = jsonencode({
      Version = "2012-10-17"
      Statement = [
        {
          Sid    = "AllowDescribeEcr"
          Effect = "Allow"
          Action = [
            "ecr:DescribeRepositories",
            "ecr:DescribeImages"
          ]
          Resource = "*"
        }
      ]
    })
  }
}
```

`Resource = "*"` is sometimes required for read-only discovery APIs, but avoid broad write permissions.

## Outputs Used By Other Layers

- `eks_roles.cluster.arn`
- `eks_roles.node.arn`
- `iam_roles`
- `custom_policy_arns`

`infra/compute` needs the EKS cluster role ARN and node role ARN before EKS can be planned.
