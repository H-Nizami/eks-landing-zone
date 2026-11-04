mock_provider "helm" {}
variables {
  cluster_name             = "example-eks"
  region                   = "us-east-1"
  karpenter_node_role_name = "example-eks-karpenter-node"
  karpenter_queue_name     = "example-eks-karpenter"
  node_ami_alias           = "al2023@v20261031"
}
run "charts_are_pinned" {
  command = plan
  assert {
    condition     = helm_release.karpenter.version == "1.15.1" && helm_release.karpenter_crd.version == "1.15.1"
    error_message = "Karpenter and its CRDs must share one exact version."
  }
  assert {
    condition     = helm_release.external_secrets.version == "2.14.0" && helm_release.kyverno.version == "3.9.2"
    error_message = "External Secrets and Kyverno must use exact versions."
  }
  assert {
    condition     = helm_release.karpenter.skip_crds
    error_message = "CRDs are upgraded through the dedicated chart."
  }
}
run "karpenter_values" {
  command = plan
  assert {
    condition     = yamldecode(helm_release.karpenter.values[0]).settings.clusterName == var.cluster_name && yamldecode(helm_release.karpenter.values[0]).settings.interruptionQueue == var.karpenter_queue_name
    error_message = "Karpenter must target this cluster and interruption queue."
  }
  assert {
    condition     = yamldecode(helm_release.karpenter.values[0]).controller.env[0].value == var.region
    error_message = "Karpenter needs the region because pods cannot reach IMDS."
  }
  assert {
    condition     = yamldecode(helm_release.karpenter_config.values[0]).amiAlias == var.node_ami_alias && yamldecode(helm_release.karpenter_config.values[0]).cpuLimit == 32
    error_message = "The node pool must use the pinned AMI and a CPU limit."
  }
}
run "kyverno_is_highly_available" {
  command = plan
  assert {
    condition     = yamldecode(helm_release.kyverno.values[0]).admissionController.replicas == 3
    error_message = "A failing admission webhook blocks pods, so run three replicas."
  }
  assert {
    condition     = yamldecode(helm_release.kyverno_policies.values[0]).validationAction == "Deny"
    error_message = "Policies must deny by default."
  }
}
run "secret_store_is_optional" {
  command = plan
  variables { enable_secret_store = false }
  assert {
    condition     = length(helm_release.secret_store) == 0
    error_message = "Disabling the store must omit its release."
  }
}
run "reject_floating_ami" {
  command = plan
  variables { node_ami_alias = "al2023@latest" }
  expect_failures = [var.node_ami_alias]
}
run "reject_unknown_policy_action" {
  command = plan
  variables { policy_action = "Warn" }
  expect_failures = [var.policy_action]
}
