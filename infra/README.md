# Infrastructure Layout

This repo uses separate Terraform root modules by concern:

- `infra/networking`: VPC, subnets, route tables from the shared VPC module, plus NACLs.
- `infra/iam`: generic IAM roles from the shared IAM module, EKS service roles, and custom policies.
- `infra/config`: ECR repositories from the shared ECR module and Secrets Manager metadata.
- `infra/compute`: EKS clusters and managed node groups.
- `infra/bootstrap`: Argo CD bootstrap on the platform EKS cluster.

## Environment Inputs

Load common values first, then component-specific values:

```powershell
terraform -chdir=infra/networking plan -var-file=../../variables/dev/common.tfvars -var-file=../../variables/dev/networking.tfvars
terraform -chdir=infra/iam plan -var-file=../../variables/dev/common.tfvars -var-file=../../variables/dev/iam.tfvars
terraform -chdir=infra/config plan -var-file=../../variables/dev/common.tfvars -var-file=../../variables/dev/config.tfvars
terraform -chdir=infra/compute plan -var-file=../../variables/dev/common.tfvars -var-file=../../variables/dev/eks.tfvars
terraform -chdir=infra/bootstrap plan -var-file=../../variables/dev/common.tfvars -var-file=../../variables/dev/bootstrap.tfvars
```

## Workspaces

Each root module has its own backend key and can use Terraform workspaces:

```powershell
terraform -chdir=infra/networking workspace new dev
terraform -chdir=infra/iam workspace new dev
terraform -chdir=infra/config workspace new dev
terraform -chdir=infra/compute workspace new dev
terraform -chdir=infra/bootstrap workspace new dev
```

Use `workspace select dev` after the workspace already exists.

## Backend

The `backend.tf` files intentionally omit environment-specific S3 backend values. Initialize with backend config values from CI or your local command:

```powershell
terraform -chdir=infra/networking init `
  -backend-config="bucket=<state-bucket>" `
  -backend-config="region=<state-region>"
```

The backend uses `workspace_key_prefix = "env"`, so the `dev` networking state path is:

```text
env/dev/networking/terraform.tfstate
```

## Dependency Order

Apply in this order:

1. `infra/networking`
2. `infra/iam`
3. `infra/config`
4. `infra/compute`
5. `infra/bootstrap`

Before planning `infra/compute`, replace placeholders in `variables/<env>/eks.tfvars` with:

- private subnet IDs from `infra/networking` outputs
- EKS cluster role ARN from `infra/iam` outputs
- EKS node role ARN from `infra/iam` outputs

Remote state data sources can be added later after the S3 backend bucket and account model are finalized.

Before planning `infra/bootstrap`, replace placeholders in `variables/<env>/bootstrap.tfvars` with the real platform repository URL. The runner must also reach the platform EKS API endpoint. For private-only EKS endpoints, use a self-hosted runner in the VPC or connected network.

## Adding More Resources

Most repeated resources are map-driven:

- Add another EKS cluster by adding another item to `eks_clusters`.
- Add another node group by adding another item under `eks_clusters.<name>.node_groups`.
- Add another ECR repository by adding another item to `ecr_repositories`.
- Add another IAM role by adding another item to `iam_roles` or `eks_roles`.
- Add another NACL by adding another item to `network_acls`.

## GitHub Actions

The workflow `.github/workflows/terraform-infra.yml` is explained in `.github/workflows/README.md`.

It has explicit jobs that map to stage-like units:

- `Networking Plan`
- `Networking Apply`
- `IAM Plan`
- `IAM Apply`
- `Config Plan`
- `Config Apply`
- `Compute Plan`
- `Compute Apply`
- `Bootstrap Plan`
- `Bootstrap Apply`

Manual runs support selecting `action=plan` or `action=apply`, plus `layers=all` or a comma-separated list such as `networking,iam,compute,bootstrap`.

Required GitHub repository variables:

- `AWS_ROLE_ARN`: IAM role assumed by GitHub Actions through OIDC.
- `AWS_REGION`: AWS region for Terraform and AWS API calls.
- `TF_STATE_BUCKET`: S3 bucket for Terraform state.
- `TF_STATE_REGION`: optional state bucket region. Defaults to `AWS_REGION` when omitted.

Use GitHub Environments named `dev` and `qa` for approval gates before apply. Keep the variables above at repository scope unless you also change the workflow to attach the plan jobs to environments.

The workflow uploads text plan summaries for review. It does not upload binary plan files because Terraform plans can contain sensitive values. Each apply job re-plans immediately before applying its layer.
