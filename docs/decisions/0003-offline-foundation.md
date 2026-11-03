# ADR 0003: Validate the foundation offline first

Status: accepted, 2026-11-02.

The first stage contains VPC, EKS control-plane and optional Pod Identity
modules. Terraform and OpenTofu use the same sources and mock-provider plan
tests. No AWS credentials are needed for these tests. `make up` and `make down`
stay disabled until a bounded deployment and teardown is approved and funded.

This proves planned configuration contracts, not AWS acceptance or runtime
behavior. Compute, the Pod Identity agent, Karpenter, External Secrets and
Kyverno remain later work. A private EKS endpoint also requires an approved
network path for operators and workers before a deployment is useful.
