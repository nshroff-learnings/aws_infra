---
applyTo: "**/*.tf,**/*.tfvars,**/*.hcl"
---

Keep Terraform deployable root modules under `infra/<domain>/<component>/`.

Keep non-secret environment values under `variables/<env>/`: `common.tfvars` for shared environment values and `<component>.tfvars` for component-specific values.

Prefer remote modules from `nshroff-learnings/aws_modules`, pinned with `?ref=<tag-or-sha>`. Inspect module variables, outputs, and examples before use.

Use `versions.tf` for Terraform/provider constraints, `providers.tf` for AWS provider/default tags, `backend.tf` for remote state backend type/shared settings, `variables.tf` with validations, and `outputs.tf` with no secret outputs.

Backend blocks cannot use variables or template placeholders. Prefer workspaces for environment-specific S3 state paths when environments share a backend pattern, or CI-provided `-backend-config` when backend values differ by environment.

Security defaults: least-privilege IAM, private networking/storage by default, encryption enabled, logging/retention configured when supported, and no committed credentials or secret tfvars.

Validation: run `terraform fmt -recursive`; prefer `terraform init -backend=false` and `terraform validate` in each changed root module. Do not run apply/destroy unless explicitly requested.
