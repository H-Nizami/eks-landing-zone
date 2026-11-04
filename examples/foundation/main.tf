provider "aws" { region = var.region }
module "vpc" {
  source             = "../../modules/vpc"
  name               = var.name
  vpc_cidr           = var.vpc_cidr
  availability_zones = var.availability_zones
  single_nat         = var.single_nat
  region             = var.region
  account_id         = var.account_id
  kms_admin_role_arn = var.kms_admin_role_arn
}
module "eks" {
  source             = "../../modules/eks"
  name               = var.name
  region             = var.region
  account_id         = var.account_id
  kubernetes_version = var.kubernetes_version
  private_subnet_ids = values(module.vpc.private_subnet_ids)
  operator_role_arn  = var.operator_role_arn
  kms_admin_role_arn = var.kms_admin_role_arn
}
module "pod_identity" {
  count           = var.enable_pod_identity ? 1 : 0
  source          = "../../modules/pod-identity"
  cluster_name    = module.eks.cluster_name
  cluster_arn     = module.eks.cluster_arn
  region          = var.region
  account_id      = var.account_id
  namespace       = var.namespace
  service_account = var.service_account
  secret_arns     = var.secret_arns
}
module "compute" {
  source             = "../../modules/compute"
  cluster_name       = module.eks.cluster_name
  kubernetes_version = var.kubernetes_version
  private_subnet_ids = values(module.vpc.private_subnet_ids)
  instance_types     = var.bootstrap_instance_types
  addon_versions = {
    vpc_cni            = var.vpc_cni_version
    kube_proxy         = var.kube_proxy_version
    coredns            = var.coredns_version
    pod_identity_agent = var.pod_identity_agent_version
  }
}
module "karpenter" {
  source                    = "../../modules/karpenter"
  cluster_name              = module.eks.cluster_name
  cluster_arn               = module.eks.cluster_arn
  region                    = var.region
  account_id                = var.account_id
  cluster_security_group_id = module.eks.cluster_security_group_id
  private_subnet_ids        = module.vpc.private_subnet_ids
}
