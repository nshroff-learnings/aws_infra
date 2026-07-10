provider "aws" {
  region = var.aws_region

  default_tags {
    tags = local.tags
  }
}

data "aws_eks_cluster" "platform" {
  name = local.platform_cluster_name
}

data "aws_eks_cluster_auth" "platform" {
  name = local.platform_cluster_name
}

provider "kubernetes" {
  host                   = data.aws_eks_cluster.platform.endpoint
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.platform.certificate_authority[0].data)
  token                  = data.aws_eks_cluster_auth.platform.token
}

provider "helm" {
  kubernetes {
    host                   = data.aws_eks_cluster.platform.endpoint
    cluster_ca_certificate = base64decode(data.aws_eks_cluster.platform.certificate_authority[0].data)
    token                  = data.aws_eks_cluster_auth.platform.token
  }
}

provider "kubectl" {
  host                   = data.aws_eks_cluster.platform.endpoint
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.platform.certificate_authority[0].data)
  token                  = data.aws_eks_cluster_auth.platform.token
  load_config_file       = false
}

