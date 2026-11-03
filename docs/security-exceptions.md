# Narrow scanner exception

`CKV2_AWS_19` expects VPC EIPs to attach to EC2 instances. The VPC module
allocates each EIP for an `aws_nat_gateway` in the same availability zone, so
attaching it to an instance would be wrong. The inline skip applies only to
`aws_eip.nat`; no other check or resource is suppressed. The NAT attachment is
asserted in the mock-plan network tests.
