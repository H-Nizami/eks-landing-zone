mock_provider "aws" {
  mock_resource "aws_launch_template" { defaults = { id = "lt-0123456789abcdef0", latest_version = 1 } }
}
variables {
  cluster_name       = "example-eks"
  kubernetes_version = "1.36"
  private_subnet_ids = ["subnet-11111111", "subnet-22222222", "subnet-33333333"]
  addon_versions = {
    vpc_cni            = "v1.23.2-eksbuild.8"
    kube_proxy         = "v1.36.0-eksbuild.58"
    coredns            = "v1.14.7-eksbuild.22"
    pod_identity_agent = "v1.3.0-eksbuild.1"
  }
}
run "secure_bootstrap_nodes" {
  command = plan
  assert {
    condition     = aws_launch_template.bootstrap.metadata_options[0].http_tokens == "required" && aws_launch_template.bootstrap.metadata_options[0].http_put_response_hop_limit == 1
    error_message = "Bootstrap nodes must require IMDSv2 and block pod access with hop limit 1."
  }
  assert {
    condition     = aws_launch_template.bootstrap.block_device_mappings[0].ebs[0].encrypted == "true"
    error_message = "Root volumes must be encrypted."
  }
  assert {
    condition     = one(aws_eks_node_group.bootstrap.taint).key == "CriticalAddonsOnly" && one(aws_eks_node_group.bootstrap.taint).effect == "NO_SCHEDULE"
    error_message = "Bootstrap nodes must be reserved for system controllers."
  }
  assert {
    condition     = aws_eks_node_group.bootstrap.capacity_type == "ON_DEMAND" && aws_eks_node_group.bootstrap.scaling_config[0].min_size == 2
    error_message = "Bootstrap capacity must be at least two on-demand nodes."
  }
  assert {
    condition     = toset(aws_eks_node_group.bootstrap.subnet_ids) == toset(var.private_subnet_ids)
    error_message = "Nodes must run in the supplied private subnets."
  }
}
run "addons_are_pinned" {
  command = plan
  assert {
    condition     = aws_eks_addon.before_nodes["vpc-cni"].addon_version == "v1.23.2-eksbuild.8" && aws_eks_addon.before_nodes["kube-proxy"].addon_version == "v1.36.0-eksbuild.58" && aws_eks_addon.before_nodes["eks-pod-identity-agent"].addon_version == "v1.3.0-eksbuild.1"
    error_message = "Pre-node add-ons must use the exact supplied versions."
  }
  assert {
    condition     = aws_eks_addon.coredns.addon_version == "v1.14.7-eksbuild.22"
    error_message = "CoreDNS must use the exact supplied version."
  }
}
run "node_role_has_only_required_policies" {
  command = plan
  assert {
    condition     = length(aws_iam_role_policy_attachment.node) == 3 && !contains(keys(aws_iam_role_policy_attachment.node), "AdministratorAccess")
    error_message = "The node role must keep the three required managed policies."
  }
}
run "reject_floating_addon_version" {
  command = plan
  variables {
    addon_versions = {
      vpc_cni            = "latest"
      kube_proxy         = "v1.36.0-eksbuild.58"
      coredns            = "v1.14.7-eksbuild.22"
      pod_identity_agent = "v1.3.0-eksbuild.1"
    }
  }
  expect_failures = [var.addon_versions]
}
run "reject_single_bootstrap_node" {
  command = plan
  variables { bootstrap_size = 1 }
  expect_failures = [var.bootstrap_size]
}
