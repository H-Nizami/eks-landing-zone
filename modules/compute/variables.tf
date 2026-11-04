variable "cluster_name" {
  type = string
  validation {
    condition     = can(regex("^[a-z][a-z0-9-]{0,29}[a-z0-9]$", var.cluster_name))
    error_message = "Cluster name must be a lowercase AWS-safe label."
  }
}
variable "kubernetes_version" { type = string }
variable "private_subnet_ids" {
  type = list(string)
  validation {
    condition     = length(var.private_subnet_ids) >= 2
    error_message = "Bootstrap nodes need at least two private subnets."
  }
}
variable "instance_types" {
  type    = list(string)
  default = ["m7i.large"]
}
variable "bootstrap_size" {
  description = "Fixed node count for the bootstrap group; Karpenter provisions all other capacity."
  type        = number
  default     = 2
  validation {
    condition     = var.bootstrap_size >= 2
    error_message = "Run at least two bootstrap nodes so Karpenter and CoreDNS survive a node loss."
  }
}
variable "addon_versions" {
  description = "Exact EKS add-on versions. No add-on floats to the AWS default."
  type = object({
    vpc_cni            = string
    kube_proxy         = string
    coredns            = string
    pod_identity_agent = string
  })
  validation {
    condition     = alltrue([for version in values(var.addon_versions) : can(regex("^v[0-9]+\\.[0-9]+\\.[0-9]+(-minimal)?-eksbuild\\.[0-9]+$", version))])
    error_message = "Pin each add-on to an exact vX.Y.Z-eksbuild.N version."
  }
}
