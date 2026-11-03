locals {
  azs           = toset(var.availability_zones)
  public_cidrs  = { for i, az in var.availability_zones : az => cidrsubnet(var.vpc_cidr, 4, i) }
  private_cidrs = { for i, az in var.availability_zones : az => cidrsubnet(var.vpc_cidr, 4, i + 3) }
  nat_az        = var.single_nat ? var.availability_zones[0] : null
}
resource "aws_vpc" "this" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags                 = { Name = var.name }
}
resource "aws_default_security_group" "locked" {
  vpc_id = aws_vpc.this.id
  # No ingress or egress rules: AWS default allow-all rules are removed.
}
resource "aws_internet_gateway" "this" {
  vpc_id = aws_vpc.this.id
  tags   = { Name = "${var.name}-igw" }
}
resource "aws_subnet" "public" {
  for_each                = local.azs
  vpc_id                  = aws_vpc.this.id
  availability_zone       = each.key
  cidr_block              = local.public_cidrs[each.key]
  map_public_ip_on_launch = false
  tags                    = { Name = "${var.name}-public-${each.key}" }
}
resource "aws_subnet" "private" {
  for_each                = local.azs
  vpc_id                  = aws_vpc.this.id
  availability_zone       = each.key
  cidr_block              = local.private_cidrs[each.key]
  map_public_ip_on_launch = false
  tags                    = { Name = "${var.name}-private-${each.key}" }
}
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.this.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.this.id
  }
}
resource "aws_route_table_association" "public" {
  for_each       = local.azs
  subnet_id      = aws_subnet.public[each.key].id
  route_table_id = aws_route_table.public.id
}
resource "aws_eip" "nat" {
  #checkov:skip=CKV2_AWS_19:NAT gateway EIPs attach to NAT gateways, not EC2 instances.
  for_each   = var.single_nat ? toset([local.nat_az]) : local.azs
  domain     = "vpc"
  depends_on = [aws_internet_gateway.this]
}
resource "aws_nat_gateway" "this" {
  for_each      = aws_eip.nat
  allocation_id = each.value.id
  subnet_id     = aws_subnet.public[each.key].id
  depends_on    = [aws_internet_gateway.this]
}
resource "aws_route_table" "private" {
  for_each = local.azs
  vpc_id   = aws_vpc.this.id
  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.this[var.single_nat ? local.nat_az : each.key].id
  }
}
resource "aws_route_table_association" "private" {
  for_each       = local.azs
  subnet_id      = aws_subnet.private[each.key].id
  route_table_id = aws_route_table.private[each.key].id
}
resource "aws_cloudwatch_log_group" "flow" {
  name              = "/aws/vpc/${var.name}/flow"
  retention_in_days = 365
  kms_key_id        = aws_kms_key.flow.arn
}
resource "aws_kms_key" "flow" {
  description         = "VPC flow logs for ${var.name}"
  enable_key_rotation = true
  policy = jsonencode({ Version = "2012-10-17", Statement = [
    { Sid = "Administration", Effect = "Allow", Principal = { AWS = var.kms_admin_role_arn }, Action = "kms:*", Resource = "*" },
    { Sid = "CloudWatchLogs", Effect = "Allow", Principal = { Service = "logs.${var.region}.amazonaws.com" }, Action = ["kms:Encrypt", "kms:Decrypt", "kms:ReEncrypt*", "kms:GenerateDataKey*", "kms:DescribeKey"], Resource = "*", Condition = { ArnLike = { "kms:EncryptionContext:aws:logs:arn" = "arn:aws:logs:${var.region}:${var.account_id}:log-group:/aws/vpc/${var.name}/flow" } } }
  ] })
}
resource "aws_iam_role" "flow" {
  name               = "${var.name}-vpc-flow"
  assume_role_policy = jsonencode({ Version = "2012-10-17", Statement = [{ Effect = "Allow", Principal = { Service = "vpc-flow-logs.amazonaws.com" }, Action = "sts:AssumeRole" }] })
}
resource "aws_iam_role_policy" "flow" {
  name   = "${var.name}-vpc-flow"
  role   = aws_iam_role.flow.id
  policy = jsonencode({ Version = "2012-10-17", Statement = [{ Effect = "Allow", Action = ["logs:CreateLogStream", "logs:PutLogEvents", "logs:DescribeLogStreams"], Resource = "${aws_cloudwatch_log_group.flow.arn}:*" }] })
}
resource "aws_flow_log" "this" {
  vpc_id               = aws_vpc.this.id
  traffic_type         = "ALL"
  log_destination_type = "cloud-watch-logs"
  log_destination      = aws_cloudwatch_log_group.flow.arn
  iam_role_arn         = aws_iam_role.flow.arn
  depends_on           = [aws_iam_role_policy.flow]
}
