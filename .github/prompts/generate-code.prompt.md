---
agent: 'agent'
description: 'Generate Terraform AWS infrastructure using repository standards'
---

Generate Terraform for: ${input:request:Describe the infrastructure change}

Follow `AGENTS.md`, `docs/ai/terraform-standards.md`, and `docs/ai/module-catalog.md`.

Requirements:
- Use `infra/<domain>/<component>/` unless the request gives another path.
- Put non-secret inputs in `variables/<env>/common.tfvars` and `variables/<env>/<component>.tfvars` when adding environment values.
- Prefer `nshroff-learnings/aws_modules` modules and pin module refs.
- Inspect upstream module docs/examples before writing module inputs.
- Include variables, validations, outputs, provider/version constraints, and safe examples as needed.
- Avoid secrets, broad IAM, public ingress/storage, and unpinned dependencies.
- State validation commands and any assumptions.
