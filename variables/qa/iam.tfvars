iam_roles = {}

eks_roles = {
  cluster = {
    role_name        = "aws-infra-qa-eks-cluster-role"
    description      = "EKS cluster service role for qa."
    trusted_services = ["eks.amazonaws.com"]
    managed_policy_arns = [
      "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
    ]
  }

  node = {
    role_name        = "aws-infra-qa-eks-node-role"
    description      = "EKS managed node group role for qa."
    trusted_services = ["ec2.amazonaws.com"]
    managed_policy_arns = [
      "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy",
      "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy",
      "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
    ]
  }
}

custom_policies = {}
