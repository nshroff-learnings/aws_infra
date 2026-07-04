---
name: terraform-aws-infra
description: Generate, review, secure, and maintain Terraform AWS infrastructure in this repository, including shared module usage, security review, code review, recommendation implementation, and GitHub Actions deployment pipelines.
---

# Terraform AWS Infra

Read `AGENTS.md`, `docs/ai/terraform-standards.md`, and `docs/ai/module-catalog.md` before changing Terraform or CI/CD.

Use root modules under `infra/<domain>/<component>/`. Use `variables/<env>/common.tfvars` plus `variables/<env>/<component>.tfvars` for non-secret environment inputs.

Use shared modules from `git::https://github.com/nshroff-learnings/aws_modules.git//modules/<module>?ref=<tag-or-sha>`. Pin refs, inspect upstream module docs, and do not invent inputs or outputs.

For reviews, report findings first by severity with file/line references when possible. For implementation, preserve unrelated changes, keep patches small, run `terraform fmt -recursive`, and validate changed root modules when dependencies are available.

Never run apply, destroy, or state mutation commands unless explicitly requested.
