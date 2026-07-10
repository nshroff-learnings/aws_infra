data "terraform_remote_state" "networking" {
  backend   = "s3"
  workspace = var.environment

  config = {
    bucket               = var.tf_state_bucket
    key                  = "networking/terraform.tfstate"
    region               = var.tf_state_region
    workspace_key_prefix = "env"
  }
}

data "terraform_remote_state" "iam" {
  backend   = "s3"
  workspace = var.environment

  config = {
    bucket               = var.tf_state_bucket
    key                  = "iam/terraform.tfstate"
    region               = var.tf_state_region
    workspace_key_prefix = "env"
  }
}

data "aws_iam_role" "github_actions" {
  name = var.github_actions_role_name
}
