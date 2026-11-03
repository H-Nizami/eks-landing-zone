resource "aws_iam_role" "this" {
  name = "${var.cluster_name}-${var.namespace}-${var.service_account}"
  assume_role_policy = jsonencode({ Version = "2012-10-17", Statement = [{
    Effect = "Allow", Principal = { Service = "pods.eks.amazonaws.com" },
    Action = ["sts:AssumeRole", "sts:TagSession"],
    Condition = { StringEquals = {
      "aws:RequestTag/eks-cluster-arn"            = var.cluster_arn,
      "aws:RequestTag/kubernetes-namespace"       = var.namespace,
      "aws:RequestTag/kubernetes-service-account" = var.service_account
    } }
  }] })
}
resource "aws_iam_role_policy" "secrets" {
  name   = "read-exact-secrets"
  role   = aws_iam_role.this.id
  policy = jsonencode({ Version = "2012-10-17", Statement = [{ Effect = "Allow", Action = ["secretsmanager:GetSecretValue", "secretsmanager:DescribeSecret"], Resource = var.secret_arns }] })
}
resource "aws_eks_pod_identity_association" "this" {
  cluster_name         = var.cluster_name
  namespace            = var.namespace
  service_account      = var.service_account
  role_arn             = aws_iam_role.this.arn
  disable_session_tags = false
}
