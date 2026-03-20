variable "project_id" {
  description = "GCP project ID"
  type        = string
}

variable "region" {
  description = "GCP region for the cluster"
  type        = string
  default     = "us-central1"
}

variable "cluster_name" {
  description = "Name of the GKE cluster"
  type        = string
}

variable "network" {
  description = "VPC network name or self_link"
  type        = string
  default     = "default"
}

variable "subnetwork" {
  description = "Subnetwork name or self_link"
  type        = string
  default     = ""
}

variable "kubernetes_version" {
  description = "Kubernetes version (leave empty for latest stable)"
  type        = string
  default     = ""
}

variable "release_channel" {
  description = "GKE release channel (RAPID, REGULAR, STABLE, UNSPECIFIED)"
  type        = string
  default     = "REGULAR"
}

variable "regional" {
  description = "Whether to create a regional (true) or zonal (false) cluster"
  type        = bool
  default     = true
}

variable "zones" {
  description = "Zones for zonal cluster or node locations for regional cluster"
  type        = list(string)
  default     = []
}

variable "enable_private_nodes" {
  description = "Enable private nodes (no public IPs on nodes)"
  type        = bool
  default     = false
}

variable "enable_private_endpoint" {
  description = "Enable private endpoint (master API only accessible from VPC)"
  type        = bool
  default     = false
}

variable "master_ipv4_cidr_block" {
  description = "CIDR block for the master network (required for private clusters)"
  type        = string
  default     = "172.16.0.0/28"
}

variable "master_authorized_networks" {
  description = "List of CIDR blocks authorized to access the master"
  type = list(object({
    cidr_block   = string
    display_name = string
  }))
  default = []
}

variable "pods_ipv4_cidr_block" {
  description = "Secondary IP range for pods"
  type        = string
  default     = ""
}

variable "services_ipv4_cidr_block" {
  description = "Secondary IP range for services"
  type        = string
  default     = ""
}

variable "node_pools" {
  description = "List of node pool configurations"
  type = list(object({
    name               = string
    machine_type       = optional(string, "e2-standard-2")
    disk_size_gb       = optional(number, 50)
    disk_type          = optional(string, "pd-balanced")
    image_type         = optional(string, "COS_CONTAINERD")
    min_node_count     = optional(number, 1)
    max_node_count     = optional(number, 3)
    initial_node_count = optional(number, 1)
    preemptible        = optional(bool, false)
    spot               = optional(bool, false)
    labels             = optional(map(string), {})
    tags               = optional(list(string), [])
    taints = optional(list(object({
      key    = string
      value  = string
      effect = string
    })), [])
    oauth_scopes = optional(list(string), ["https://www.googleapis.com/auth/cloud-platform"])
  }))
  default = [
    {
      name         = "default-pool"
      machine_type = "e2-standard-2"
    }
  ]
}

variable "enable_autopilot" {
  description = "Enable GKE Autopilot mode"
  type        = bool
  default     = false
}

variable "deletion_protection" {
  description = "Enable deletion protection on the cluster"
  type        = bool
  default     = false
}

variable "labels" {
  description = "Labels to apply to the cluster"
  type        = map(string)
  default     = {}
}

variable "enable_workload_identity" {
  description = "Enable Workload Identity"
  type        = bool
  default     = true
}

variable "enable_http_load_balancing" {
  description = "Enable HTTP load balancing addon"
  type        = bool
  default     = true
}

variable "enable_horizontal_pod_autoscaling" {
  description = "Enable horizontal pod autoscaling addon"
  type        = bool
  default     = true
}
