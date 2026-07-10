data "terraform_remote_state" "compute" {
  backend   = "s3"
  workspace = var.environment

  config = {
    bucket               = var.tf_state_bucket
    key                  = "compute/terraform.tfstate"
    region               = var.tf_state_region
    workspace_key_prefix = "env"
  }
}
