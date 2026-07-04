# Config

This root module creates shared configuration resources:

- ECR repositories through the shared `ecr-repository` module.
- AWS Secrets Manager secret metadata.

Secret values are intentionally not managed by Terraform in this module. Store secret values through a secure operational process, CI secret injection, or a dedicated secret management workflow.

Run Terraform from this directory with:

```powershell
terraform -chdir=infra/config init `
  -backend-config="bucket=<state-bucket>" `
  -backend-config="region=<state-region>"

terraform -chdir=infra/config workspace select dev

terraform -chdir=infra/config plan `
  -var-file=../../variables/dev/common.tfvars `
  -var-file=../../variables/dev/config.tfvars
```

## Important Properties

| Property | Purpose |
| --- | --- |
| `ecr_repositories` | Map of ECR repositories to create. Add a new map item for another repository. |
| `repository_suffix` | Suffix used with `project_name` and `environment` when `repository_name` is not supplied. |
| `repository_name` | Optional explicit ECR repository name. |
| `image_tag_mutability` | Use `IMMUTABLE` for safer deployments because existing tags cannot be overwritten. |
| `scan_on_push` | Enables basic ECR image scanning when images are pushed. |
| `kms_key_arn` | Optional KMS key for repository encryption. Defaults to AES256 when omitted. |
| `force_delete` | Whether Terraform can delete repositories containing images. Keep false for safer environments. |
| `create_lifecycle_policy` | Creates lifecycle rules to clean up old images. |
| `secrets` | Map of Secrets Manager secret metadata. Values are not stored by this module. |
| `recovery_window_in_days` | Waiting period before a deleted secret is permanently removed. |

## Sample ECR Values

```hcl
ecr_repositories = {
  app = {
    repository_suffix              = "app"
    image_tag_mutability           = "IMMUTABLE"
    scan_on_push                   = true
    force_delete                   = false
    create_lifecycle_policy        = true
    untagged_image_expiration_days = 7
    max_tagged_image_count         = 20
    lifecycle_tag_prefixes         = ["v", "release", "main", "dev"]
  }

  worker = {
    repository_suffix              = "worker"
    image_tag_mutability           = "IMMUTABLE"
    scan_on_push                   = true
    force_delete                   = false
    create_lifecycle_policy        = true
    untagged_image_expiration_days = 14
    max_tagged_image_count         = 30
  }
}
```

## Sample Secrets Manager Values

```hcl
secrets = {
  app_config = {
    name                    = "aws-infra/dev/app/config"
    description             = "Application configuration secret metadata for dev."
    recovery_window_in_days = 7
    tags = {
      Component = "app"
    }
  }
}
```

Do not put secret values in committed tfvars. Use AWS Secrets Manager APIs, CI/CD protected secrets, or a controlled break-glass process to populate values.

## Outputs

- `ecr_repositories`: repository name, ARN, and URL keyed by logical name.
- `secret_arns`: Secrets Manager secret ARNs keyed by logical name.
