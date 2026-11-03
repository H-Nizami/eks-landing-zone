variable "name" {
  type    = string
  default = "example-eks"
}
variable "region" {
  type    = string
  default = "us-east-1"
}
variable "account_id" {
  type    = string
  default = "000000000000"
  validation {
    condition     = can(regex("^[0-9]{12}$", var.account_id))
    error_message = "Provide a 12-digit account ID."
  }
}
variable "availability_zones" {
  type    = list(string)
  default = ["us-east-1a", "us-east-1b", "us-east-1c"]
  validation {
    condition     = length(var.availability_zones) == 3 && length(distinct(var.availability_zones)) == 3 && alltrue([for az in var.availability_zones : startswith(az, var.region) && can(regex("^[a-z]{2}-[a-z]+-[0-9]+[a-z]$", az))])
    error_message = "Provide three distinct AZs in the selected region."
  }
}
variable "vpc_cidr" {
  type    = string
  default = "10.40.0.0/16"
}
variable "single_nat" {
  type    = bool
  default = false
}
variable "kubernetes_version" {
  type    = string
  default = "1.34"
}
variable "operator_role_arn" {
  type    = string
  default = "arn:aws:iam::000000000000:role/eks-operator"
}
variable "kms_admin_role_arn" {
  type    = string
  default = "arn:aws:iam::000000000000:role/kms-admin"
}
variable "enable_pod_identity" {
  type    = bool
  default = false
}
variable "namespace" {
  type    = string
  default = "external-secrets"
}
variable "service_account" {
  type    = string
  default = "external-secrets"
}
variable "secret_arns" {
  type    = list(string)
  default = []
  validation {
    condition     = !var.enable_pod_identity || length(var.secret_arns) > 0
    error_message = "Supply exact secret ARNs when Pod Identity is enabled."
  }
}
