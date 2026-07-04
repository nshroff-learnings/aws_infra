# aws_infra

Terraform workspace for AWS infrastructure deployments using reusable modules from `https://github.com/nshroff-learnings/aws_modules`.

## AI Setup

- `AGENTS.md`: shared repository guidance for Codex, Copilot agents, and other agents.
- `.agents/skills/terraform-aws-infra`: Codex repo-scoped skill for Terraform generation, review, security, and CI/CD workflows.
- `.codex/agents`: Codex project custom agents.
- `docs/codex-prompts`: Codex prompt snippets.
- `docs/ai`: shared standards and module catalog used by both Codex and Copilot.
- `.github/copilot-instructions.md`: repository-wide Copilot instructions.
- `.github/instructions`: path-specific Copilot instructions.
- `.github/prompts`: Copilot slash-command prompt files.
- `.github/agents`: Copilot custom agents.

## Terraform Defaults

Create deployable root modules under `infra/<domain>/<component>/`. Keep non-secret environment values in `variables/<env>/common.tfvars` plus `variables/<env>/<component>.tfvars`. Pin module sources with immutable refs and validate changes with `terraform fmt -recursive`, `terraform init -backend=false`, and `terraform validate` when dependencies are accessible.
