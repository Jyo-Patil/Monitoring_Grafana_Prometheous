output "ecr_url" {
  value = aws_ecr_repository.zomato.repository_url
}

output "cluster_name" {
  value = aws_eks_cluster.eks.name
}
