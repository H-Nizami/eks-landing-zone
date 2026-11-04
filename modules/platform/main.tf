locals {
  charts = {
    karpenter        = { repository = "oci://public.ecr.aws/karpenter", chart = "karpenter", version = "1.15.1" }
    karpenter_crd    = { repository = "oci://public.ecr.aws/karpenter", chart = "karpenter-crd", version = "1.15.1" }
    external_secrets = { repository = "https://charts.external-secrets.io", chart = "external-secrets", version = "2.14.0" }
    kyverno          = { repository = "https://kyverno.github.io/kyverno/", chart = "kyverno", version = "3.9.2" }
  }
}
resource "helm_release" "karpenter_crd" {
  name             = "karpenter-crd"
  namespace        = "karpenter"
  create_namespace = true
  repository       = local.charts.karpenter_crd.repository
  chart            = local.charts.karpenter_crd.chart
  version          = local.charts.karpenter_crd.version
}
resource "helm_release" "karpenter" {
  name       = "karpenter"
  namespace  = "karpenter"
  repository = local.charts.karpenter.repository
  chart      = local.charts.karpenter.chart
  version    = local.charts.karpenter.version
  skip_crds  = true
  wait       = true
  values = [yamlencode({
    replicas = 2
    settings = {
      clusterName       = var.cluster_name
      interruptionQueue = var.karpenter_queue_name
    }
    # Node hop limit 1 blocks IMDS from pods, so the region cannot be discovered.
    controller = { env = [{ name = "AWS_REGION", value = var.region }] }
  })]
  depends_on = [helm_release.karpenter_crd]
}
resource "helm_release" "karpenter_config" {
  name      = "karpenter-config"
  namespace = "karpenter"
  chart     = "${path.module}/charts/karpenter-config"
  values = [yamlencode({
    clusterName  = var.cluster_name
    nodeRoleName = var.karpenter_node_role_name
    amiAlias     = var.node_ami_alias
    cpuLimit     = var.node_cpu_limit
  })]
  depends_on = [helm_release.karpenter]
}
# External Secrets and Kyverno do not tolerate the bootstrap taint, so they need Karpenter capacity first.
resource "helm_release" "external_secrets" {
  name             = "external-secrets"
  namespace        = "external-secrets"
  create_namespace = true
  repository       = local.charts.external_secrets.repository
  chart            = local.charts.external_secrets.chart
  version          = local.charts.external_secrets.version
  wait             = true
  timeout          = 600
  values = [yamlencode({
    installCRDs    = true
    replicaCount   = 2
    webhook        = { replicaCount = 2 }
    certController = { replicaCount = 2 }
  })]
  depends_on = [helm_release.karpenter_config]
}
resource "helm_release" "secret_store" {
  count      = var.enable_secret_store ? 1 : 0
  name       = "secret-store"
  namespace  = "external-secrets"
  chart      = "${path.module}/charts/secret-store"
  values     = [yamlencode({ region = var.region })]
  depends_on = [helm_release.external_secrets]
}
resource "helm_release" "kyverno" {
  name             = "kyverno"
  namespace        = "kyverno"
  create_namespace = true
  repository       = local.charts.kyverno.repository
  chart            = local.charts.kyverno.chart
  version          = local.charts.kyverno.version
  wait             = true
  timeout          = 600
  values = [yamlencode({
    admissionController  = { replicas = 3 }
    backgroundController = { replicas = 2 }
    cleanupController    = { replicas = 2 }
    reportsController    = { replicas = 2 }
  })]
  depends_on = [helm_release.karpenter_config]
}
resource "helm_release" "kyverno_policies" {
  name       = "kyverno-policies"
  namespace  = "kyverno"
  chart      = "${path.module}/charts/kyverno-policies"
  values     = [yamlencode({ validationAction = var.policy_action })]
  depends_on = [helm_release.kyverno, helm_release.external_secrets]
}
