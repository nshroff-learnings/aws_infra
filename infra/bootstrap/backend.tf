terraform {
  backend "s3" {
    key                  = "bootstrap/terraform.tfstate"
    workspace_key_prefix = "env"
  }
}

