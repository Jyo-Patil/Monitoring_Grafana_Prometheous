############################################
# IAM Role for EKS Cluster
############################################
resource "aws_iam_role" "eks_cluster_role" {
  name = "eks-cluster-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect = "Allow",
      Principal = {
        Service = "eks.amazonaws.com"
      },
      Action = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "AmazonEKSClusterPolicy" {
  role       = aws_iam_role.eks_cluster_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
}

############################################
# EKS Cluster Resource
############################################
resource "aws_eks_cluster" "eks" {
  name     = "zomato-cluster"
  role_arn = aws_iam_role.eks_cluster_role.arn

  vpc_config {
    subnet_ids              = aws_subnet.public[*].id
    security_group_ids      = [aws_security_group.eks_node_sg.id]
    endpoint_public_access  = true
    endpoint_private_access = false
  }

  depends_on = [
    aws_iam_role_policy_attachment.AmazonEKSClusterPolicy
  ]
}

############################################
# IAM Role for Node Group
############################################
resource "aws_iam_role" "node_group_role" {
  name = "eks-node-group-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect = "Allow",
      Principal = {
        Service = "ec2.amazonaws.com"
      },
      Action = "sts:AssumeRole"
    }]
  })

  tags = {
    Name = "EKS Node Group Role"
  }
}

############################################
# Attach Policies to Node Group Role
############################################
resource "aws_iam_role_policy_attachment" "AmazonEKSWorkerNodePolicy" {
  role       = aws_iam_role.node_group_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
}

resource "aws_iam_role_policy_attachment" "AmazonEC2ContainerRegistryReadOnly" {
  role       = aws_iam_role.node_group_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}

resource "aws_iam_role_policy_attachment" "AmazonEKS_CNI_Policy" {
  role       = aws_iam_role.node_group_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
}

############################################
# EKS Node Group Resource
############################################
resource "aws_eks_node_group" "nodes" {
  cluster_name    = aws_eks_cluster.eks.name
  node_group_name = "zomato-nodes"
  node_role_arn   = aws_iam_role.node_group_role.arn
  subnet_ids      = aws_subnet.public[*].id
  instance_types  = ["t3.medium"]

  scaling_config {
    desired_size = 2
    max_size     = 3
    min_size     = 1
  }

  depends_on = [
    aws_iam_role_policy_attachment.AmazonEKSWorkerNodePolicy,
    aws_iam_role_policy_attachment.AmazonEKS_CNI_Policy,
    aws_iam_role_policy_attachment.AmazonEC2ContainerRegistryReadOnly
  ]
}
