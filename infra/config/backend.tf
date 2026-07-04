terraform {
  backend "s3" {
    key                  = "config/terraform.tfstate"
    workspace_key_prefix = "env"
    encrypt              = true
  }
}
