---
agent: 'agent'
description: 'Implement approved Terraform review recommendations'
---

Implement these approved recommendations: ${input:recommendations:Paste review findings or a checklist}

Rules:
- Read `AGENTS.md` and the Terraform standards reference first.
- Change only files required by the recommendations.
- Preserve unrelated user changes.
- Prefer smallest safe patch.
- Run `terraform fmt -recursive` and relevant validation commands.
- Summarize implemented items, skipped items, assumptions, and validation results.
