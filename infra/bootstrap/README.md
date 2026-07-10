# Bootstrap

This Terraform root module bootstraps the platform control plane after EKS exists.

It installs Argo CD into the platform EKS cluster and creates the root Argo CD `Application` that points to the separate platform repository.

## What It Creates

- `argocd` namespace.
- Argo CD Helm release.
- Root Argo CD Application, usually named `platform-root`.

The root app points to `argocd/apps` in the platform repo. Those child applications install Crossplane and sync the platform API.

## Required Inputs

```hcl
platform_repo_url      = "https://github.com/<org>/<platform-repo>.git"
platform_repo_revision = "main"
platform_root_app_path = "argocd/apps"
```

## Important Network Requirement

The Terraform runner must reach the platform EKS API endpoint.

If the platform EKS cluster has `endpoint_public_access = false`, GitHub-hosted runners cannot reach it. Use one of these patterns:

- Self-hosted GitHub runner inside the VPC or connected network.
- Public EKS endpoint with tightly restricted CIDRs.
- A private CI runner in AWS.

## Commands

```powershell
terraform -chdir=infra/bootstrap init `
  -backend-config="bucket=<state-bucket>" `
  -backend-config="region=<state-region>"

terraform -chdir=infra/bootstrap workspace select dev

terraform -chdir=infra/bootstrap plan `
  -var-file=../../variables/dev/common.tfvars `
  -var-file=../../variables/dev/bootstrap.tfvars
```

Do not run this module before `infra/compute` has created the platform EKS cluster and its node group.

