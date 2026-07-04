---
agent: 'agent'
description: 'Review Terraform changes for correctness and maintainability'
---

Review the Terraform change set: ${input:scope:Describe files, PR, or diff to review}

Use code-review style. Findings first, ordered by severity, with file/line references when possible.

Check:
- Module source pinning and correct module inputs/outputs.
- Terraform/provider version constraints and root module layout.
- Resource address stability, naming, tags, variable validation, outputs, and backend assumptions.
- Validation coverage: fmt, init, validate, lint/security scans.
- Risk of drift, replacement, downtime, or accidental deletion.

Do not rewrite code unless asked. Provide concise remediation steps.
