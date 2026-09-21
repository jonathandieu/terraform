variable "name" {
  description = "Cluster name — used as prefix for all resources (e.g. dieubernetes-do-main-nyc3)"
  type        = string
}

variable "region" {
  description = "DigitalOcean region slug"
  type        = string
  validation {
    condition = contains([
      "nyc1", "nyc3", "ams3", "sfo3", "sgp1", "lon1", "fra1", "tor1", "blr1", "syd1", "atl1"
    ], var.region)
    error_message = "Must be a valid DigitalOcean region slug."
  }
}

variable "node_size" {
  description = "Droplet size slug for worker nodes"
  type        = string
  default     = "s-2vcpu-4gb"
}

variable "min_nodes" {
  description = "Minimum nodes in the autoscaling pool"
  type        = number
  default     = 1
}

variable "max_nodes" {
  description = "Maximum nodes in the autoscaling pool"
  type        = number
  default     = 3
  validation {
    condition     = var.max_nodes >= var.min_nodes
    error_message = "max_nodes must be >= min_nodes."
  }
}

variable "kubernetes_version_prefix" {
  description = "Kubernetes minor version to track (e.g. '1.33') — latest patch is always used"
  type        = string
  default     = "1.33"
}

variable "project_description" {
  description = "Description for the DigitalOcean project grouping these resources"
  type        = string
  default     = "dieubernetes cluster"
}
