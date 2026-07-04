---
agent: 'agent'
description: 'Create a GitHub Actions Terraform deployment pipeline'
---

Create or update a GitHub Actions pipeline for: ${input:scope:Describe envs and components}

Requirements:
- Use OIDC role assumption, not static AWS keys.
- Separate fmt, validate, security scan, plan, and gated apply jobs.
- Use least repository permissions, concurrency per environment/stack, and protected GitHub Environments for apply.
- Run from changed root modules where practical.
- Upload safe plan artifacts only; avoid secrets.
- Apply only from protected branches/tags after successful validation and approval.
- Document required repository variables/secrets and AWS IAM role assumptions.
