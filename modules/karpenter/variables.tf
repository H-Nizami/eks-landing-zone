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
variable "cluster_security_group_id" { type = string }
variable "private_subnet_ids" {
  description = "Private subnet IDs keyed by availability zone."
  type        = map(string)
  validation {
    condition     = length(var.private_subnet_ids) >= 2
    error_message = "Karpenter needs at least two private subnets."
  }
}
