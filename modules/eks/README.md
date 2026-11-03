# EKS control plane module

Creates a private-endpoint EKS control plane on caller-supplied private subnets.
It disables automatic creator admin access and grants cluster admin to the
explicit operator IAM role through an access entry. Control-plane logs and
Kubernetes secrets use a rotating customer KMS key. The KMS administrator role
must already exist and be authorized to manage this key. The operator needs a
network path into the VPC to reach the private Kubernetes API.

This module does not create nodes, add-ons, a kubeconfig or a public API endpoint.
