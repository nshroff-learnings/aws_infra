# Terraform AWS Standards

## Repository Layout

- Put deployable root modules under `infra/<domain>/<component>/`, for example `infra/networking` or `infra/compute/eks`.
- Use `main.tf`, `variables.tf`, `outputs.tf`, `providers.tf`, `versions.tf`, and `backend.tf` when those concerns exist.
- Keep non-secret environment values in `variables/<env>/common.tfvars` and `variables/<env>/<component>.tfvars`.
- Never commit state, plans, credentials, secrets, generated provider caches, or local/secret tfvars.
- Commit `variables/**/*.tfvars` only when they contain non-secret values.
- Use `locals.tf` only when it improves readability for naming, tags, or derived values.
- Read `docs/ai/module-catalog.md` before using shared modules.

## Environment Inputs

- Use `variables/<env>/common.tfvars` for values shared by all components in an environment, such as `environment`, `project_name`, `aws_region`, and common tags.
- Use `variables/<env>/<component>.tfvars` for component-specific values, such as VPC CIDRs or EKS node sizing.
- Load variable files in order so component values can intentionally override common defaults.
- From `infra/networking`, use:
  `-var-file=../../variables/<env>/common.tfvars -var-file=../../variables/<env>/networking.tfvars`
- From `infra/compute/eks`, use:
  `-var-file=../../../variables/<env>/common.tfvars -var-file=../../../variables/<env>/eks.tfvars`
- Do not put secrets in committed tfvars. Use CI secrets, environment variables, a secret manager, or untracked local tfvars for sensitive values.
- Keep variable names consistent across root modules when they represent the same concept.

## Backend And Workspaces

- Each `infra/<domain>/<component>` root module may include `backend.tf`.
- Backend blocks cannot use Terraform variables or locals. Do not use `${var.environment}` or template placeholders in `backend.tf`.
- Prefer an S3 backend with a fixed component key and `workspace_key_prefix` when dev/qa/prod share the same backend bucket pattern.
- Use Terraform workspaces for environment state suffixes/prefixes when appropriate: `dev`, `qa`, `prod`.
- Use CI-provided `-backend-config` values instead of committed backend values when environments require different backend buckets, accounts, KMS keys, or role assumptions.

## Module Usage

- Prefer the shared modules repository:
  `git::https://github.com/nshroff-learnings/aws_modules.git//modules/<module>?ref=<tag-or-sha>`
- Pin each module to an immutable tag or commit SHA for deployable environments. Do not use a floating branch for production.
- Read the upstream module README, variables, outputs, and examples before writing a module block.
- Do not copy module internals into this repo unless explicitly requested.
- Pass only intentional inputs. Let module defaults stand when they are documented and secure.

## Terraform Style

- Pin Terraform and provider constraints in `versions.tf`.
- Configure AWS provider defaults, including common tags, in one provider block per root module.
- Prefer `for_each` over `count` for address stability when resources are keyed by names.
- Add variable `validation` blocks for constrained inputs such as environment, CIDR, retention days, and allowed tiers.
- Use `sensitive = true` on sensitive variables and outputs.
- Avoid unnecessary outputs. Do not output secrets, tokens, passwords, private keys, or full IAM policy documents unless required.
- Use clear names with stable prefixes: `<project>-<env>-<component>`.
- Keep generated names deterministic unless AWS requires uniqueness.

## Security Baseline

- Do not hardcode AWS access keys, account IDs unless intentional, passwords, tokens, or personal ARNs.
- Prefer GitHub Actions OIDC with IAM role assumption over long-lived AWS secrets.
- Use least-privilege IAM. Avoid `Action = "*"`, `Resource = "*"`, and broad trust policies unless justified in comments.
- Enable encryption at rest where supported and prefer AWS-managed or customer-managed KMS keys according to stack needs.
- Block public access for S3 by default; require explicit justification for public resources.
- Enable logs, retention, deletion protection, or backups for stateful and externally exposed services when supported.
- Treat security group ingress from `0.0.0.0/0` or `::/0` as a finding unless the port and use case are explicitly public.

## Validation

- Always run `terraform fmt -recursive` after Terraform edits.
- Prefer `terraform init -backend=false` before `terraform validate` for review-time validation.
- Run `terraform validate` from each changed root module after initialization.
- Run `tflint`, `checkov`, or `tfsec` when available; do not silently skip if the tool is missing.
- Do not run `terraform apply`, `destroy`, or state mutation commands unless the user explicitly asks.

## GitHub Actions Pipeline Pattern

- Use separate jobs for `fmt`, `validate`, `security-scan`, `plan`, and gated `apply`.
- Use `permissions: id-token: write` and `contents: read`; add broader permissions only when required.
- Configure AWS credentials via OIDC role assumption, not static keys.
- Use GitHub Environments for approval gates before apply.
- Use `concurrency` per environment/component to avoid overlapping applies.
- Upload plan artifacts for review, but never upload files containing secrets.
- Apply only from protected branches/tags and only after validation and plan succeed.
