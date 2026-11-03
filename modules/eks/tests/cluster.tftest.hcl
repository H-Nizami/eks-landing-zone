mock_provider "aws" {
  mock_resource "aws_iam_role" { defaults = { arn = "arn:aws:iam::000000000000:role/example-eks-eks-cluster" } }
  mock_resource "aws_kms_key" { defaults = { arn = "arn:aws:kms:us-east-1:000000000000:key/00000000-0000-0000-0000-000000000000" } }
}
variables {
  name               = "example-eks"
  private_subnet_ids = ["subnet-11111111", "subnet-22222222", "subnet-33333333"]
  region             = "us-east-1"
  account_id         = "000000000000"
  kubernetes_version = "1.34"
  operator_role_arn  = "arn:aws:iam::000000000000:role/eks-operator"
  kms_admin_role_arn = "arn:aws:iam::000000000000:role/kms-admin"
}
run "private_control_plane" {
  command = plan
  assert {
    condition     = aws_eks_cluster.this.vpc_config[0].endpoint_private_access && !aws_eks_cluster.this.vpc_config[0].endpoint_public_access
    error_message = "Cluster endpoint must be private only."
  }
  assert {
    condition     = aws_eks_cluster.this.access_config[0].authentication_mode == "API" && !aws_eks_cluster.this.access_config[0].bootstrap_cluster_creator_admin_permissions
    error_message = "Cluster access must use explicit API entries."
  }
  assert {
    condition     = length(aws_eks_cluster.this.enabled_cluster_log_types) == 5 && aws_kms_key.cluster.enable_key_rotation
    error_message = "Control plane logs and KMS rotation required."
  }
  assert {
    condition     = aws_eks_access_entry.operator.principal_arn == var.operator_role_arn
    error_message = "Operator access must use explicit role."
  }
}
