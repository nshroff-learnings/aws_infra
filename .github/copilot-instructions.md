# Copilot Instructions

This is a Terraform AWS infrastructure repository. Follow `AGENTS.md` first, then apply path-specific instructions from `.github/instructions/terraform.instructions.md` for Terraform files.

Use shared modules from `git::https://github.com/nshroff-learnings/aws_modules.git//modules/<module>?ref=<tag-or-sha>` after inspecting upstream docs/examples. Pin module refs and provider versions. Do not invent module inputs.

Default to secure AWS choices: no hardcoded secrets, no public S3, no broad IAM, no public ingress unless justified, encryption/logging enabled where supported, and OIDC for GitHub Actions.

Validate Terraform edits with `terraform fmt -recursive`; use `terraform init -backend=false` and `terraform validate` per changed root module when dependencies are available. Never run apply, destroy, or state mutation commands unless the user explicitly asks.
