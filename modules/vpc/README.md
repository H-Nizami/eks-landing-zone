# VPC module

Creates three public and three private subnets from a `/16` to `/24` IPv4 CIDR.
Public subnet indexes are 0–2 and private indexes are 3–5 after adding four prefix
bits. Every private subnet has its own route table. The default uses one NAT gateway
per AZ; `single_nat = true` routes all private subnets through the first AZ and
reduces resilience. Both subnet types disable automatic public IP assignment.

VPC DNS is enabled for a private EKS endpoint. The default security group has no
ingress or egress rules. Flow logs cover all traffic with one-year CloudWatch
retention. This module provisions network resources only; it has no worker nodes.
