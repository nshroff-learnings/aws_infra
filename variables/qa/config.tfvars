ecr_repositories = {
  app = {
    repository_suffix              = "app"
    image_tag_mutability           = "IMMUTABLE"
    scan_on_push                   = true
    force_delete                   = false
    create_lifecycle_policy        = true
    untagged_image_expiration_days = 14
    max_tagged_image_count         = 30
    lifecycle_tag_prefixes         = ["v", "release", "main", "qa"]
  }
}

secrets = {
  app_config = {
    name                    = "aws-infra/qa/app/config"
    description             = "Application configuration secret metadata for qa. Secret value is not managed by Terraform."
    recovery_window_in_days = 14
  }
}
