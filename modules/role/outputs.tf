output "iam_cluster_role_arn" {
  value = aws_iam_role.eks_cluster_role.arn
}

output "iam_node_role_arn" {
  value = aws_iam_role.eks_node_role.arn
}
