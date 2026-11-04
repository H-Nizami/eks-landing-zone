# Narrow scanner exceptions

## `CKV2_AWS_19`: NAT gateway EIPs

`CKV2_AWS_19` expects VPC EIPs to attach to EC2 instances. The VPC module
allocates each EIP for an `aws_nat_gateway` in the same availability zone, so
attaching it to an instance would be wrong. The inline skip applies only to
`aws_eip.nat`; no other check or resource is suppressed. The NAT attachment is
asserted in the mock-plan network tests.

## `CKV_AWS_339`: supported Kubernetes version

Checkov 3.3.30 keeps a fixed list of supported EKS versions that predates Kubernetes 1.36. AWS lists 1.36 in standard support until August 2, 2027. The inline skip applies only to `aws_eks_cluster.this`. Remove it when an upgraded Checkov recognizes the version.
