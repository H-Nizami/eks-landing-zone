mock_provider "aws" {
  mock_resource "aws_iam_role" { defaults = { arn = "arn:aws:iam::000000000000:role/example-role" } }
  mock_resource "aws_cloudwatch_log_group" { defaults = { arn = "arn:aws:logs:us-east-1:000000000000:log-group:example" } }
  mock_resource "aws_kms_key" { defaults = { arn = "arn:aws:kms:us-east-1:000000000000:key/00000000-0000-0000-0000-000000000000" } }
  mock_resource "aws_eks_cluster" { defaults = { arn = "arn:aws:eks:us-east-1:000000000000:cluster/example-eks" } }
}

run "foundation_private" {
  command = plan
  assert {
    condition     = module.eks.cluster_name == "example-eks"
    error_message = "Expected composed cluster name."
  }
  assert {
    condition     = length(module.vpc.private_subnet_ids) == 3 && length(module.vpc.public_subnet_ids) == 3
    error_message = "Expected three subnet pairs."
  }
  assert {
    condition     = module.pod_identity == []
    error_message = "Workload role should be disabled by default."
  }
}

run "pod_identity_enabled" {
  command = plan
  variables {
    enable_pod_identity = true
    secret_arns         = ["arn:aws:secretsmanager:us-east-1:000000000000:secret:demo-ABC123"]
  }
  assert {
    condition     = length(module.pod_identity) == 1
    error_message = "Expected one workload identity."
  }
}
