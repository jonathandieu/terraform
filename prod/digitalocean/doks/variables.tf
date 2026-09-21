variable "cluster_name" {
  description = "Name of the DOKS cluster"
  type        = string
  default     = "doks-prod"
}

variable "region" {
  description = "DigitalOcean region for the cluster"
  type        = string
  default     = "nyc3"

  validation {
    condition = contains([
      "nyc1", "nyc3", "ams3", "sfo3", "sgp1", "lon1", "fra1", "tor1", "blr1"
    ], var.region)
    error_message = "Region must be a valid DigitalOcean region."
  }
}

variable "kubernetes_version" {
  description = "Kubernetes version for the cluster"
  type        = string
  default     = "1.33.2"
}

variable "node_pool_name" {
  description = "Name of the node pool"
  type        = string
  default     = "worker-pool"
}

variable "node_size" {
  description = "Size of the nodes (e.g., s-2vcpu-4gb)"
  type        = string
  default     = "s-2vcpu-4gb"
}

variable "node_count" {
  description = "Number of nodes in the pool"
  type        = number
  default     = 2
}


