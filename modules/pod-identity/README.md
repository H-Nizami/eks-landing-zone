# Pod Identity module

Creates one IAM role and one EKS Pod Identity association for an explicit
cluster, namespace and service account. The role trust restricts the service
and the three Pod Identity request tags. Its policy reads only caller-supplied,
exact, same-account and same-region Secrets Manager ARNs. The secret values are
never managed here.

An association alone cannot deliver credentials. Worker nodes, the EKS Pod
Identity agent, the Kubernetes service account, a controller or workload, and a
supported AWS SDK are required at runtime. Those are later stages.
