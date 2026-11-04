provider "helm" {
  kubernetes = {
    host                   = var.cluster_endpoint
    cluster_ca_certificate = base64decode(var.cluster_ca_certificate)
    exec = {
      api_version = "client.authentication.k8s.io/v1"
      command     = "aws"
      args        = ["eks", "get-token", "--cluster-name", var.cluster_name, "--region", var.region]
    }
  }
}
module "platform" {
  source                   = "../../modules/platform"
  cluster_name             = var.cluster_name
  region                   = var.region
  karpenter_node_role_name = var.karpenter_node_role_name
  karpenter_queue_name     = var.karpenter_queue_name
  node_ami_alias           = var.node_ami_alias
  node_cpu_limit           = var.node_cpu_limit
  policy_action            = var.policy_action
  enable_secret_store      = var.enable_secret_store
}
