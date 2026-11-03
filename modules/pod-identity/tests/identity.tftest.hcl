mock_provider "aws" {
  mock_resource "aws_iam_role" { defaults = { arn = "arn:aws:iam::000000000000:role/example-eks-external-secrets" } }
}
variables {
  cluster_name    = "example-eks"
  cluster_arn     = "arn:aws:eks:us-east-1:000000000000:cluster/example-eks"
  region          = "us-east-1"
  account_id      = "000000000000"
  namespace       = "external-secrets"
  service_account = "external-secrets"
  secret_arns     = ["arn:aws:secretsmanager:us-east-1:000000000000:secret:demo-ABC123"]
}
run "scoped_identity" {
  command = plan
  assert {
    condition     = aws_eks_pod_identity_association.this.cluster_name == var.cluster_name && aws_eks_pod_identity_association.this.namespace == var.namespace && aws_eks_pod_identity_association.this.service_account == var.service_account && !aws_eks_pod_identity_association.this.disable_session_tags
    error_message = "Association must target exact workload."
  }
  assert {
    condition     = jsondecode(aws_iam_role.this.assume_role_policy).Statement[0].Principal.Service == "pods.eks.amazonaws.com" && toset(jsondecode(aws_iam_role.this.assume_role_policy).Statement[0].Action) == toset(["sts:AssumeRole", "sts:TagSession"]) && jsondecode(aws_iam_role.this.assume_role_policy).Statement[0].Condition.StringEquals["aws:RequestTag/eks-cluster-arn"] == var.cluster_arn && jsondecode(aws_iam_role.this.assume_role_policy).Statement[0].Condition.StringEquals["aws:RequestTag/kubernetes-namespace"] == var.namespace && jsondecode(aws_iam_role.this.assume_role_policy).Statement[0].Condition.StringEquals["aws:RequestTag/kubernetes-service-account"] == var.service_account
    error_message = "Trust must bind the cluster."
  }
  assert {
    condition     = toset(jsondecode(aws_iam_role_policy.secrets.policy).Statement[0].Action) == toset(["secretsmanager:GetSecretValue", "secretsmanager:DescribeSecret"]) && jsonencode(jsondecode(aws_iam_role_policy.secrets.policy).Statement[0].Resource) == jsonencode(var.secret_arns)
    error_message = "Secret policy must use exact ARNs."
  }
}
