ecr_repositories = {
  app = {
    repository_suffix              = "app"
    image_tag_mutability           = "IMMUTABLE"
    scan_on_push                   = true
    force_delete                   = false
    create_lifecycle_policy        = true
    untagged_image_expiration_days = 7
    max_tagged_image_count         = 20
    lifecycle_tag_prefixes         = ["v", "release", "main", "dev"]
  }
}

secrets = {
  app_config = {
    name                    = "aws-infra/dev/app/config"
    description             = "Application configuration secret metadata for dev. Secret value is not managed by Terraform."
    recovery_window_in_days = 7
  }
}
