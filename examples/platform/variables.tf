variable "cluster_name" {
  type    = string
  default = "example-eks"
}
variable "region" {
  type    = string
  default = "us-east-1"
}
variable "cluster_endpoint" {
  type    = string
  default = "https://example.eks.amazonaws.com"
}
variable "cluster_ca_certificate" {
  type    = string
  default = "ZXhhbXBsZQ=="
}
variable "karpenter_node_role_name" {
  type    = string
  default = "example-eks-karpenter-node"
}
variable "karpenter_queue_name" {
  type    = string
  default = "example-eks-karpenter"
}
variable "node_ami_alias" {
  type    = string
  default = "al2023@v20261031"
}
variable "node_cpu_limit" {
  type    = number
  default = 32
}
variable "policy_action" {
  type    = string
  default = "Deny"
}
variable "enable_secret_store" {
  type    = bool
  default = true
}
