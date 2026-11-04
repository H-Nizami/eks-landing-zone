# AWS resources for Karpenter 1.15, derived from the upstream getting-started CloudFormation template.
locals {
  namespace       = "karpenter"
  service_account = "karpenter"
  cluster_tag     = "kubernetes.io/cluster/${var.cluster_name}"
  ec2_arn         = "arn:aws:ec2:${var.region}"
  profile_arn     = "arn:aws:iam::${var.account_id}:instance-profile/*"
  tagged_resources = [
    "${local.ec2_arn}:*:fleet/*",
    "${local.ec2_arn}:*:instance/*",
    "${local.ec2_arn}:*:volume/*",
    "${local.ec2_arn}:*:network-interface/*",
    "${local.ec2_arn}:*:launch-template/*",
    "${local.ec2_arn}:*:spot-instances-request/*",
  ]
  owned_nodepool = {
    StringEquals = { "aws:ResourceTag/${local.cluster_tag}" = "owned" }
    StringLike   = { "aws:ResourceTag/karpenter.sh/nodepool" = "*" }
  }
  profile_request_tags = {
    "aws:RequestTag/${local.cluster_tag}"          = "owned"
    "aws:RequestTag/eks:eks-cluster-name"          = var.cluster_name
    "aws:RequestTag/topology.kubernetes.io/region" = var.region
  }
  profile_resource_tags = {
    "aws:ResourceTag/${local.cluster_tag}"          = "owned"
    "aws:ResourceTag/topology.kubernetes.io/region" = var.region
  }
  controller_policies = {
    node-lifecycle = [
      {
        Sid    = "AllowScopedEC2InstanceAccessActions"
        Effect = "Allow"
        Action = ["ec2:RunInstances", "ec2:CreateFleet"]
        Resource = [
          "${local.ec2_arn}::image/*",
          "${local.ec2_arn}::snapshot/*",
          "${local.ec2_arn}:*:security-group/*",
          "${local.ec2_arn}:*:subnet/*",
          "${local.ec2_arn}:*:capacity-reservation/*",
          "${local.ec2_arn}:*:placement-group/*",
        ]
      },
      {
        Sid       = "AllowScopedEC2LaunchTemplateAccessActions"
        Effect    = "Allow"
        Action    = ["ec2:RunInstances", "ec2:CreateFleet"]
        Resource  = "${local.ec2_arn}:*:launch-template/*"
        Condition = local.owned_nodepool
      },
      {
        Sid      = "AllowScopedEC2InstanceActionsWithTags"
        Effect   = "Allow"
        Action   = ["ec2:RunInstances", "ec2:CreateFleet", "ec2:CreateLaunchTemplate"]
        Resource = local.tagged_resources
        Condition = {
          StringEquals = {
            "aws:RequestTag/${local.cluster_tag}" = "owned"
            "aws:RequestTag/eks:eks-cluster-name" = var.cluster_name
          }
          StringLike = { "aws:RequestTag/karpenter.sh/nodepool" = "*" }
        }
      },
      {
        Sid      = "AllowScopedResourceCreationTagging"
        Effect   = "Allow"
        Action   = "ec2:CreateTags"
        Resource = local.tagged_resources
        Condition = {
          StringEquals = {
            "aws:RequestTag/${local.cluster_tag}" = "owned"
            "aws:RequestTag/eks:eks-cluster-name" = var.cluster_name
            "ec2:CreateAction"                    = ["RunInstances", "CreateFleet", "CreateLaunchTemplate"]
          }
          StringLike = { "aws:RequestTag/karpenter.sh/nodepool" = "*" }
        }
      },
      {
        Sid      = "AllowScopedResourceTagging"
        Effect   = "Allow"
        Action   = "ec2:CreateTags"
        Resource = "${local.ec2_arn}:*:instance/*"
        Condition = merge(local.owned_nodepool, {
          StringEqualsIfExists        = { "aws:RequestTag/eks:eks-cluster-name" = var.cluster_name }
          "ForAllValues:StringEquals" = { "aws:TagKeys" = ["eks:eks-cluster-name", "karpenter.sh/nodeclaim", "Name"] }
        })
      },
      {
        Sid       = "AllowScopedDeletion"
        Effect    = "Allow"
        Action    = ["ec2:TerminateInstances", "ec2:DeleteLaunchTemplate"]
        Resource  = ["${local.ec2_arn}:*:instance/*", "${local.ec2_arn}:*:launch-template/*"]
        Condition = local.owned_nodepool
      },
    ]
    iam-integration = [
      {
        Sid       = "AllowPassingInstanceRole"
        Effect    = "Allow"
        Action    = "iam:PassRole"
        Resource  = aws_iam_role.node.arn
        Condition = { StringEquals = { "iam:PassedToService" = "ec2.amazonaws.com" } }
      },
      {
        Sid      = "AllowScopedInstanceProfileCreationActions"
        Effect   = "Allow"
        Action   = "iam:CreateInstanceProfile"
        Resource = local.profile_arn
        Condition = {
          StringEquals = local.profile_request_tags
          StringLike   = { "aws:RequestTag/karpenter.k8s.aws/ec2nodeclass" = "*" }
        }
      },
      {
        Sid      = "AllowScopedInstanceProfileTagActions"
        Effect   = "Allow"
        Action   = "iam:TagInstanceProfile"
        Resource = local.profile_arn
        Condition = {
          StringEquals = merge(local.profile_resource_tags, local.profile_request_tags)
          StringLike = {
            "aws:ResourceTag/karpenter.k8s.aws/ec2nodeclass" = "*"
            "aws:RequestTag/karpenter.k8s.aws/ec2nodeclass"  = "*"
          }
        }
      },
      {
        Sid      = "AllowScopedInstanceProfileActions"
        Effect   = "Allow"
        Action   = ["iam:AddRoleToInstanceProfile", "iam:RemoveRoleFromInstanceProfile", "iam:DeleteInstanceProfile"]
        Resource = local.profile_arn
        Condition = {
          StringEquals = local.profile_resource_tags
          StringLike   = { "aws:ResourceTag/karpenter.k8s.aws/ec2nodeclass" = "*" }
        }
      },
    ]
    eks-integration = [{
      Sid      = "AllowAPIServerEndpointDiscovery"
      Effect   = "Allow"
      Action   = "eks:DescribeCluster"
      Resource = var.cluster_arn
    }]
    interruption = [{
      Sid      = "AllowInterruptionQueueActions"
      Effect   = "Allow"
      Action   = ["sqs:DeleteMessage", "sqs:GetQueueUrl", "sqs:ReceiveMessage"]
      Resource = aws_sqs_queue.interruption.arn
    }]
    zonal-shift = [{
      Sid       = "AllowZonalShiftStatusReadOnly"
      Effect    = "Allow"
      Action    = "arc-zonal-shift:GetManagedResource"
      Resource  = "*"
      Condition = { StringEquals = { "arc-zonal-shift:ResourceIdentifier" = var.cluster_arn } }
    }]
    resource-discovery = [
      {
        Sid    = "AllowRegionalReadActions"
        Effect = "Allow"
        Action = [
          "ec2:DescribeCapacityReservations",
          "ec2:DescribeImages",
          "ec2:DescribeInstances",
          "ec2:DescribeInstanceStatus",
          "ec2:DescribeInstanceTypeOfferings",
          "ec2:DescribeInstanceTypes",
          "ec2:DescribeLaunchTemplates",
          "ec2:DescribePlacementGroups",
          "ec2:DescribeSecurityGroups",
          "ec2:DescribeSpotPriceHistory",
          "ec2:DescribeSubnets",
        ]
        Resource  = "*"
        Condition = { StringEquals = { "aws:RequestedRegion" = var.region } }
      },
      {
        Sid      = "AllowSSMReadActions"
        Effect   = "Allow"
        Action   = "ssm:GetParameter"
        Resource = "arn:aws:ssm:${var.region}::parameter/aws/service/*"
      },
      {
        Sid      = "AllowPricingReadActions"
        Effect   = "Allow"
        Action   = "pricing:GetProducts"
        Resource = "*"
      },
      {
        Sid      = "AllowUnscopedInstanceProfileListAction"
        Effect   = "Allow"
        Action   = "iam:ListInstanceProfiles"
        Resource = "*"
      },
      {
        Sid      = "AllowInstanceProfileReadActions"
        Effect   = "Allow"
        Action   = "iam:GetInstanceProfile"
        Resource = local.profile_arn
      },
    ]
  }
  interruption_events = {
    health       = { source = "aws.health", detail_type = "AWS Health Event" }
    spot         = { source = "aws.ec2", detail_type = "EC2 Spot Instance Interruption Warning" }
    rebalance    = { source = "aws.ec2", detail_type = "EC2 Instance Rebalance Recommendation" }
    state-change = { source = "aws.ec2", detail_type = "EC2 Instance State-change Notification" }
    reservation  = { source = "aws.ec2", detail_type = "EC2 Capacity Reservation Instance Interruption Warning" }
  }
}
resource "aws_iam_role" "node" {
  name               = "${var.cluster_name}-karpenter-node"
  assume_role_policy = jsonencode({ Version = "2012-10-17", Statement = [{ Effect = "Allow", Principal = { Service = "ec2.amazonaws.com" }, Action = "sts:AssumeRole" }] })
}
resource "aws_iam_role_policy_attachment" "node" {
  for_each   = toset(["AmazonEKSWorkerNodePolicy", "AmazonEKS_CNI_Policy", "AmazonEC2ContainerRegistryPullOnly", "AmazonSSMManagedInstanceCore"])
  role       = aws_iam_role.node.name
  policy_arn = "arn:aws:iam::aws:policy/${each.key}"
}
resource "aws_eks_access_entry" "node" {
  cluster_name  = var.cluster_name
  principal_arn = aws_iam_role.node.arn
  type          = "EC2_LINUX"
}
resource "aws_iam_role" "controller" {
  name = "${var.cluster_name}-karpenter-controller"
  assume_role_policy = jsonencode({ Version = "2012-10-17", Statement = [{
    Effect = "Allow", Principal = { Service = "pods.eks.amazonaws.com" },
    Action = ["sts:AssumeRole", "sts:TagSession"],
    Condition = { StringEquals = {
      "aws:RequestTag/eks-cluster-arn"            = var.cluster_arn,
      "aws:RequestTag/kubernetes-namespace"       = local.namespace,
      "aws:RequestTag/kubernetes-service-account" = local.service_account
    } }
  }] })
}
resource "aws_iam_policy" "controller" {
  for_each = toset(keys(local.controller_policies))
  name     = "${var.cluster_name}-karpenter-${each.key}"
  policy   = jsonencode({ Version = "2012-10-17", Statement = local.controller_policies[each.key] })
}
resource "aws_iam_role_policy_attachment" "controller" {
  for_each   = toset(keys(local.controller_policies))
  role       = aws_iam_role.controller.name
  policy_arn = aws_iam_policy.controller[each.key].arn
}
resource "aws_eks_pod_identity_association" "controller" {
  cluster_name    = var.cluster_name
  namespace       = local.namespace
  service_account = local.service_account
  role_arn        = aws_iam_role.controller.arn
}
resource "aws_sqs_queue" "interruption" {
  name                      = "${var.cluster_name}-karpenter"
  message_retention_seconds = 300
  sqs_managed_sse_enabled   = true
}
resource "aws_sqs_queue_policy" "interruption" {
  queue_url = aws_sqs_queue.interruption.id
  policy = jsonencode({ Version = "2012-10-17", Id = "EC2InterruptionPolicy", Statement = [
    { Sid = "AllowEventDelivery", Effect = "Allow", Principal = { Service = ["events.amazonaws.com", "sqs.amazonaws.com"] }, Action = "sqs:SendMessage", Resource = aws_sqs_queue.interruption.arn },
    { Sid = "DenyHTTP", Effect = "Deny", Principal = "*", Action = "sqs:*", Resource = aws_sqs_queue.interruption.arn, Condition = { Bool = { "aws:SecureTransport" = "false" } } },
  ] })
}
resource "aws_cloudwatch_event_rule" "interruption" {
  for_each      = local.interruption_events
  name          = "${var.cluster_name}-karpenter-${each.key}"
  event_pattern = jsonencode({ source = [each.value.source], detail-type = [each.value.detail_type] })
}
resource "aws_cloudwatch_event_target" "interruption" {
  for_each = local.interruption_events
  rule     = aws_cloudwatch_event_rule.interruption[each.key].name
  arn      = aws_sqs_queue.interruption.arn
}
resource "aws_ec2_tag" "subnet_discovery" {
  for_each    = var.private_subnet_ids
  resource_id = each.value
  key         = "karpenter.sh/discovery"
  value       = var.cluster_name
}
resource "aws_ec2_tag" "security_group_discovery" {
  resource_id = var.cluster_security_group_id
  key         = "karpenter.sh/discovery"
  value       = var.cluster_name
}
