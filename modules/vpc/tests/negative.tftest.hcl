mock_provider "aws" {
  mock_resource "aws_iam_role" { defaults = { arn = "arn:aws:iam::000000000000:role/example-role" } }
  mock_resource "aws_cloudwatch_log_group" { defaults = { arn = "arn:aws:logs:us-east-1:000000000000:log-group:example" } }
  mock_resource "aws_kms_key" { defaults = { arn = "arn:aws:kms:us-east-1:000000000000:key/00000000-0000-0000-0000-000000000000" } }
  mock_resource "aws_eks_cluster" { defaults = { arn = "arn:aws:eks:us-east-1:000000000000:cluster/example-eks" } }
}

variables {
  name               = "example-vpc"
  vpc_cidr           = "10.40.0.0/16"
  availability_zones = ["us-east-1a", "us-east-1b", "us-east-1c"]
  region             = "us-east-1"
  account_id         = "000000000000"
  kms_admin_role_arn = "arn:aws:iam::000000000000:role/kms-admin"
}

run "reject_small_cidr" {
  command = plan
  variables { vpc_cidr = "10.40.0.0/25" }
  expect_failures = [var.vpc_cidr]
}

run "reject_malformed_cidr" {
  command = plan
  variables { vpc_cidr = "10.40.0.0/not-a-prefix" }
  expect_failures = [var.vpc_cidr]
}

run "reject_duplicate_az" {
  command = plan
  variables { availability_zones = ["us-east-1a", "us-east-1a", "us-east-1c"] }
  expect_failures = [var.availability_zones]
}

run "reject_two_az" {
  command = plan
  variables { availability_zones = ["us-east-1a", "us-east-1b"] }
  expect_failures = [var.availability_zones]
}
