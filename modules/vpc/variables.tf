variable "name" {
  type = string
  validation {
    condition     = can(regex("^[a-z][a-z0-9-]{0,29}[a-z0-9]$", var.name))
    error_message = "Name must be a lowercase AWS-safe label of 2 to 31 characters."
  }
}
variable "vpc_cidr" {
  type = string
  validation {
    condition     = can(cidrhost(var.vpc_cidr, 0)) && can(regex("^([0-9]{1,3}\\.){3}[0-9]{1,3}/(1[6-9]|2[0-4])$", var.vpc_cidr))
    error_message = "Use a valid IPv4 VPC CIDR with /16 through /24."
  }
}
variable "availability_zones" {
  type = list(string)
  validation {
    condition     = length(var.availability_zones) == 3 && length(distinct(var.availability_zones)) == 3 && alltrue([for az in var.availability_zones : can(regex("^[a-z]{2}-[a-z]+-[0-9][a-z]$", az))])
    error_message = "Supply three distinct availability zones."
  }
}
variable "single_nat" {
  type    = bool
  default = false
}
variable "region" { type = string }
variable "account_id" { type = string }
variable "kms_admin_role_arn" { type = string }
