mock_provider "aws" {
  mock_resource "aws_iam_role" { defaults = { arn = "arn:aws:iam::000000000000:role/example-role" } }
  mock_resource "aws_cloudwatch_log_group" { defaults = { arn = "arn:aws:logs:us-east-1:000000000000:log-group:example" } }
  mock_resource "aws_kms_key" { defaults = { arn = "arn:aws:kms:us-east-1:000000000000:key/00000000-0000-0000-0000-000000000000" } }
  mock_resource "aws_eks_cluster" { defaults = { arn = "arn:aws:eks:us-east-1:000000000000:cluster/example-eks" } }
}

variables {
  cluster_name    = "example-eks"
  cluster_arn     = "arn:aws:eks:us-east-1:000000000000:cluster/example-eks"
  region          = "us-east-1"
  account_id      = "000000000000"
  namespace       = "external-secrets"
  service_account = "external-secrets"
  secret_arns     = ["arn:aws:secretsmanager:us-east-1:000000000000:secret:example-AbCd12"]
}

run "reject_wildcard_secret" {
  command = plan
  variables { secret_arns = ["arn:aws:secretsmanager:us-east-1:000000000000:secret:example-*"] }
  expect_failures = [var.secret_arns]
}

run "reject_cross_region_secret" {
  command = plan
  variables { secret_arns = ["arn:aws:secretsmanager:eu-west-1:000000000000:secret:example-AbCd12"] }
  expect_failures = [var.secret_arns]
}

run "reject_cross_account_secret" {
  command = plan
  variables { secret_arns = ["arn:aws:secretsmanager:us-east-1:111111111111:secret:example-AbCd12"] }
  expect_failures = [var.secret_arns]
}

run "reject_bad_namespace" {
  command = plan
  variables { namespace = "UPPER_CASE" }
  expect_failures = [var.namespace]
}

run "reject_bad_service_account" {
  command = plan
  variables { service_account = "bad.name" }
  expect_failures = [var.service_account]
}

run "reject_cluster_arn_mismatch" {
  command = plan
  variables { cluster_arn = "arn:aws:eks:us-east-1:111111111111:cluster/example-eks" }
  expect_failures = [var.cluster_arn]
}
