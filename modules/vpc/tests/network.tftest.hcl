mock_provider "aws" {
  mock_resource "aws_cloudwatch_log_group" { defaults = { arn = "arn:aws:logs:us-east-1:000000000000:log-group:/aws/vpc/example-vpc/flow" } }
  mock_resource "aws_iam_role" { defaults = { arn = "arn:aws:iam::000000000000:role/example-vpc-vpc-flow" } }
  mock_resource "aws_kms_key" { defaults = { arn = "arn:aws:kms:us-east-1:000000000000:key/00000000-0000-0000-0000-000000000000" } }
}
variables {
  name               = "example-vpc"
  vpc_cidr           = "10.40.0.0/16"
  availability_zones = ["us-east-1a", "us-east-1b", "us-east-1c"]
  region             = "us-east-1"
  account_id         = "000000000000"
  kms_admin_role_arn = "arn:aws:iam::000000000000:role/kms-admin"
}
run "az_local_nat" {
  command = plan
  assert {
    condition     = length(aws_nat_gateway.this) == 3 && length(aws_subnet.private) == 3 && length(aws_subnet.public) == 3
    error_message = "Expected three subnet pairs and three NAT gateways."
  }
  assert {
    condition     = aws_subnet.private["us-east-1a"].cidr_block == "10.40.48.0/20" && aws_subnet.public["us-east-1a"].cidr_block == "10.40.0.0/20"
    error_message = "Expected disjoint VPC subnet slices."
  }
  assert {
    condition     = alltrue([for i, az in var.availability_zones : aws_subnet.public[az].cidr_block == cidrsubnet(var.vpc_cidr, 4, i) && aws_subnet.private[az].cidr_block == cidrsubnet(var.vpc_cidr, 4, i + 3) && aws_subnet.private[az].availability_zone == az])
    error_message = "Each AZ must receive its documented disjoint public and private CIDR."
  }
  assert {
    condition     = length(aws_route_table.private) == 3 && length(aws_route_table_association.private) == 3 && alltrue([for az in var.availability_zones : one(aws_route_table.private[az].route).cidr_block == "0.0.0.0/0"])
    error_message = "Each private AZ must have a default route and route table association."
  }
  assert {
    condition     = alltrue([for subnet in aws_subnet.private : subnet.map_public_ip_on_launch == false]) && aws_flow_log.this.traffic_type == "ALL" && aws_cloudwatch_log_group.flow.retention_in_days == 365 && aws_kms_key.flow.enable_key_rotation
    error_message = "Private subnets and full flow logs are required."
  }
}
run "single_nat_sandbox" {
  command = plan
  variables { single_nat = true }
  assert {
    condition     = length(aws_nat_gateway.this) == 1 && length(aws_route_table.private) == 3
    error_message = "Single NAT mode should create one NAT gateway."
  }
}
