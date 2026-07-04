# Agent Instructions

This repository is for AWS infrastructure deployments with Terraform. Treat this file as the primary source of truth for Codex, Copilot agents, and other coding agents.

## Project Rules

- Keep deployable Terraform root modules under `infra/<domain>/<component>/`, for example `infra/networking` or `infra/compute/eks`.
- Keep environment-specific non-secret inputs under `variables/<env>/`, including `common.tfvars` plus component files such as `networking.tfvars` or `eks.tfvars`.
- Prefer shared modules from `git::https://github.com/nshroff-learnings/aws_modules.git//modules/<module>?ref=<tag-or-sha>`.
- Inspect the upstream module README, variables, outputs, and examples before adding or changing a module block.
- Pin module sources, Terraform versions, and provider versions for deployable stacks.
- Do not commit `.terraform/`, state files, plan files, crash logs, credentials, secrets, or local/secret tfvars.
- Only commit `variables/**/*.tfvars` when they contain non-secret values.
- Preserve unrelated user changes. Make small, reviewable patches.

## Terraform Standards

- Use `versions.tf`, `providers.tf`, `backend.tf`, `main.tf`, `variables.tf`, and `outputs.tf` in each `infra/<domain>/<component>` root module when those concerns exist.
- Use `backend.tf` for the backend type and shared backend settings. Use workspaces or CI-provided `-backend-config` values for environment-specific state paths.
- Use variable validation for constrained inputs.
- Mark sensitive variables and outputs with `sensitive = true`.
- Prefer deterministic names and common tags.
- Prefer `for_each` over `count` when resource identity should be stable.
- Do not invent module inputs or outputs. If upstream docs are unavailable, leave a TODO rather than guessing.

## Security Rules

- Never hardcode AWS keys, passwords, tokens, private keys, or personal credentials.
- Use GitHub Actions OIDC and IAM role assumption for CI/CD.
- Use least-privilege IAM; broad wildcard permissions require a clear justification.
- Default S3, networking, IAM, and logging decisions to private, encrypted, auditable settings.
- Treat public ingress, public buckets, disabled encryption, missing logging, and secret outputs as review findings.

## Validation

- Run `terraform fmt -recursive` after Terraform edits.
- For each changed root module, prefer `terraform init -backend=false` then `terraform validate`.
- For planning, load variables in order: `variables/<env>/common.tfvars`, then `variables/<env>/<component>.tfvars`.
- Run `tflint`, `checkov`, or `tfsec` when available.
- Do not run `terraform apply`, `destroy`, or state mutation commands unless the user explicitly asks.

## Prompt/Skill Hints

- For Codex, use `.agents/skills/terraform-aws-infra`, `.codex/agents`, and `docs/codex-prompts`.
- For Copilot, use `.github/copilot-instructions.md`, `.github/instructions`, `.github/prompts`, and `.github/agents`.
