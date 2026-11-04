variable "cluster_name" {
  type = string
  validation {
    condition     = can(regex("^[a-z][a-z0-9-]{0,29}[a-z0-9]$", var.cluster_name))
    error_message = "Cluster name must be a lowercase AWS-safe label."
  }
}
variable "region" {
  type = string
  validation {
    condition     = can(regex("^[a-z]{2}-[a-z]+-[0-9]+$", var.region))
    error_message = "Provide a commercial AWS region."
  }
}
variable "karpenter_node_role_name" { type = string }
variable "karpenter_queue_name" { type = string }
variable "node_ami_alias" {
  description = "Exact EKS-optimized AMI alias for Karpenter nodes."
  type        = string
  validation {
    condition     = can(regex("^al2023@v[0-9]{8}$", var.node_ami_alias))
    error_message = "Pin an exact AMI alias such as al2023@v20261031, never @latest."
  }
}
variable "node_cpu_limit" {
  description = "Upper bound on total vCPUs Karpenter may provision."
  type        = number
  default     = 32
  validation {
    condition     = var.node_cpu_limit > 0 && var.node_cpu_limit <= 1000
    error_message = "Set a CPU limit between 1 and 1000."
  }
}
variable "policy_action" {
  description = "Kyverno response to a policy violation."
  type        = string
  default     = "Deny"
  validation {
    condition     = contains(["Deny", "Audit"], var.policy_action)
    error_message = "Use Deny or Audit."
  }
}
variable "enable_secret_store" {
  description = "Create the cluster secret store. Requires the External Secrets Pod Identity role from the foundation."
  type        = bool
  default     = true
}
