resource "aws_iam_role" "node" {
  name               = "${var.cluster_name}-bootstrap-node"
  assume_role_policy = jsonencode({ Version = "2012-10-17", Statement = [{ Effect = "Allow", Principal = { Service = "ec2.amazonaws.com" }, Action = "sts:AssumeRole" }] })
}
resource "aws_iam_role_policy_attachment" "node" {
  for_each   = toset(["AmazonEKSWorkerNodePolicy", "AmazonEKS_CNI_Policy", "AmazonEC2ContainerRegistryPullOnly"])
  role       = aws_iam_role.node.name
  policy_arn = "arn:aws:iam::aws:policy/${each.key}"
}
resource "aws_launch_template" "bootstrap" {
  name_prefix            = "${var.cluster_name}-bootstrap-"
  update_default_version = true
  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = 1
  }
  block_device_mappings {
    device_name = "/dev/xvda"
    ebs {
      volume_size           = 30
      volume_type           = "gp3"
      encrypted             = true
      delete_on_termination = true
    }
  }
}
# The cluster disables self-managed add-ons, so networking must exist before nodes join.
resource "aws_eks_addon" "before_nodes" {
  for_each = {
    vpc-cni                = var.addon_versions.vpc_cni
    kube-proxy             = var.addon_versions.kube_proxy
    eks-pod-identity-agent = var.addon_versions.pod_identity_agent
  }
  cluster_name                = var.cluster_name
  addon_name                  = each.key
  addon_version               = each.value
  resolve_conflicts_on_create = "OVERWRITE"
  resolve_conflicts_on_update = "OVERWRITE"
}
resource "aws_eks_node_group" "bootstrap" {
  cluster_name    = var.cluster_name
  node_group_name = "bootstrap"
  node_role_arn   = aws_iam_role.node.arn
  subnet_ids      = var.private_subnet_ids
  version         = var.kubernetes_version
  ami_type        = "AL2023_x86_64_STANDARD"
  capacity_type   = "ON_DEMAND"
  instance_types  = var.instance_types
  scaling_config {
    min_size     = var.bootstrap_size
    desired_size = var.bootstrap_size
    max_size     = var.bootstrap_size + 1
  }
  update_config { max_unavailable = 1 }
  launch_template {
    id      = aws_launch_template.bootstrap.id
    version = aws_launch_template.bootstrap.latest_version
  }
  # Only tolerating system controllers land here; workloads go to Karpenter capacity.
  taint {
    key    = "CriticalAddonsOnly"
    value  = "true"
    effect = "NO_SCHEDULE"
  }
  depends_on = [aws_iam_role_policy_attachment.node, aws_eks_addon.before_nodes]
}
# CoreDNS needs a schedulable node before the add-on reports active.
resource "aws_eks_addon" "coredns" {
  cluster_name                = var.cluster_name
  addon_name                  = "coredns"
  addon_version               = var.addon_versions.coredns
  resolve_conflicts_on_create = "OVERWRITE"
  resolve_conflicts_on_update = "OVERWRITE"
  depends_on                  = [aws_eks_node_group.bootstrap]
}
