variable "cluster_name" {
  type = string
  validation {
    condition     = can(regex("^[a-z][a-z0-9-]{0,29}[a-z0-9]$", var.cluster_name))
    error_message = "Cluster name must be a lowercase AWS-safe label."
  }
}
variable "cluster_arn" {
  type = string
  validation {
    condition     = var.cluster_arn == "arn:aws:eks:${var.region}:${var.account_id}:cluster/${var.cluster_name}"
    error_message = "Cluster ARN must match the supplied cluster, region and account."
  }
}
variable "region" {
  type = string
  validation {
    condition     = can(regex("^[a-z]{2}-[a-z]+-[0-9]+$", var.region))
    error_message = "Provide a commercial AWS region."
  }
}
variable "account_id" {
  type = string
  validation {
    condition     = can(regex("^[0-9]{12}$", var.account_id))
    error_message = "Provide a 12-digit account ID."
  }
}
variable "namespace" {
  type = string
  validation {
    condition     = can(regex("^[a-z0-9]([-a-z0-9]*[a-z0-9])?$", var.namespace)) && length(var.namespace) <= 63
    error_message = "Namespace must be a Kubernetes DNS label."
  }
}
variable "service_account" {
  type = string
  validation {
    condition     = can(regex("^[a-z0-9]([-a-z0-9]*[a-z0-9])?$", var.service_account)) && length(var.service_account) <= 63
    error_message = "Service account must be a Kubernetes DNS label."
  }
}
variable "secret_arns" {
  type = list(string)
  validation {
    condition     = length(var.secret_arns) > 0 && length(distinct(var.secret_arns)) == length(var.secret_arns) && alltrue([for arn in var.secret_arns : can(regex("^arn:aws:secretsmanager:${var.region}:${var.account_id}:secret:[A-Za-z0-9/_+=.@-]+-[A-Za-z0-9]{6}$", arn)) && !strcontains(arn, "*")])
    error_message = "Supply exact same-region, same-account Secrets Manager ARNs without wildcards."
  }
}
