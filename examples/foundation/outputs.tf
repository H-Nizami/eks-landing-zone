output "vpc_id" { value = module.vpc.vpc_id }
output "private_subnet_ids" { value = module.vpc.private_subnet_ids }
output "cluster_name" { value = module.eks.cluster_name }
output "cluster_arn" { value = module.eks.cluster_arn }
output "pod_identity_role_arn" { value = var.enable_pod_identity ? module.pod_identity[0].role_arn : null }
