iam_roles = {}

eks_roles = {
  cluster = {
    role_name        = "aws-infra-dev-eks-cluster-role"
    description      = "EKS cluster service role for dev."
    trusted_services = ["eks.amazonaws.com"]
    managed_policy_arns = [
      "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
    ]
  }

  node = {
    role_name        = "aws-infra-dev-eks-node-role"
    description      = "EKS managed node group role for dev."
    trusted_services = ["ec2.amazonaws.com"]
    managed_policy_arns = [
      "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy",
      "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy",
      "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
    ]
  }
}

custom_policies = {}

eks_admin_access_roles = {
  admins = {
    role_name  = "aws-infra-dev-eks-admin"
    group_name = "AWS-Admins"
  }
}

