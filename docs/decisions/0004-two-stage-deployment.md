# ADR 0004: Deploy in two stages

Status: accepted, 2026-11-04.

The API endpoint is private, so a Helm provider cannot reach it from a machine outside the VPC, and a single root would need the cluster to exist before its provider can be configured. The foundation root therefore uses only the AWS provider. It creates the network, cluster, bootstrap nodes, core add-ons and Karpenter's AWS resources. The platform root uses only the Helm provider and runs afterwards from a machine with a network path to the API.

Local charts hold the NodePool, EC2NodeClass, ClusterSecretStore and Kyverno policies. Helm can install them after their CRDs exist, whereas a Kubernetes manifest resource needs those CRDs during planning.

The bootstrap node group is tainted `CriticalAddonsOnly`. Karpenter and CoreDNS tolerate the taint; External Secrets, Kyverno and workloads run on Karpenter capacity. This keeps Karpenter off the nodes it manages.

Kyverno policies use the `ValidatingPolicy` type because Kyverno 1.19 flags the legacy `kyverno.io` policy types as deprecated. Admission runs with three replicas and system namespaces excluded, because the webhook fails closed.

The cost is one more apply step and separate provider locks.
