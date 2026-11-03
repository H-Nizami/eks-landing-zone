mock_provider "aws" {
  mock_resource "aws_iam_role" { defaults = { arn = "arn:aws:iam::000000000000:role/example-role" } }
  mock_resource "aws_cloudwatch_log_group" { defaults = { arn = "arn:aws:logs:us-east-1:000000000000:log-group:example" } }
  mock_resource "aws_kms_key" { defaults = { arn = "arn:aws:kms:us-east-1:000000000000:key/00000000-0000-0000-0000-000000000000" } }
  mock_resource "aws_eks_cluster" { defaults = { arn = "arn:aws:eks:us-east-1:000000000000:cluster/example-eks" } }
}

run "foundation_without_workload_identity" {
  command = plan
  assert {
    condition     = length(module.vpc.private_subnet_ids) == 3 && module.eks.cluster_name == var.name && output.pod_identity_role_arn == null
    error_message = "The composed foundation must wire the VPC to EKS and omit optional workload IAM."
  }
}

run "foundation_with_workload_identity" {
  command = plan
  variables {
    enable_pod_identity = true
    secret_arns         = ["arn:aws:secretsmanager:us-east-1:000000000000:secret:example-AbCd12"]
  }
  assert {
    condition     = length(module.pod_identity) == 1 && module.eks.cluster_name == var.name
    error_message = "Enabling workload IAM must compose a role and association with the EKS cluster."
  }
}

run "reject_mismatched_az_region" {
  command = plan
  variables { availability_zones = ["eu-west-1a", "eu-west-1b", "eu-west-1c"] }
  expect_failures = [var.availability_zones]
}
