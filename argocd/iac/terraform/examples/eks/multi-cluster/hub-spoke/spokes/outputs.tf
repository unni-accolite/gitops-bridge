output "cluster_name" {
  description = "Cluster Hub name"
  value       = data.aws_eks_cluster.iac-admin-3.name
}
output "cluster_endpoint" {
  description = "Cluster Hub endpoint"
  value       = data.aws_eks_cluster.iac-admin-3.endpoint
}
output "cluster_certificate_authority_data" {
  description = "Cluster Hub certificate_authority_data"
  value       = data.aws_eks_cluster.iac-admin-3.certificate_authority
}
output "cluster_region" {
  description = "Cluster Hub region"
  value       = local.region
}
