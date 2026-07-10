data "terraform_remote_state" "networking" {
  backend = "s3"

  config = {
    bucket = var.tf_state_bucket
    key    = "env/${var.environment}/networking/terraform.tfstate"
    region = var.tf_state_region
  }
}

data "terraform_remote_state" "iam" {
  backend = "s3"

  config = {
    bucket = var.tf_state_bucket
    key    = "env/${var.environment}/iam/terraform.tfstate"
    region = var.tf_state_region
  }
}

data "aws_iam_role" "github_actions" {
  name = var.github_actions_role_name
}
