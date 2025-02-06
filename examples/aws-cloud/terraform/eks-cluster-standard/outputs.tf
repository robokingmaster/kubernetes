output "aws_region" {
  description = "AWS region"
  value       = var.aws_region
}

output "aws_vpc_name" {
  description = "AWS created VPC name"
  value       = module.vpc.name
}

output "aws_vpc_cidr_block" {
  description = "AWS created VPC cidr block"
  value       = module.vpc.vpc_cidr_block
}

## EKS Cluster Information
output "cluster_id" {
  description = "EKS cluster ID."
  value       = module.eks.cluster_id
}

output "cluster_security_group_id" {
  description = "Security group ids attached to the cluster control plane"
  value       = module.eks.cluster_security_group_id
}

output "oidc_provider_arn" {
  value = module.eks.oidc_provider_arn
}

output "cluster_name" {
  description = "Kubernetes Cluster Name"
  value       = module.eks.cluster_name
}

output "cluster_endpoint" {
  description = "Endpoint for EKS control plane"
  value       = module.eks.cluster_endpoint
}
