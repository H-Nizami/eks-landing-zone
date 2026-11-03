variable "name" {
  type = string
  validation {
    condition     = can(regex("^[A-Za-z][A-Za-z0-9-]{0,99}$", var.name))
    error_message = "Use a valid EKS cluster name."
  }
}
variable "private_subnet_ids" {
  type = list(string)
  validation {
    condition     = length(var.private_subnet_ids) >= 2
    error_message = "EKS needs at least two private subnets."
  }
}
variable "region" {
  type = string
  validation {
    condition     = can(regex("^[a-z]{2}-[a-z]+-[0-9]$", var.region))
    error_message = "Supply an AWS region."
  }
}
variable "account_id" {
  type = string
  validation {
    condition     = can(regex("^[0-9]{12}$", var.account_id))
    error_message = "Supply a 12-digit account ID."
  }
}
variable "kubernetes_version" { type = string }
variable "operator_role_arn" {
  type = string
  validation {
    condition     = can(regex("^arn:aws:iam::${var.account_id}:role/[A-Za-z0-9+=,.@_/-]+$", var.operator_role_arn))
    error_message = "Supply a commercial-partition IAM role ARN."
  }
}
variable "kms_admin_role_arn" {
  type = string
  validation {
    condition     = can(regex("^arn:aws:iam::${var.account_id}:role/[A-Za-z0-9+=,.@_/-]+$", var.kms_admin_role_arn))
    error_message = "Supply a commercial-partition IAM role ARN."
  }
}
