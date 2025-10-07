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


