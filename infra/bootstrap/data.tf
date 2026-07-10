data "terraform_remote_state" "compute" {
  backend = "s3"

  config = {
    bucket = var.tf_state_bucket
    key    = "env/${var.environment}/compute/terraform.tfstate"
    region = var.tf_state_region
  }
}
