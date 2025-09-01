output "cluster_endpoint" {
  value = aws_eks_cluster.minimal_eks.endpoint
}

output "cluster_ca_certificate" {
  value = aws_eks_cluster.minimal_eks.certificate_authority[0].data
}

output "ebs_csi_driver_role_arn" {
  value = aws_iam_role.ebs_csi_driver_role.arn
}

output "oidc_arn"{
  value = aws_iam_openid_connect_provider.eks_oidc.arn
}