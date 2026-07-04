terraform {
  backend "s3" {
    key                  = "compute/terraform.tfstate"
    workspace_key_prefix = "env"
    encrypt              = true
  }
}
