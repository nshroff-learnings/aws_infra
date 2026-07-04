---
agent: 'agent'
description: 'Review Terraform AWS infrastructure for security risks'
---

Perform a Terraform/AWS security review for: ${input:scope:Describe files, PR, or diff to review}

Findings first, ordered by severity, with file/line references when possible.

Check:
- Hardcoded secrets, committed tfvars, secret outputs, and unsafe logs/artifacts.
- IAM wildcards, broad trust policies, privilege escalation, and missing condition keys.
- Public S3, public ingress, weak network boundaries, missing encryption, missing logging, and weak retention.
- GitHub Actions OIDC, permissions, environment gates, concurrency, and secret handling.
- State backend encryption/locking and plan artifact exposure.

Include concrete fixes and note any assumptions that need AWS account context.
