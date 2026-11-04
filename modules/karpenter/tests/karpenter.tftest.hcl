mock_provider "aws" {
  mock_resource "aws_iam_role" { defaults = { arn = "arn:aws:iam::000000000000:role/example-role" } }
  mock_resource "aws_iam_policy" { defaults = { arn = "arn:aws:iam::000000000000:policy/example-policy" } }
  mock_resource "aws_sqs_queue" { defaults = { arn = "arn:aws:sqs:us-east-1:000000000000:example", id = "https://sqs.us-east-1.amazonaws.com/000000000000/example" } }
}
variables {
  cluster_name              = "example-eks"
  cluster_arn               = "arn:aws:eks:us-east-1:000000000000:cluster/example-eks"
  region                    = "us-east-1"
  account_id                = "000000000000"
  cluster_security_group_id = "sg-11111111"
  private_subnet_ids = {
    us-east-1a = "subnet-11111111"
    us-east-1b = "subnet-22222222"
  }
}
run "controller_identity_is_scoped" {
  command = plan
  assert {
    condition     = aws_eks_pod_identity_association.controller.namespace == "karpenter" && aws_eks_pod_identity_association.controller.service_account == "karpenter"
    error_message = "The controller role must bind to the karpenter service account only."
  }
  assert {
    condition     = jsondecode(aws_iam_role.controller.assume_role_policy).Statement[0].Condition.StringEquals["aws:RequestTag/eks-cluster-arn"] == var.cluster_arn
    error_message = "The controller trust policy must be limited to this cluster."
  }
  assert {
    condition     = alltrue([for statement in jsondecode(aws_iam_policy.controller["node-lifecycle"].policy).Statement : statement.Resource != "*"])
    error_message = "Node lifecycle statements must not use a wildcard resource."
  }
  assert {
    condition     = strcontains(aws_iam_policy.controller["node-lifecycle"].policy, "aws:ResourceTag/kubernetes.io/cluster/example-eks")
    error_message = "Instance deletion must be limited to nodes owned by this cluster."
  }
}
run "node_access_uses_ec2_linux_entry" {
  command = plan
  assert {
    condition     = aws_eks_access_entry.node.type == "EC2_LINUX"
    error_message = "Karpenter nodes need an EC2_LINUX access entry."
  }
  assert {
    condition     = length(aws_iam_role_policy_attachment.controller) == 6
    error_message = "All controller policy groups must attach to the controller role."
  }
}
run "interruption_handling" {
  command = plan
  assert {
    condition     = aws_sqs_queue.interruption.sqs_managed_sse_enabled && aws_sqs_queue.interruption.message_retention_seconds == 300
    error_message = "The interruption queue must be encrypted with short retention."
  }
  assert {
    condition     = length(aws_cloudwatch_event_rule.interruption) == 5 && length(aws_cloudwatch_event_target.interruption) == 5
    error_message = "Every interruption event type needs a rule and a target."
  }
}
run "discovery_tags" {
  command = plan
  assert {
    condition     = length(aws_ec2_tag.subnet_discovery) == 2 && alltrue([for tag in aws_ec2_tag.subnet_discovery : tag.key == "karpenter.sh/discovery" && tag.value == var.cluster_name])
    error_message = "Each private subnet must carry the discovery tag."
  }
  assert {
    condition     = aws_ec2_tag.security_group_discovery.resource_id == var.cluster_security_group_id
    error_message = "The cluster security group must carry the discovery tag."
  }
}
run "reject_mismatched_cluster_arn" {
  command = plan
  variables { cluster_arn = "arn:aws:eks:us-east-1:000000000000:cluster/other" }
  expect_failures = [var.cluster_arn]
}
