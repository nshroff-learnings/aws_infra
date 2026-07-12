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

data "aws_iam_roles" "eks_access" {
  for_each = {
    for item in flatten([
      for cluster_key, cluster in var.eks_clusters : [
        for entry_key, entry in cluster.access_entries : {
          key   = "${cluster_key}-${entry_key}"
          regex = try(entry.principal_role_name_regex, null)
        }
        if try(entry.principal_role_name_regex, null) != null
      ]
    ]) : item.key => item.regex
  }

  name_regex = each.value
}


