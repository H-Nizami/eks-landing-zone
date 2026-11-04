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
  default = "1.36"
}
variable "bootstrap_instance_types" {
  type    = list(string)
  default = ["m7i.large"]
}
variable "vpc_cni_version" {
  type    = string
  default = "v1.23.2-eksbuild.8"
}
variable "kube_proxy_version" {
  type    = string
  default = "v1.36.0-eksbuild.58"
}
variable "coredns_version" {
  type    = string
  default = "v1.14.7-eksbuild.22"
}
variable "pod_identity_agent_version" {
  description = "Exact add-on version. AWS publishes no public table for it: run aws eks describe-addon-versions --addon-name eks-pod-identity-agent --kubernetes-version 1.36."
  type        = string
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
