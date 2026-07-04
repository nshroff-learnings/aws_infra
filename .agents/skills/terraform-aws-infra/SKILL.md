---
name: terraform-aws-infra
description: Generate, review, secure, and maintain Terraform for AWS infrastructure in this repository. Use for Terraform files, environment stacks, GitHub Actions deployment pipelines, module consumption from nshroff-learnings/aws_modules, security reviews, code reviews, and implementation of review recommendations.
---

# Terraform AWS Infra

## Workflow

1. Read `AGENTS.md` first for repository-wide rules.
2. Read `docs/ai/terraform-standards.md` before changing Terraform, CI, or security policy.
3. Read `docs/ai/module-catalog.md` before using shared modules.
4. Inspect the target environment and the upstream module README/examples before adding module calls.
5. Prefer small, reviewable changes. Do not introduce live AWS changes unless the user explicitly asks.
6. Validate with `terraform fmt -recursive`; use `terraform init -backend=false` and `terraform validate` when the needed providers/modules are accessible.

## Scope

- Create or update Terraform root modules under `infra/<domain>/<component>/`.
- Maintain non-secret environment inputs under `variables/<env>/common.tfvars` and `variables/<env>/<component>.tfvars`.
- Consume modules from `git::https://github.com/nshroff-learnings/aws_modules.git//modules/<module>?ref=<tag-or-sha>`.
- Review Terraform for correctness, maintainability, drift risk, and secure defaults.
- Create GitHub Actions workflows for plan/apply with OIDC, environment protection, concurrency, and least privilege.
- Implement recommendations from review prompts while preserving unrelated user changes.

## Output Rules

- Show file paths and commands plainly.
- Flag any assumption that requires the user's AWS account, backend, region, or module version.
- Never invent module inputs or outputs. If the upstream module cannot be inspected, add a TODO and stop at a safe scaffold.
