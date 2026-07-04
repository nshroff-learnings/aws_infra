# AWS Console Setup for GitHub Actions Terraform Pipeline

This guide walks through the AWS Console and GitHub UI setup required before running `.github/workflows/terraform-infra.yml`.

Use this guide if you prefer the portal/console path instead of AWS CLI.

## Goal

Prepare AWS and GitHub so the Terraform workflow can provision infrastructure using GitHub Actions OIDC.

You need:

- Secure AWS root account access.
- Human admin access that is not root.
- S3 bucket for Terraform remote state.
- GitHub OIDC identity provider in AWS IAM.
- IAM role for GitHub Actions.
- IAM permissions for that role.
- GitHub repository variables.
- GitHub environments named `dev` and `qa`.
- First Terraform runs staged by layer.

## 1. Secure the AWS Root User

AWS Console:

```text
Sign in as root -> Account menu -> Security credentials
```

Do this first:

- Enable MFA on the root user.
- Do not create root access keys.
- Add alternate contacts for billing, operations, and security.
- Store root credentials securely.

After this, root should be used only for emergency/account-level tasks.

## 2. Create Human Admin Access

Do not use root for normal console or CLI work.

### Preferred: IAM Identity Center

If IAM Identity Center is available in your account:

```text
AWS Console -> IAM Identity Center -> Enable
```

Create groups:

```text
AWS-ReadOnly
AWS-Admins
AWS-Billing
```

Create permission sets:

```text
ReadOnlyAccess
AdministratorAccess
BillingAccess
```

Attach AWS managed policies:

```text
ReadOnlyAccess -> ReadOnlyAccess
AdministratorAccess -> AdministratorAccess
BillingAccess -> job-function/Billing
```

Set `AdministratorAccess` session duration short:

```text
1 hour or 2 hours
```

Assign yourself:

```text
AWS-ReadOnly -> ReadOnlyAccess
AWS-Admins -> AdministratorAccess
```

This is the closest basic AWS pattern to Azure users having read access by default and elevating only when needed. For a stricter Azure PIM-like model, use Microsoft Entra ID PIM to control group membership and federate Entra ID into IAM Identity Center.

### Fallback: IAM User for Learning Account

If IAM Identity Center is not available, use an IAM admin user temporarily.

AWS Console:

```text
IAM -> User groups -> Create group
```

Create:

```text
AWS-Admins
```

Attach:

```text
AdministratorAccess
```

Then:

```text
IAM -> Users -> Create user
```

Create your user and add it to `AWS-Admins`.

Then:

```text
IAM -> Users -> your user -> Security credentials
```

Enable MFA for the IAM user.

Use this IAM user for setup. Do not create root access keys.

## 3. Create the Terraform State S3 Bucket

AWS Console:

```text
S3 -> Buckets -> Create bucket
```

Example bucket name:

```text
aws-infra-<account-id>-tfstate-us-east-1
```

Use a globally unique name.

Recommended settings:

```text
Region: us-east-1
Object Ownership: ACLs disabled
Block all public access: enabled
Bucket Versioning: enabled
Default encryption: SSE-S3 / AES-256
Bucket Key: enabled if shown
```

After creating the bucket, open it:

```text
Permissions -> Bucket policy
```

Add an HTTPS-only deny policy:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "DenyInsecureTransport",
      "Effect": "Deny",
      "Principal": "*",
      "Action": "s3:*",
      "Resource": [
        "arn:aws:s3:::YOUR_BUCKET_NAME",
        "arn:aws:s3:::YOUR_BUCKET_NAME/*"
      ],
      "Condition": {
        "Bool": {
          "aws:SecureTransport": "false"
        }
      }
    }
  ]
}
```

Replace `YOUR_BUCKET_NAME` with your actual bucket name.

The Terraform backend in this repo uses S3 keys like:

```text
networking/terraform.tfstate
iam/terraform.tfstate
config/terraform.tfstate
compute/terraform.tfstate
bootstrap/terraform.tfstate
```

With Terraform workspaces, dev state paths become:

```text
env/dev/networking/terraform.tfstate
env/dev/iam/terraform.tfstate
env/dev/config/terraform.tfstate
env/dev/compute/terraform.tfstate
env/dev/bootstrap/terraform.tfstate
```

## 4. Create GitHub OIDC Provider in AWS

AWS Console:

```text
IAM -> Identity providers -> Add provider
```

Choose:

```text
Provider type: OpenID Connect
Provider URL: https://token.actions.githubusercontent.com
Audience: sts.amazonaws.com
```

Create the provider.

This lets GitHub Actions authenticate to AWS without storing AWS access keys in GitHub.

## 5. Create IAM Role for GitHub Actions

AWS Console:

```text
IAM -> Roles -> Create role
```

Choose:

```text
Trusted entity type: Web identity
Identity provider: token.actions.githubusercontent.com
Audience: sts.amazonaws.com
```

If the console asks for GitHub details:

```text
GitHub organization: <your-github-owner-or-org>
GitHub repository: aws_infra
Branch: main
```

Use role name:

```text
aws-infra-github-actions
```

Create the role.

Then open the role:

```text
Trust relationships -> Edit trust policy
```

Use this trust policy:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Federated": "arn:aws:iam::<account-id>:oidc-provider/token.actions.githubusercontent.com"
      },
      "Action": "sts:AssumeRoleWithWebIdentity",
      "Condition": {
        "StringEquals": {
          "token.actions.githubusercontent.com:aud": "sts.amazonaws.com"
        },
        "StringLike": {
          "token.actions.githubusercontent.com:sub": [
            "repo:<github-owner>/aws_infra:ref:refs/heads/main",
            "repo:<github-owner>/aws_infra:pull_request",
            "repo:<github-owner>/aws_infra:environment:dev",
            "repo:<github-owner>/aws_infra:environment:qa"
          ]
        }
      }
    }
  ]
}
```

Replace:

```text
<account-id>
<github-owner>
```

Example:

```text
repo:nshroff-learnings/aws_infra:environment:dev
```

The `environment:dev` and `environment:qa` entries must match the GitHub environments created later.

## 6. Attach Permissions to the GitHub Actions Role

For a learning setup, the simplest first pass is to temporarily attach:

```text
AdministratorAccess
```

AWS Console:

```text
IAM -> Roles -> aws-infra-github-actions -> Add permissions -> Attach policies
```

Attach:

```text
AdministratorAccess
```

This is broad. Use it only to get the pipeline working, then replace it with least privilege.

A narrower Terraform role eventually needs access to manage:

```text
S3 state bucket
EC2/VPC
IAM
EKS
ECR
Secrets Manager
CloudWatch Logs
Auto Scaling
Elastic Load Balancing
STS GetCallerIdentity
```

Copy the role ARN after creation. It looks like:

```text
arn:aws:iam::<account-id>:role/aws-infra-github-actions
```

You need this value for `AWS_ROLE_ARN` in GitHub.

## 7. Add GitHub Repository Variables

GitHub repository:

```text
Settings -> Secrets and variables -> Actions -> Variables
```

Create repository variables:

```text
AWS_REGION = us-east-1
AWS_ROLE_ARN = arn:aws:iam::<account-id>:role/aws-infra-github-actions
TF_STATE_BUCKET = your-state-bucket-name
TF_STATE_REGION = us-east-1
```

These match the workflow environment variables:

```yaml
AWS_REGION
AWS_ROLE_ARN
TF_STATE_BUCKET
TF_STATE_REGION
```

No AWS access keys are needed in GitHub.

## 8. Create GitHub Environments

GitHub repository:

```text
Settings -> Environments -> New environment
```

Create exactly:

```text
dev
qa
```

For each environment, optionally configure:

```text
Required reviewers
Deployment branches: main only
```

This matters because the workflow uses:

```yaml
environment: ${{ inputs.environment }}
```

The AWS role trust policy also allows:

```text
repo:<owner>/aws_infra:environment:dev
repo:<owner>/aws_infra:environment:qa
```

The names must match exactly.

## 9. First-Time Provisioning Order

Do not run `layers=all` the first time.

The file `variables/dev/eks.tfvars` currently has placeholders that depend on earlier layer outputs.

Run the workflow in GitHub:

```text
Actions -> Terraform Infrastructure -> Run workflow
```

### First Run: Networking

Choose:

```text
environment: dev
action: apply
layers: networking
```

After success, collect networking outputs and update `variables/dev/eks.tfvars`:

```text
REPLACE_WITH_INFRA_NETWORKING_OUTPUT_PRIVATE_SUBNET_ID_A
REPLACE_WITH_INFRA_NETWORKING_OUTPUT_PRIVATE_SUBNET_ID_B
```

### Second Run: IAM

Choose:

```text
environment: dev
action: apply
layers: iam
```

After success, update `variables/dev/eks.tfvars`:

```text
REPLACE_WITH_INFRA_IAM_OUTPUT_EKS_CLUSTER_ROLE_ARN
REPLACE_WITH_INFRA_IAM_OUTPUT_EKS_NODE_ROLE_ARN
REPLACE_WITH_GITHUB_ACTIONS_AWS_ROLE_ARN
```

Use the GitHub Actions role ARN for:

```text
REPLACE_WITH_GITHUB_ACTIONS_AWS_ROLE_ARN
```

### Third Run: Config

Choose:

```text
environment: dev
action: apply
layers: config
```

### Fourth Run: Compute

Choose:

```text
environment: dev
action: apply
layers: compute
```

### Fifth Run: Bootstrap

Only run bootstrap when the GitHub runner can reach the EKS API endpoint.

Choose:

```text
environment: dev
action: apply
layers: bootstrap
```

Current EKS settings are private endpoint only:

```hcl
endpoint_private_access = true
endpoint_public_access  = false
```

A GitHub-hosted runner probably cannot reach this endpoint.

Use one of these options:

```text
Self-hosted runner inside the VPC
VPN/private connectivity from runner network
Temporary public endpoint with restricted CIDRs
```

## 10. QA Setup

Repeat the same process for `qa`:

```text
variables/qa/*.tfvars
environment: qa
```

Make sure the AWS trust policy includes:

```text
repo:<github-owner>/aws_infra:environment:qa
```

## Minimum Checklist

Before running the workflow:

- Root MFA enabled.
- Human admin user created.
- Terraform state S3 bucket created.
- Bucket versioning enabled.
- Bucket encryption enabled.
- Bucket public access blocked.
- GitHub OIDC provider created in AWS IAM.
- GitHub Actions IAM role created.
- Trust policy updated for your repo and GitHub environments.
- Role has Terraform provisioning permissions.
- GitHub repo variables created.
- GitHub environments `dev` and `qa` created.
- `variables/dev/*.tfvars` reviewed.
- First run uses `layers=networking`, not `all`.

## References

- GitHub OIDC in AWS: https://docs.github.com/en/actions/how-tos/secure-your-work/security-harden-deployments/oidc-in-aws
- AWS OIDC provider docs: https://docs.aws.amazon.com/IAM/latest/UserGuide/id_roles_providers_create_oidc.html
- IAM Identity Center getting started: https://docs.aws.amazon.com/singlesignon/latest/userguide/getting-started.html
- S3 bucket creation: https://docs.aws.amazon.com/AmazonS3/latest/userguide/create-bucket-overview.html
