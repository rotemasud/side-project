variable "region" {
  description = "AWS region"
  type        = string
  default     = "il-central-1"
}

variable "vpc_name" {
  description = "Name for the VPC"
  type        = string
  default     = "my-vpc"
}

variable "vpc_cidr" {
  description = "VPC CIDR"
  type        = string
  default     = "10.0.0.0/16"
}

variable "vpc_private_subnets" {
  description = "Private subnet CIDRs"
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
}

variable "vpc_public_subnets" {
  description = "Public subnet CIDRs"
  type        = list(string)
  default     = ["10.0.4.0/24", "10.0.5.0/24", "10.0.6.0/24"]
}

variable "vpc_enable_nat_gateway" {
  description = "Enable NAT gateway"
  type        = bool
  default     = true
}

variable "vpc_single_nat_gateway" {
  description = "Single NAT gateway"
  type        = bool
  default     = true
}

variable "vpc_enable_dns_hostnames" {
  description = "Enable DNS hostnames"
  type        = bool
  default     = true
}

variable "cluster_name" {
  description = "EKS cluster name"
  type        = string
  default     = "side-project-eks"
}

variable "cluster_version" {
  description = "EKS cluster version"
  type        = string
  default     = "1.29"
}

variable "node_group_instance_types" {
  description = "Node group instance types"
  type        = list(string)
  default     = ["t3.small"]
}

variable "node_group_min_size" {
  description = "Node group min size"
  type        = number
  default     = 1
}

variable "node_group_max_size" {
  description = "Node group max size"
  type        = number
  default     = 3
}

variable "node_group_desired_size" {
  description = "Node group desired size"
  type        = number
  default     = 2
}

variable "karpenter_enabled" {
  description = "Install Karpenter via Helm"
  type        = bool
  default     = true
}

variable "karpenter_values_file" {
  description = "Path to Karpenter Helm values.yaml"
  type        = string
  default     = null
}

variable "istio_enabled" {
  description = "Install Istio via Helm"
  type        = bool
  default     = false
}

variable "istio_namespace" {
  description = "Namespace for Istio components"
  type        = string
  default     = "istio-system"
}

variable "istio_repository" {
  description = "Helm repository for Istio charts"
  type        = string
  default     = "https://istio-release.storage.googleapis.com/charts"
}

variable "istiod_values_file" {
  description = "Optional values file for istiod chart"
  type        = string
  default     = null
}

variable "istio_ingress_enabled" {
  description = "Install Istio Ingress Gateway"
  type        = bool
  default     = true
}

variable "istio_ingress_values_file" {
  description = "Optional values file for Istio ingress gateway chart"
  type        = string
  default     = null
}

variable "argocd_enabled" {
  description = "Install Argo CD via Helm"
  type        = bool
  default     = false
}

variable "argocd_namespace" {
  description = "Namespace for Argo CD"
  type        = string
  default     = "argocd"
}

variable "argocd_repository" {
  description = "Helm repository for Argo CD chart"
  type        = string
  default     = "https://argoproj.github.io/argo-helm"
}

variable "argocd_values_file" {
  description = "Optional values file for Argo CD chart"
  type        = string
  default     = null
}
