# AWS Setup for GitHub Actions Terraform Pipeline

This guide prepares an AWS account so `.github/workflows/terraform-infra.yml` can run Terraform from GitHub Actions using AWS OIDC.

The workflow expects this AWS/GitHub setup:

- An S3 bucket for Terraform remote state.
- IAM Identity Center for human access instead of day-to-day root access.
- A GitHub Actions OIDC provider in AWS IAM.
- An IAM role that GitHub Actions can assume.
- IAM permissions on that role to manage the infrastructure in this repo.
- GitHub repository variables used by the workflow.
- GitHub environments named `dev` and `qa` for apply approvals.

The commands below use PowerShell syntax because this repo is being worked on from Windows.

## Important Constraints

This repo is not fully one-click from an empty AWS account yet.

The first provisioning pass must be staged because `variables/<env>/eks.tfvars` contains placeholders for outputs created by earlier layers:

- Private subnet IDs from `infra/networking`.
- EKS cluster role ARN from `infra/iam`.
- EKS node role ARN from `infra/iam`.
- GitHub Actions AWS role ARN from this setup.

The `bootstrap` layer also needs network access to the EKS API endpoint. Current `eks.tfvars` uses:

```hcl
endpoint_private_access = true
endpoint_public_access  = false
```

That means a normal GitHub-hosted runner cannot reach the EKS Kubernetes API for the Helm/Kubernetes providers. For the `bootstrap` layer, use one of these options:

- Preferred: self-hosted GitHub runner inside the VPC or connected network.
- Temporary bootstrap option: enable public EKS endpoint access with tightly restricted CIDRs, then disable it after bootstrap.
- VPN/Direct Connect/private connectivity from the runner network.

## Prerequisites

Install and authenticate these tools locally:

- AWS CLI v2.
- GitHub CLI, optional but useful for setting repository variables and environments.
- An AWS principal allowed to create IAM Identity Center resources, S3 buckets, IAM OIDC providers, IAM roles, and IAM policies.
- A GitHub repository admin or maintainer token for setting repo variables/environments.

Verify AWS access:

```powershell
aws sts get-caller-identity
```

Verify GitHub CLI access, if using `gh`:

```powershell
gh auth status
```

## Choose Setup Values

Set these values for your repository and AWS account.

```powershell
$env:AWS_REGION = "us-east-1"
$env:GITHUB_OWNER = "YOUR_GITHUB_OWNER_OR_ORG"
$env:GITHUB_REPO = "aws_infra"
$env:ROLE_NAME = "aws-infra-github-actions"
$env:POLICY_NAME = "aws-infra-github-actions-terraform"

$env:AWS_ACCOUNT_ID = aws sts get-caller-identity --query Account --output text
$env:TF_STATE_BUCKET = "aws-infra-$($env:AWS_ACCOUNT_ID)-tfstate-$($env:AWS_REGION)"
$env:OIDC_PROVIDER_URL = "https://token.actions.githubusercontent.com"
$env:OIDC_PROVIDER_HOST = "token.actions.githubusercontent.com"

$env:AWS_ACCOUNT_ID
$env:TF_STATE_BUCKET
```

S3 bucket names are globally unique. If `TF_STATE_BUCKET` is already taken, choose a different name.

## Set Up IAM Identity Center for Human Access

Before setting up GitHub Actions provisioning, stop using the AWS root user for daily work.

Use IAM Identity Center for human access. This is the AWS-native replacement for creating long-lived IAM users for people.

The model should look like this:

```text
Root user: emergency/account-only tasks
IAM Identity Center user: normal console and CLI access
GitHub Actions OIDC role: Terraform automation access
```

This is similar to Azure users having read access by default and elevating when needed, but AWS does not provide a perfect built-in Azure PIM equivalent for approval-based elevation in a single standalone account. The practical AWS baseline is separate permission sets with short sessions and CloudTrail audit. If you use Microsoft Entra ID, the closer PIM-like pattern is to use Entra PIM for group elevation and federate those groups into IAM Identity Center.

### IAM Identity Center Caveat

AWS supports IAM Identity Center APIs through `sso-admin` and `identitystore`.

For a single learning account, the CLI `create-instance` flow can create a standalone IAM Identity Center instance.

For production multi-account AWS Organizations, prefer an organization instance of IAM Identity Center. Depending on your account and organization state, initial enablement may need to be done in the AWS console from the management account. After the instance exists, the CLI commands below manage users, groups, permission sets, and assignments.

### Choose IAM Identity Center Values

Set these values for the first human admin user.

```powershell
$env:SSO_INSTANCE_NAME = "aws-infra-identity-center"
$env:SSO_USER_NAME = "naresh"
$env:SSO_USER_EMAIL = "nshroff@example.com"
$env:SSO_GIVEN_NAME = "Naresh"
$env:SSO_FAMILY_NAME = "Admin"
```

Use your real email address. IAM Identity Center sends the initial password/setup email to this address when using the built-in identity store.

### Create or Locate the IAM Identity Center Instance

First check whether an instance already exists:

```powershell
$instances = aws sso-admin list-instances | ConvertFrom-Json
$instances.Instances
```

If no instance exists, create one:

```powershell
if (-not $instances.Instances -or $instances.Instances.Count -eq 0) {
  aws sso-admin create-instance `
    --name $env:SSO_INSTANCE_NAME

  Start-Sleep -Seconds 20
  $instances = aws sso-admin list-instances | ConvertFrom-Json
}
```

Export the instance ARN and identity store ID:

```powershell
$env:SSO_INSTANCE_ARN = $instances.Instances[0].InstanceArn
$env:IDENTITY_STORE_ID = $instances.Instances[0].IdentityStoreId

$env:SSO_INSTANCE_ARN
$env:IDENTITY_STORE_ID
```

If `create-instance` fails because your account requires organization-level enablement, enable IAM Identity Center in the AWS console first, then rerun `list-instances` and continue from this point.

### Create IAM Identity Center Groups

Create these groups:

```text
AWS-ReadOnly
AWS-PowerUsers
AWS-Admins
AWS-Billing
```

Use this helper function so rerunning the guide does not create duplicates:

```powershell
function Get-OrCreateIdentityStoreGroupId {
  param(
    [Parameter(Mandatory = $true)][string]$DisplayName,
    [Parameter(Mandatory = $true)][string]$Description
  )

  $groupId = aws identitystore list-groups `
    --identity-store-id $env:IDENTITY_STORE_ID `
    --query "Groups[?DisplayName=='$DisplayName'].GroupId | [0]" `
    --output text

  if ($groupId -eq "None" -or [string]::IsNullOrWhiteSpace($groupId)) {
    $groupId = aws identitystore create-group `
      --identity-store-id $env:IDENTITY_STORE_ID `
      --display-name $DisplayName `
      --description $Description `
      --query GroupId `
      --output text
  }

  return $groupId
}

$readOnlyGroupId = Get-OrCreateIdentityStoreGroupId "AWS-ReadOnly" "Default read-only access to AWS accounts"
$powerUsersGroupId = Get-OrCreateIdentityStoreGroupId "AWS-PowerUsers" "Power user access without full IAM administration"
$adminsGroupId = Get-OrCreateIdentityStoreGroupId "AWS-Admins" "Short-session administrator access"
$billingGroupId = Get-OrCreateIdentityStoreGroupId "AWS-Billing" "Billing and cost management access"

$readOnlyGroupId
$powerUsersGroupId
$adminsGroupId
$billingGroupId
```

### Create Your IAM Identity Center User

Check whether the user already exists:

```powershell
$userId = aws identitystore list-users `
  --identity-store-id $env:IDENTITY_STORE_ID `
  --query "Users[?UserName=='$($env:SSO_USER_NAME)'].UserId | [0]" `
  --output text
```

Create the user if needed:

```powershell
if ($userId -eq "None" -or [string]::IsNullOrWhiteSpace($userId)) {
  $userId = aws identitystore create-user `
    --identity-store-id $env:IDENTITY_STORE_ID `
    --user-name $env:SSO_USER_NAME `
    --display-name "$($env:SSO_GIVEN_NAME) $($env:SSO_FAMILY_NAME)" `
    --name "GivenName=$($env:SSO_GIVEN_NAME),FamilyName=$($env:SSO_FAMILY_NAME)" `
    --emails "Value=$($env:SSO_USER_EMAIL),Type=work,Primary=true" `
    --query UserId `
    --output text
}

$userId
```

### Add Yourself to ReadOnly and Admin Groups

Add yourself to the default read-only group:

```powershell
aws identitystore create-group-membership `
  --identity-store-id $env:IDENTITY_STORE_ID `
  --group-id $readOnlyGroupId `
  --member-id "UserId=$userId"
```

Add yourself to the admin group:

```powershell
aws identitystore create-group-membership `
  --identity-store-id $env:IDENTITY_STORE_ID `
  --group-id $adminsGroupId `
  --member-id "UserId=$userId"
```

If either command returns `ConflictException`, the membership already exists and you can continue.

Do not add yourself to every group by default. Keep normal day-to-day access read-only, and use the admin permission set only when needed.

### Create Permission Sets

Create four permission sets:

```text
ReadOnlyAccess
PowerUserAccess
AdministratorAccess
BillingAccess
```

Session duration guidance:

- Read-only: `PT8H` is usually acceptable.
- Power user: `PT2H` or less.
- Admin: `PT1H` or `PT2H`.
- Billing: `PT4H` or less.

Use this helper to create permission sets:

```powershell
function New-PermissionSetArn {
  param(
    [Parameter(Mandatory = $true)][string]$Name,
    [Parameter(Mandatory = $true)][string]$Description,
    [Parameter(Mandatory = $true)][string]$SessionDuration
  )

  $existingArns = aws sso-admin list-permission-sets `
    --instance-arn $env:SSO_INSTANCE_ARN `
    --query PermissionSets `
    --output json | ConvertFrom-Json

  foreach ($arn in $existingArns) {
    $existingName = aws sso-admin describe-permission-set `
      --instance-arn $env:SSO_INSTANCE_ARN `
      --permission-set-arn $arn `
      --query PermissionSet.Name `
      --output text

    if ($existingName -eq $Name) {
      return $arn
    }
  }

  return aws sso-admin create-permission-set `
    --instance-arn $env:SSO_INSTANCE_ARN `
    --name $Name `
    --description $Description `
    --session-duration $SessionDuration `
    --query PermissionSet.PermissionSetArn `
    --output text
}

$readOnlyPermissionSetArn = New-PermissionSetArn "ReadOnlyAccess" "Read-only AWS account access" "PT8H"
$powerUserPermissionSetArn = New-PermissionSetArn "PowerUserAccess" "Power user AWS account access" "PT2H"
$adminPermissionSetArn = New-PermissionSetArn "AdministratorAccess" "Short-session administrator access" "PT1H"
$billingPermissionSetArn = New-PermissionSetArn "BillingAccess" "Billing and cost management access" "PT4H"

$readOnlyPermissionSetArn
$powerUserPermissionSetArn
$adminPermissionSetArn
$billingPermissionSetArn
```

### Attach AWS Managed Policies to Permission Sets

Attach AWS managed policies:

```powershell
aws sso-admin attach-managed-policy-to-permission-set `
  --instance-arn $env:SSO_INSTANCE_ARN `
  --permission-set-arn $readOnlyPermissionSetArn `
  --managed-policy-arn arn:aws:iam::aws:policy/ReadOnlyAccess

aws sso-admin attach-managed-policy-to-permission-set `
  --instance-arn $env:SSO_INSTANCE_ARN `
  --permission-set-arn $powerUserPermissionSetArn `
  --managed-policy-arn arn:aws:iam::aws:policy/PowerUserAccess

aws sso-admin attach-managed-policy-to-permission-set `
  --instance-arn $env:SSO_INSTANCE_ARN `
  --permission-set-arn $adminPermissionSetArn `
  --managed-policy-arn arn:aws:iam::aws:policy/AdministratorAccess

aws sso-admin attach-managed-policy-to-permission-set `
  --instance-arn $env:SSO_INSTANCE_ARN `
  --permission-set-arn $billingPermissionSetArn `
  --managed-policy-arn arn:aws:iam::aws:policy/job-function/Billing
```

If a policy is already attached, AWS may return a conflict or no-op style response depending on API behavior. Continue if the desired attachment already exists.

### Assign Groups to This AWS Account

Assign each group to its matching permission set for this account:

```powershell
aws sso-admin create-account-assignment `
  --instance-arn $env:SSO_INSTANCE_ARN `
  --target-id $env:AWS_ACCOUNT_ID `
  --target-type AWS_ACCOUNT `
  --permission-set-arn $readOnlyPermissionSetArn `
  --principal-type GROUP `
  --principal-id $readOnlyGroupId

aws sso-admin create-account-assignment `
  --instance-arn $env:SSO_INSTANCE_ARN `
  --target-id $env:AWS_ACCOUNT_ID `
  --target-type AWS_ACCOUNT `
  --permission-set-arn $powerUserPermissionSetArn `
  --principal-type GROUP `
  --principal-id $powerUsersGroupId

aws sso-admin create-account-assignment `
  --instance-arn $env:SSO_INSTANCE_ARN `
  --target-id $env:AWS_ACCOUNT_ID `
  --target-type AWS_ACCOUNT `
  --permission-set-arn $adminPermissionSetArn `
  --principal-type GROUP `
  --principal-id $adminsGroupId

aws sso-admin create-account-assignment `
  --instance-arn $env:SSO_INSTANCE_ARN `
  --target-id $env:AWS_ACCOUNT_ID `
  --target-type AWS_ACCOUNT `
  --permission-set-arn $billingPermissionSetArn `
  --principal-type GROUP `
  --principal-id $billingGroupId
```

These commands return assignment creation status. It can take a few minutes before access appears in the IAM Identity Center portal.

### Provision Permission Sets

Provision the permission sets to the account:

```powershell
foreach ($permissionSetArn in @($readOnlyPermissionSetArn, $powerUserPermissionSetArn, $adminPermissionSetArn, $billingPermissionSetArn)) {
  aws sso-admin provision-permission-set `
    --instance-arn $env:SSO_INSTANCE_ARN `
    --permission-set-arn $permissionSetArn `
    --target-type AWS_ACCOUNT `
    --target-id $env:AWS_ACCOUNT_ID
}
```

### Use IAM Identity Center for AWS CLI Access

After the assignment is active, configure an SSO-backed AWS CLI profile:

```powershell
aws configure sso --profile aws-infra-admin
```

Choose the IAM Identity Center start URL, AWS account, and `AdministratorAccess` permission set.

Login with:

```powershell
aws sso login --profile aws-infra-admin
```

Then use:

```powershell
aws sts get-caller-identity --profile aws-infra-admin
```

For normal day-to-day work, also create a read-only profile:

```powershell
aws configure sso --profile aws-infra-readonly
aws sso login --profile aws-infra-readonly
```

After this is working, stop using the root account for routine work.

## Create the Terraform State Bucket

Create the S3 bucket used by the Terraform backend.

```powershell
if ($env:AWS_REGION -eq "us-east-1") {
  aws s3api create-bucket `
    --bucket $env:TF_STATE_BUCKET `
    --region $env:AWS_REGION
} else {
  aws s3api create-bucket `
    --bucket $env:TF_STATE_BUCKET `
    --region $env:AWS_REGION `
    --create-bucket-configuration LocationConstraint=$env:AWS_REGION
}
```

Enable versioning:

```powershell
aws s3api put-bucket-versioning `
  --bucket $env:TF_STATE_BUCKET `
  --versioning-configuration Status=Enabled
```

Enable default encryption:

```powershell
aws s3api put-bucket-encryption `
  --bucket $env:TF_STATE_BUCKET `
  --server-side-encryption-configuration '{"Rules":[{"ApplyServerSideEncryptionByDefault":{"SSEAlgorithm":"AES256"}}]}'
```

Block public access:

```powershell
aws s3api put-public-access-block `
  --bucket $env:TF_STATE_BUCKET `
  --public-access-block-configuration BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true
```

Require HTTPS access to the bucket:

```powershell
$bucketPolicy = @{
  Version = "2012-10-17"
  Statement = @(
    @{
      Sid = "DenyInsecureTransport"
      Effect = "Deny"
      Principal = "*"
      Action = "s3:*"
      Resource = @(
        "arn:aws:s3:::$($env:TF_STATE_BUCKET)",
        "arn:aws:s3:::$($env:TF_STATE_BUCKET)/*"
      )
      Condition = @{
        Bool = @{
          "aws:SecureTransport" = "false"
        }
      }
    }
  )
} | ConvertTo-Json -Depth 20

$bucketPolicyPath = Join-Path $env:TEMP "tf-state-bucket-policy.json"
$bucketPolicy | Set-Content -Path $bucketPolicyPath -Encoding utf8

aws s3api put-bucket-policy `
  --bucket $env:TF_STATE_BUCKET `
  --policy file://$bucketPolicyPath
```

The Terraform backend files in this repo already use S3 backend keys like:

```text
networking/terraform.tfstate
iam/terraform.tfstate
config/terraform.tfstate
compute/terraform.tfstate
bootstrap/terraform.tfstate
```

They also use `workspace_key_prefix = "env"`, so dev state paths look like:

```text
env/dev/networking/terraform.tfstate
env/dev/iam/terraform.tfstate
env/dev/config/terraform.tfstate
env/dev/compute/terraform.tfstate
env/dev/bootstrap/terraform.tfstate
```

## Create the GitHub OIDC Provider

Check whether the provider already exists:

```powershell
$providerArn = aws iam list-open-id-connect-providers `
  --query "OpenIDConnectProviderList[?contains(Arn, '$($env:OIDC_PROVIDER_HOST)')].Arn | [0]" `
  --output text

$providerArn
```

If it returns `None`, create it:

```powershell
if ($providerArn -eq "None" -or [string]::IsNullOrWhiteSpace($providerArn)) {
  aws iam create-open-id-connect-provider `
    --url $env:OIDC_PROVIDER_URL `
    --client-id-list sts.amazonaws.com `
    --tags Key=Project,Value=aws-infra Key=ManagedBy,Value=aws-cli

  $providerArn = aws iam list-open-id-connect-providers `
    --query "OpenIDConnectProviderList[?contains(Arn, '$($env:OIDC_PROVIDER_HOST)')].Arn | [0]" `
    --output text
}

$providerArn
```

If your AWS CLI or account policy requires a thumbprint at create time, use the AWS console or retrieve the current GitHub OIDC certificate thumbprint using your organization's approved process. AWS IAM now uses its trusted root CA library when possible and falls back to thumbprint verification when required.

## Create the GitHub Actions IAM Trust Policy

This trust policy allows the role to be assumed only by this repository through GitHub OIDC.

It allows:

- Push/manual plan runs on `main`.
- Pull request validation runs.
- Apply jobs that use GitHub environments `dev` and `qa`.

```powershell
$repoSlug = "$($env:GITHUB_OWNER)/$($env:GITHUB_REPO)"

$trustPolicy = @{
  Version = "2012-10-17"
  Statement = @(
    @{
      Effect = "Allow"
      Principal = @{
        Federated = "arn:aws:iam::$($env:AWS_ACCOUNT_ID):oidc-provider/$($env:OIDC_PROVIDER_HOST)"
      }
      Action = "sts:AssumeRoleWithWebIdentity"
      Condition = @{
        StringEquals = @{
          "token.actions.githubusercontent.com:aud" = "sts.amazonaws.com"
        }
        StringLike = @{
          "token.actions.githubusercontent.com:sub" = @(
            "repo:$repoSlug:ref:refs/heads/main",
            "repo:$repoSlug:pull_request",
            "repo:$repoSlug:environment:dev",
            "repo:$repoSlug:environment:qa"
          )
        }
      }
    }
  )
} | ConvertTo-Json -Depth 20

$trustPolicyPath = Join-Path $env:TEMP "github-actions-trust-policy.json"
$trustPolicy | Set-Content -Path $trustPolicyPath -Encoding utf8
Get-Content $trustPolicyPath
```

Create the role:

```powershell
aws iam create-role `
  --role-name $env:ROLE_NAME `
  --assume-role-policy-document file://$trustPolicyPath `
  --description "GitHub Actions Terraform role for $repoSlug" `
  --tags Key=Project,Value=aws-infra Key=ManagedBy,Value=aws-cli
```

If the role already exists, update the trust policy instead:

```powershell
aws iam update-assume-role-policy `
  --role-name $env:ROLE_NAME `
  --policy-document file://$trustPolicyPath
```

Get the role ARN:

```powershell
$env:AWS_ROLE_ARN = aws iam get-role `
  --role-name $env:ROLE_NAME `
  --query Role.Arn `
  --output text

$env:AWS_ROLE_ARN
```

## Create a Terraform Provisioning Policy

For a learning repo, the easiest setup is attaching `AdministratorAccess` temporarily, running the pipeline, then replacing it with least privilege after reviewing CloudTrail and Terraform state.

That is operationally simple but high privilege:

```powershell
aws iam attach-role-policy `
  --role-name $env:ROLE_NAME `
  --policy-arn arn:aws:iam::aws:policy/AdministratorAccess
```

A narrower starter policy is below. It is still broad because this repo provisions VPC, IAM, ECR, Secrets Manager, EKS, CloudWatch logs, and Kubernetes bootstrap dependencies. Treat it as a starting point, not final least privilege.

```powershell
$terraformPolicy = @{
  Version = "2012-10-17"
  Statement = @(
    @{
      Sid = "TerraformStateBucketAccess"
      Effect = "Allow"
      Action = @(
        "s3:ListBucket",
        "s3:GetBucketVersioning",
        "s3:GetBucketLocation"
      )
      Resource = "arn:aws:s3:::$($env:TF_STATE_BUCKET)"
    },
    @{
      Sid = "TerraformStateObjectAccess"
      Effect = "Allow"
      Action = @(
        "s3:GetObject",
        "s3:PutObject",
        "s3:DeleteObject"
      )
      Resource = "arn:aws:s3:::$($env:TF_STATE_BUCKET)/*"
    },
    @{
      Sid = "TerraformProvisioningServices"
      Effect = "Allow"
      Action = @(
        "ec2:*",
        "eks:*",
        "ecr:*",
        "secretsmanager:*",
        "iam:*",
        "logs:*",
        "cloudwatch:*",
        "autoscaling:*",
        "elasticloadbalancing:*",
        "kms:DescribeKey",
        "kms:ListAliases",
        "sts:GetCallerIdentity"
      )
      Resource = "*"
    }
  )
} | ConvertTo-Json -Depth 20

$terraformPolicyPath = Join-Path $env:TEMP "github-actions-terraform-policy.json"
$terraformPolicy | Set-Content -Path $terraformPolicyPath -Encoding utf8

aws iam create-policy `
  --policy-name $env:POLICY_NAME `
  --policy-document file://$terraformPolicyPath `
  --description "Starter Terraform provisioning policy for GitHub Actions aws_infra repo" `
  --tags Key=Project,Value=aws-infra Key=ManagedBy,Value=aws-cli
```

Attach the policy:

```powershell
$policyArn = "arn:aws:iam::$($env:AWS_ACCOUNT_ID):policy/$($env:POLICY_NAME)"

aws iam attach-role-policy `
  --role-name $env:ROLE_NAME `
  --policy-arn $policyArn
```

If you attached `AdministratorAccess` for initial bootstrapping, remove it after the narrower policy is proven sufficient:

```powershell
aws iam detach-role-policy `
  --role-name $env:ROLE_NAME `
  --policy-arn arn:aws:iam::aws:policy/AdministratorAccess
```

## Create GitHub Repository Variables

The workflow reads these GitHub repository variables:

- `AWS_REGION`
- `AWS_ROLE_ARN`
- `TF_STATE_BUCKET`
- `TF_STATE_REGION`

Using GitHub CLI:

```powershell
gh variable set AWS_REGION --repo "$($env:GITHUB_OWNER)/$($env:GITHUB_REPO)" --body $env:AWS_REGION
gh variable set AWS_ROLE_ARN --repo "$($env:GITHUB_OWNER)/$($env:GITHUB_REPO)" --body $env:AWS_ROLE_ARN
gh variable set TF_STATE_BUCKET --repo "$($env:GITHUB_OWNER)/$($env:GITHUB_REPO)" --body $env:TF_STATE_BUCKET
gh variable set TF_STATE_REGION --repo "$($env:GITHUB_OWNER)/$($env:GITHUB_REPO)" --body $env:AWS_REGION
```

If you do not use `gh`, set them in GitHub UI:

```text
Repository -> Settings -> Secrets and variables -> Actions -> Variables
```

No long-lived AWS access key is required. The workflow uses OIDC and temporary credentials.

## Create GitHub Environments

The apply jobs use:

```yaml
environment: ${{ inputs.environment }}
```

Create environments named exactly:

- `dev`
- `qa`

Using GitHub CLI:

```powershell
gh api `
  --method PUT `
  -H "Accept: application/vnd.github+json" `
  "/repos/$($env:GITHUB_OWNER)/$($env:GITHUB_REPO)/environments/dev"

gh api `
  --method PUT `
  -H "Accept: application/vnd.github+json" `
  "/repos/$($env:GITHUB_OWNER)/$($env:GITHUB_REPO)/environments/qa"
```

Then configure required reviewers or deployment protection rules in GitHub UI if you want an approval gate:

```text
Repository -> Settings -> Environments -> dev / qa
```

The IAM trust policy above includes `repo:OWNER/REPO:environment:dev` and `repo:OWNER/REPO:environment:qa`, so environment names must match.

## First-Time Provisioning Order

Use staged deployment for the first run.

### 1. Run Networking

In GitHub Actions:

```text
Actions -> Terraform Infrastructure -> Run workflow
```

Choose:

```text
environment: dev
action: apply
layers: networking
```

After it succeeds, get networking outputs locally:

```powershell
terraform -chdir=infra/networking init `
  -backend-config="bucket=$env:TF_STATE_BUCKET" `
  -backend-config="region=$env:AWS_REGION"

terraform -chdir=infra/networking workspace select dev
terraform -chdir=infra/networking output -json
```

Copy the private subnet IDs into `variables/dev/eks.tfvars`.

### 2. Run IAM

Run the workflow again:

```text
environment: dev
action: apply
layers: iam
```

After it succeeds, get IAM outputs locally:

```powershell
terraform -chdir=infra/iam init `
  -backend-config="bucket=$env:TF_STATE_BUCKET" `
  -backend-config="region=$env:AWS_REGION"

terraform -chdir=infra/iam workspace select dev
terraform -chdir=infra/iam output -json
```

Copy these into `variables/dev/eks.tfvars`:

- EKS cluster role ARN.
- EKS node role ARN.

Also replace:

```text
REPLACE_WITH_GITHUB_ACTIONS_AWS_ROLE_ARN
```

with:

```powershell
$env:AWS_ROLE_ARN
```

Commit and push the tfvars updates if this repo is the source used by GitHub Actions.

### 3. Run Config

Run:

```text
environment: dev
action: apply
layers: config
```

### 4. Run Compute

Run:

```text
environment: dev
action: apply
layers: compute
```

If the EKS endpoint remains private-only, GitHub-hosted runners can still call the AWS EKS API to create the cluster, but they will not be able to use Kubernetes/Helm providers against that private endpoint later.

### 5. Prepare Bootstrap Variables

Update `variables/dev/bootstrap.tfvars`:

```hcl
platform_repo_url = "https://github.com/YOUR_ORG/YOUR_PLATFORM_REPO.git"
```

Set the real platform repo URL and path.

### 6. Run Bootstrap

Only run bootstrap when the runner can reach the private EKS endpoint.

Run:

```text
environment: dev
action: apply
layers: bootstrap
```

If using GitHub-hosted runners, this will fail unless the EKS endpoint is reachable publicly or through configured private connectivity.

## QA Environment

Repeat the same process for `qa`:

- Use `variables/qa/*.tfvars`.
- Run workflow with `environment=qa`.
- Replace placeholders in `variables/qa/eks.tfvars`.
- Confirm the IAM trust policy includes `repo:OWNER/REPO:environment:qa`.

## Verification Commands

Check role identity by assuming it from GitHub Actions. Add this temporary step after `configure-aws-credentials` if debugging:

```yaml
- name: Show AWS identity
  run: aws sts get-caller-identity
```

Check the state bucket:

```powershell
aws s3api get-bucket-versioning --bucket $env:TF_STATE_BUCKET
aws s3api get-bucket-encryption --bucket $env:TF_STATE_BUCKET
aws s3api get-public-access-block --bucket $env:TF_STATE_BUCKET
```

Check OIDC provider:

```powershell
aws iam list-open-id-connect-providers
```

Check role trust policy:

```powershell
aws iam get-role --role-name $env:ROLE_NAME --query Role.AssumeRolePolicyDocument
```

## Cleanup Commands

Use these only if you intentionally want to remove the CI AWS setup.

Detach policies:

```powershell
aws iam detach-role-policy --role-name $env:ROLE_NAME --policy-arn "arn:aws:iam::$($env:AWS_ACCOUNT_ID):policy/$($env:POLICY_NAME)"
aws iam detach-role-policy --role-name $env:ROLE_NAME --policy-arn arn:aws:iam::aws:policy/AdministratorAccess
```

Delete the role and custom policy:

```powershell
aws iam delete-role --role-name $env:ROLE_NAME
aws iam delete-policy --policy-arn "arn:aws:iam::$($env:AWS_ACCOUNT_ID):policy/$($env:POLICY_NAME)"
```

Do not delete the S3 state bucket unless all Terraform-managed infrastructure has been destroyed and you no longer need state history.

## References

- GitHub OIDC in AWS: https://docs.github.com/en/actions/how-tos/secure-your-work/security-harden-deployments/oidc-in-aws
- AWS IAM OIDC provider docs: https://docs.aws.amazon.com/IAM/latest/UserGuide/id_roles_providers_create_oidc.html
- AWS CLI IAM Identity Center sso-admin: https://docs.aws.amazon.com/cli/latest/reference/sso-admin/
- AWS CLI Identity Store commands: https://docs.aws.amazon.com/cli/latest/reference/identitystore/
- AWS configure credentials action: https://github.com/aws-actions/configure-aws-credentials
