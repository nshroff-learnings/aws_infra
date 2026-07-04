# Shared Module Catalog

Inspected source: `https://github.com/nshroff-learnings/aws_modules.git` on `main` at commit `16a80d96f53a968f26946f80cdd37acc9a46eb40`.

Re-check upstream README, variables, outputs, and examples before implementation. Pin to a tag or commit SHA; use the inspected commit only when the user has not selected a release.

## Available Modules

### `vpc`

Source: `git::https://github.com/nshroff-learnings/aws_modules.git//modules/vpc?ref=<tag-or-sha>`

Creates one VPC, private subnets by default, optional public subnets, route tables, and an Internet Gateway only when public subnets are provided. It does not create a NAT Gateway.

Required inputs:
- `name_prefix`
- `environment`

Important optional inputs:
- `vpc_cidr`
- `private_subnet_cidrs`
- `public_subnet_cidrs`
- `availability_zones`
- `map_public_ip_on_launch`
- `tags`

### `s3-bucket`

Source: `git::https://github.com/nshroff-learnings/aws_modules.git//modules/s3-bucket?ref=<tag-or-sha>`

Creates one private S3 bucket with public access block, ownership controls, versioning, encryption, optional access logging, lifecycle rules, bucket policy, S3 Gateway VPC Endpoint, and optional endpoint-restricted bucket policy.

Required inputs:
- `name_prefix`
- `environment`

Important optional inputs:
- `bucket_name`
- `bucket_suffix`
- `versioning_enabled`
- `kms_key_arn`
- `object_ownership`
- public access block flags
- `bucket_policy_json`
- `create_vpc_endpoint`
- `vpc_id`
- `vpc_endpoint_route_table_ids`
- `vpc_endpoint_policy_json`
- `restrict_bucket_to_vpc_endpoint`
- `access_log_bucket_name`
- `lifecycle_rules`
- `tags`

### `iam-role`

Source: `git::https://github.com/nshroff-learnings/aws_modules.git//modules/iam-role?ref=<tag-or-sha>`

Creates one IAM role with generated or custom trust policy, optional managed policy attachments, inline policies, permissions boundary, and optional EC2 instance profile.

Required inputs:
- `name_prefix`
- `environment`
- At least one trusted principal input, or `custom_assume_role_policy_json`

Important optional inputs:
- `trusted_services`
- `trusted_aws_principals`
- `trusted_federated_principals`
- `federated_conditions`
- `managed_policy_arns`
- `inline_policies`
- `permissions_boundary_arn`
- `create_instance_profile`
- `tags`

### `ecr-repository`

Source: `git::https://github.com/nshroff-learnings/aws_modules.git//modules/ecr-repository?ref=<tag-or-sha>`

Creates one private ECR repository with AES256 or KMS encryption, immutable tags by default, scan-on-push by default, optional lifecycle policy, and optional repository policy.

Required inputs:
- `name_prefix`
- `environment`

Important optional inputs:
- `repository_name`
- `repository_suffix`
- `image_tag_mutability`
- `scan_on_push`
- `kms_key_arn`
- `force_delete`
- `create_lifecycle_policy`
- `lifecycle_policy_json`
- `repository_policy_json`
- `tags`

## Not Present In Inspected Main

- `eks-cluster`

If a task asks for a module not listed here, inspect upstream first. Do not assume the module exists.
