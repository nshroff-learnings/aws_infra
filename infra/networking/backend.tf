terraform {
  backend "s3" {
    key                  = "networking/terraform.tfstate"
    workspace_key_prefix = "env"
    encrypt              = true
  }
}
