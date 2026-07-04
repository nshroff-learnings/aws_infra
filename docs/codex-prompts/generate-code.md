# Generate Terraform Code

Use `$terraform-aws-infra`.

Task: generate Terraform for the requested AWS infrastructure change.

Read `AGENTS.md`, `docs/ai/terraform-standards.md`, and `docs/ai/module-catalog.md`.

Deliver:
- Minimal files under `infra/<domain>/<component>/`.
- Non-secret environment inputs under `variables/<env>/common.tfvars` and `variables/<env>/<component>.tfvars`.
- Pinned module/provider versions.
- Secure defaults and variable validation.
- Validation commands run and assumptions.
