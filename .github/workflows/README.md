# Terraform Infrastructure Workflow

This document explains `.github/workflows/terraform-infra.yml` and compares the GitHub Actions design with equivalent Azure DevOps YAML pipeline concepts.

## Purpose

`terraform-infra.yml` is the CI/CD workflow for Terraform infrastructure.

It supports:

- Pull request validation for infrastructure changes.
- Main branch validation for infrastructure changes.
- Manual runs where the operator chooses the environment, action, and Terraform layers.
- Layered execution in this order: `networking`, `iam`, `config`, `compute`, `bootstrap`.
- Optional Terraform apply, but only from a manual workflow run.

High-level flow:

```text
Layer Choice
  |
Networking Plan -> Networking Apply
  |
IAM Plan -> IAM Apply
  |
Config Plan -> Config Apply
  |
Compute Plan -> Compute Apply
  |
Bootstrap Plan -> Bootstrap Apply
```

In Azure DevOps terms, this behaves like a multi-stage Terraform pipeline even though GitHub Actions uses `jobs` plus `needs` instead of a separate `stages` keyword.

## Keyword vs Custom Name

Some YAML fields are fixed GitHub Actions keywords. Others are names chosen by this repository.

| Item | Type | Explanation |
|---|---|---|
| `name` | GitHub keyword | Sets the display name of the workflow or job. |
| `Terraform Infrastructure` | Custom value | Display name chosen for this workflow. |
| `on` | GitHub keyword | Defines events that trigger the workflow. |
| `pull_request` | GitHub event keyword | Runs the workflow for pull request activity. |
| `push` | GitHub event keyword | Runs the workflow for Git pushes. |
| `workflow_dispatch` | GitHub event keyword | Allows manual workflow runs from GitHub UI/API/CLI. |
| `paths` | GitHub keyword | Limits triggers to specific changed paths. |
| `branches` | GitHub keyword | Limits triggers to selected branches. |
| `inputs` | GitHub keyword | Defines manual input fields for `workflow_dispatch`. |
| `environment`, `action`, `layers` | Custom input names | Chosen by this repo. They can be renamed if all references are updated. |
| `description`, `type`, `required`, `default`, `options` | GitHub input keywords | Configure manual inputs. |
| `permissions` | GitHub keyword | Controls `GITHUB_TOKEN` and OIDC permissions. |
| `contents`, `id-token` | GitHub permission names | Fixed permission scopes. |
| `env` | GitHub keyword | Defines workflow-level environment variables. |
| `AWS_REGION`, `AWS_ROLE_ARN`, `TF_STATE_BUCKET` | Custom env var names | Chosen by this repo. |
| `vars` | GitHub context | Reads GitHub repository or environment variables. |
| `AWS_REGION` in `vars.AWS_REGION` | Custom repository variable name | Must exist in GitHub repo variables if no default is provided. |
| `concurrency` | GitHub keyword | Prevents overlapping runs for the same group. |
| `jobs` | GitHub keyword | Contains workflow jobs. |
| `networking_plan`, `networking_apply`, `iam_plan` | Custom job IDs | Chosen by this repo. Used by `needs` references. |
| `runs-on` | GitHub keyword | Selects the runner. |
| `ubuntu-latest` | GitHub runner label | GitHub-hosted Linux runner label. |
| `needs` | GitHub keyword | Defines job dependencies. Similar to Azure DevOps `dependsOn`. |
| `if` | GitHub keyword | Defines job or step conditions. Similar to Azure DevOps `condition`. |
| `steps` | GitHub keyword | Contains the commands/actions in a job. |
| `uses` | GitHub keyword | Runs a reusable GitHub Action. |
| `run` | GitHub keyword | Runs shell commands. |
| `with` | GitHub keyword | Passes inputs to an action. |
| `id` | GitHub keyword | Gives a step an ID so outputs can be referenced. |

## Trigger Section

The workflow starts with:

```yaml
on:
  pull_request:
    paths:
      - "infra/**"
      - "variables/**"
      - ".github/workflows/terraform-infra.yml"
  push:
    branches:
      - main
    paths:
      - "infra/**"
      - "variables/**"
      - ".github/workflows/terraform-infra.yml"
  workflow_dispatch:
    inputs:
      environment:
        type: choice
        default: dev
        options:
          - dev
          - qa
      action:
        type: choice
        default: plan
        options:
          - plan
          - apply
      layers:
        type: choice
        default: all
        options:
          - all
          - networking
          - iam
          - config
          - compute
          - bootstrap
```

Meaning:

- `pull_request`: runs when a PR changes `infra/**`, `variables/**`, or this workflow file.
- `push`: runs when `main` receives changes to those paths.
- `workflow_dispatch`: allows a person to manually start the workflow and provide inputs.

Azure DevOps equivalent:

```yaml
trigger:
  branches:
    include:
      - main
  paths:
    include:
      - infra/*
      - variables/*

pr:
  paths:
    include:
      - infra/*
      - variables/*

parameters:
  - name: environment
    type: string
    default: dev
    values:
      - dev
      - qa
```

## Other Trigger Options

`workflow_dispatch` is a GitHub Actions event keyword, not a custom name.

Common GitHub Actions trigger options:

| Trigger | GitHub keyword? | When to use |
|---|---:|---|
| `push` | Yes | Run when commits are pushed. |
| `pull_request` | Yes | Run CI checks for pull requests. |
| `workflow_dispatch` | Yes | Run manually with optional inputs. |
| `schedule` | Yes | Run on a cron schedule. Similar to Azure DevOps scheduled triggers. |
| `workflow_call` | Yes | Make this workflow reusable from another workflow. Similar in purpose to Azure DevOps templates, but it executes as a called workflow. |
| `repository_dispatch` | Yes | Trigger from an external system using the GitHub API. |
| `workflow_run` | Yes | Trigger after another workflow is requested or completed. |
| `release` | Yes | Trigger on GitHub release activity. |
| `deployment` | Yes | Trigger when a deployment is created. |
| `deployment_status` | Yes | Trigger when deployment status changes. |
| `issues` | Yes | Trigger on issue activity. Usually not needed for Terraform deployment. |
| `issue_comment` | Yes | Trigger on issue or PR comments. Sometimes used for ChatOps commands. |
| `pull_request_target` | Yes | Runs in the target repository context. Powerful but risky for untrusted PR code. |
| `merge_group` | Yes | Used with GitHub merge queues. |

The full list is maintained by GitHub in the official "Events that trigger workflows" docs.

## Manual Input Options

This workflow uses manual inputs under `workflow_dispatch`.

```yaml
environment:
  type: choice
  options:
    - dev
    - qa
```

`environment` is a custom input name.

`type`, `choice`, and `options` are GitHub-defined input syntax.

GitHub supports these `workflow_dispatch` input types:

- `boolean`
- `choice`
- `number`
- `environment`
- `string`

This workflow uses:

| Input | Name type | Input type | Meaning |
|---|---|---|---|
| `environment` | Custom name | `choice` | User chooses `dev` or `qa`. |
| `action` | Custom name | `choice` | User chooses `plan` or `apply`. |
| `layers` | Custom name | `choice` | User chooses `all` or one layer: `networking`, `iam`, `config`, `compute`, or `bootstrap`. |

Azure DevOps equivalent:

```yaml
parameters:
  - name: environment
    type: string
    default: dev
    values:
      - dev
      - qa

  - name: action
    type: string
    default: plan
    values:
      - plan
      - apply

  - name: layers
    type: string
    default: all
    values:
      - all
      - networking
      - iam
      - config
      - compute
      - bootstrap
```

## Permissions and AWS Authentication

The workflow defines:

```yaml
permissions:
  contents: read
  id-token: write
```

Meaning:

- `contents: read`: allows the workflow to read repository code.
- `id-token: write`: allows GitHub Actions to request an OIDC token.

The OIDC token is used here:

```yaml
- uses: aws-actions/configure-aws-credentials@v4
  with:
    role-to-assume: ${{ env.AWS_ROLE_ARN }}
    aws-region: ${{ env.AWS_REGION }}
```

This lets the workflow assume an AWS IAM role without storing long-lived AWS access keys.

Azure DevOps equivalent:

- AWS service connection.
- Workload identity federation/OIDC if configured.
- Secret-based AWS credentials, though OIDC is usually better.

## Global Environment Variables

The workflow defines:

```yaml
env:
  TF_IN_AUTOMATION: "true"
  AWS_REGION: ${{ vars.AWS_REGION || 'us-east-1' }}
  AWS_ROLE_ARN: ${{ vars.AWS_ROLE_ARN }}
  TF_STATE_BUCKET: ${{ vars.TF_STATE_BUCKET }}
  TF_STATE_REGION: ${{ vars.TF_STATE_REGION || vars.AWS_REGION || 'us-east-1' }}
  TARGET_ENV: ${{ github.event_name == 'workflow_dispatch' && inputs.environment || 'dev' }}
```

Meaning:

- `TF_IN_AUTOMATION`: tells Terraform it is running in automation.
- `AWS_REGION`: AWS region used by the workflow.
- `AWS_ROLE_ARN`: AWS IAM role GitHub Actions assumes.
- `TF_STATE_BUCKET`: S3 bucket for Terraform state.
- `TF_STATE_REGION`: region for the S3 state bucket.
- `TARGET_ENV`: selected environment for manual runs, otherwise `dev`.

Azure DevOps equivalent:

```yaml
variables:
  TF_IN_AUTOMATION: true
  AWS_REGION: us-east-1
  TF_STATE_REGION: us-east-1
```

For real Azure DevOps pipelines, values usually live in:

- Pipeline variables.
- Variable groups.
- Secret variables.
- Environment-specific variable templates.

## Concurrency

The workflow defines:

```yaml
concurrency:
  group: terraform-${{ github.workflow }}-${{ github.event_name == 'workflow_dispatch' && inputs.environment || 'dev' }}
  cancel-in-progress: false
```

This prevents multiple Terraform runs for the same environment from running at the same time.

That matters because overlapping Terraform applies can cause state locking conflicts, inconsistent plan/apply behavior, or two operators deploying to the same environment at once.

Azure DevOps equivalent:

- Environment exclusive lock checks.
- Deployment environments with approvals and checks.
- `lockBehavior: sequential` when using environment locks.

## Layer Choice Conditions

The workflow no longer has a separate setup job to parse `layers`.

Instead, each job checks the selected choice directly with `inputs.layers`.

Example:

```yaml
if: ${{ github.event_name != 'workflow_dispatch' || inputs.layers == 'all' || inputs.layers == 'networking' }}
```

Meaning:

- For PR and push runs, run as if `layers=all`.
- For manual runs with `layers=all`, run all layer plan jobs.
- For manual runs with `layers=networking`, run only the networking plan/apply jobs.

The tradeoff is that `choice` is single-select. It supports `all` or one layer at a time, but not arbitrary combinations like `networking,iam` unless those combinations are added as explicit choices.

## Plan Jobs

Each Terraform layer has a plan job:

- `networking_plan`
- `iam_plan`
- `config_plan`
- `compute_plan`
- `bootstrap_plan`

Each plan job follows the same pattern:

1. Checkout code.
2. Install Terraform.
3. Validate required inputs.
4. Configure AWS credentials.
5. Run `terraform fmt -check -recursive`.
6. Run `terraform init`.
7. Select or create the Terraform workspace.
8. Run `terraform validate`.
9. Run Checkov.
10. Run `terraform plan`.
11. Convert the plan to a text file.
12. Upload the text plan as an artifact.

Example from networking:

```bash
terraform -chdir=infra/networking plan -input=false -no-color -out=tfplan \
  -var-file=../../variables/${TARGET_ENV}/common.tfvars \
  -var-file=../../variables/${TARGET_ENV}/networking.tfvars

terraform -chdir=infra/networking show -no-color tfplan > plan-networking.txt
```

Azure DevOps equivalent:

```yaml
- checkout: self

- script: terraform fmt -check -recursive
  displayName: Terraform fmt

- script: terraform -chdir=infra/networking init
  displayName: Terraform init

- script: terraform -chdir=infra/networking validate
  displayName: Terraform validate

- script: terraform -chdir=infra/networking plan -input=false -no-color -out=tfplan
  displayName: Terraform plan

- publish: infra/networking/plan-networking.txt
  artifact: terraform-plan-dev-networking
```

## Apply Jobs

Each Terraform layer has an apply job:

- `networking_apply`
- `iam_apply`
- `config_apply`
- `compute_apply`
- `bootstrap_apply`

Apply jobs only run when:

```yaml
github.event_name == 'workflow_dispatch' && inputs.action == 'apply'
```

That means apply runs only for manual runs where the user selected `action=apply`.

These do not apply on:

- Pull requests.
- Pushes to `main`.
- Manual runs with `action=plan`.

Each apply job also has:

```yaml
environment: ${{ inputs.environment }}
```

In GitHub Actions, `environment` is a deployment environment. It can enforce approvals, environment secrets, and protection rules.

Azure DevOps equivalent:

```yaml
jobs:
- deployment: ApplyNetworking
  environment: dev
```

Azure DevOps deployment environments can also enforce approvals and checks.

## Layer Order and Dependencies

The workflow applies layers in dependency order.

| Layer | Directory | Variable file | Depends on |
|---|---|---|---|
| `networking` | `infra/networking` | `networking.tfvars` | First |
| `iam` | `infra/iam` | `iam.tfvars` | Networking |
| `config` | `infra/config` | `config.tfvars` | IAM |
| `compute` | `infra/compute` | `eks.tfvars` | Config |
| `bootstrap` | `infra/bootstrap` | `bootstrap.tfvars` | Compute |

Example:

```yaml
iam_plan:
  needs: networking_apply
  if: ${{ always() && (github.event_name != 'workflow_dispatch' || inputs.layers == 'all' || inputs.layers == 'iam') && (github.event_name != 'workflow_dispatch' || inputs.layers != 'all' || inputs.action != 'apply' || needs.networking_apply.result == 'success') }}
```

Meaning:

- Run IAM for PR/push runs, because those behave like `layers=all`.
- Run IAM for manual `layers=all` or manual `layers=iam`.
- For manual `layers=all` with `action=apply`, continue only after networking apply succeeds.
- For manual single-layer `layers=iam`, do not require networking to run first.

Azure DevOps equivalent:

```yaml
dependsOn: NetworkingApply
condition: |
  and(
    always(),
    or(
      ne(variables['Build.Reason'], 'Manual'),
      eq('${{ parameters.layers }}', 'all'),
      eq('${{ parameters.layers }}', 'iam')
    ),
    or(
      ne('${{ parameters.layers }}', 'all'),
      ne('${{ parameters.action }}', 'apply'),
      eq(dependencies.NetworkingApply.result, 'Succeeded')
    )
  )
```

## GitHub Actions to Azure DevOps Mapping

| GitHub Actions | Azure DevOps YAML |
|---|---|
| `on.push` | `trigger` |
| `on.pull_request` | `pr` |
| `workflow_dispatch.inputs` | `parameters` |
| `env` | `variables` |
| `vars.X` | Pipeline variables or variable groups |
| `secrets.X` | Secret variables or variable groups |
| `jobs.<job_id>` | `jobs` or `stages` |
| `runs-on: ubuntu-latest` | `pool: vmImage: ubuntu-latest` |
| `steps` | `steps` |
| `uses: actions/checkout@v4` | `checkout: self` |
| `uses: hashicorp/setup-terraform@v3` | Terraform installer task or script install |
| `uses: aws-actions/configure-aws-credentials@v4` | AWS service connection task or AWS CLI setup |
| `needs` | `dependsOn` |
| `if:` | `condition:` |
| `actions/upload-artifact` | `PublishPipelineArtifact` or `publish` |
| `environment:` | `environment:` on a deployment job |
| `concurrency` | Environment exclusive lock/checks |

## Important Design Note

The apply jobs do not consume the exact plan artifact produced by the plan jobs.

They run a fresh plan and immediately apply it:

```bash
terraform plan -input=false -out=tfplan
terraform apply -input=false -auto-approve tfplan
```

That is valid, but it means the reviewed text artifact may not be exactly the same plan that gets applied if something changes between the plan job and the apply job.

A stricter production pattern is:

1. Create a binary plan in the plan job.
2. Upload the binary plan as a protected artifact.
3. Download the same binary plan in the apply job.
4. Apply exactly that plan.

This workflow avoids uploading binary plan files because Terraform plans may contain sensitive values. That is a reasonable tradeoff for this repository, but for production you should explicitly choose between:

- Applying the exact reviewed plan.
- Avoiding sensitive binary plan artifacts.

## Official References

- GitHub Actions workflow syntax: https://docs.github.com/en/actions/reference/workflows-and-actions/workflow-syntax
- GitHub Actions events that trigger workflows: https://docs.github.com/en/actions/reference/workflows-and-actions/events-that-trigger-workflows
