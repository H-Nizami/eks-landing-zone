mock_provider "aws" {
  mock_resource "aws_iam_role" { defaults = { arn = "arn:aws:iam::000000000000:role/example-eks-eks-cluster" } }
  mock_resource "aws_kms_key" { defaults = { arn = "arn:aws:kms:us-east-1:000000000000:key/00000000-0000-0000-0000-000000000000" } }
}

variables {
  name               = "example-eks"
  region             = "us-east-1"
  account_id         = "000000000000"
  kubernetes_version = "1.34"
  private_subnet_ids = ["subnet-aaaa1111", "subnet-bbbb2222", "subnet-cccc3333"]
  operator_role_arn  = "arn:aws:iam::000000000000:role/eks-operator"
  kms_admin_role_arn = "arn:aws:iam::000000000000:role/kms-admin"
}

run "private_cluster_and_access" {
  command = plan
  assert {
    condition     = !aws_eks_cluster.this.vpc_config[0].endpoint_public_access && aws_eks_cluster.this.vpc_config[0].endpoint_private_access && toset(aws_eks_cluster.this.vpc_config[0].subnet_ids) == toset(var.private_subnet_ids)
    error_message = "EKS must use only the supplied private subnets and a private endpoint."
  }
  assert {
    condition     = toset(aws_eks_cluster.this.enabled_cluster_log_types) == toset(["api", "audit", "authenticator", "controllerManager", "scheduler"]) && aws_cloudwatch_log_group.cluster.retention_in_days == 365 && aws_kms_key.cluster.enable_key_rotation
    error_message = "All control-plane logs must be retained for a year and encrypted with a rotating key."
  }
  assert {
    condition     = aws_eks_cluster.this.access_config[0].authentication_mode == "API" && !aws_eks_cluster.this.access_config[0].bootstrap_cluster_creator_admin_permissions && length(aws_eks_cluster.this.encryption_config) == 1
    error_message = "EKS must use API access entries, no implicit creator admin, and secrets encryption."
  }
  assert {
    condition     = aws_eks_access_entry.operator.principal_arn == var.operator_role_arn && aws_eks_access_policy_association.operator.policy_arn == "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy" && aws_eks_access_policy_association.operator.access_scope[0].type == "cluster"
    error_message = "Only the explicit operator role receives cluster admin access."
  }
  assert {
    condition     = jsondecode(aws_iam_role.cluster.assume_role_policy).Statement[0].Principal.Service == "eks.amazonaws.com" && jsondecode(aws_iam_role.cluster.assume_role_policy).Statement[0].Action == "sts:AssumeRole"
    error_message = "Cluster IAM trust must name only the EKS service."
  }
}

run "reject_wrong_operator_account" {
  command = plan
  variables { operator_role_arn = "arn:aws:iam::111111111111:role/eks-operator" }
  expect_failures = [var.operator_role_arn]
}

run "reject_bad_account" {
  command = plan
  variables { account_id = "123" }
  expect_failures = [var.account_id]
}

run "reject_bad_region" {
  command = plan
  variables { region = "somewhere" }
  expect_failures = [var.region]
}
