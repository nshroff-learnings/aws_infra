terraform {
  backend "s3" {
    key                  = "iam/terraform.tfstate"
    workspace_key_prefix = "env"
    encrypt              = true
  }
}
