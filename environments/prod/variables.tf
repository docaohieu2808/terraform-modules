variable "project_id" {
  description = "GCP project ID"
  type        = string
}

variable "region" {
  description = "GCP region"
  type        = string
  default     = "us-central1"
}

variable "zone" {
  description = "GCP zone for zonal resources"
  type        = string
  default     = "us-central1-a"
}

variable "env" {
  description = "Environment name"
  type        = string
  default     = "prod"
}

variable "credentials_file" {
  description = "Path to GCP service account JSON credentials file"
  type        = string
  default     = ""
}

variable "subnet_cidr" {
  description = "CIDR block for the main subnet"
  type        = string
  default     = "10.30.0.0/24"
}

variable "gke_pods_cidr" {
  description = "CIDR block for the GKE pods subnet"
  type        = string
  default     = "10.31.0.0/16"
}

variable "machine_type" {
  description = "Compute instance machine type"
  type        = string
  default     = "e2-standard-4"
}

variable "disk_size_gb" {
  description = "Boot disk size in GB"
  type        = number
  default     = 100
}

variable "gke_machine_type" {
  description = "GKE node pool machine type"
  type        = string
  default     = "e2-standard-4"
}

variable "gke_zones" {
  description = "Zones for GKE node pools"
  type        = list(string)
  default     = ["us-central1-a", "us-central1-b", "us-central1-c"]
}

variable "gke_min_nodes" {
  description = "Minimum nodes per zone in GKE node pool"
  type        = number
  default     = 1
}

variable "gke_max_nodes" {
  description = "Maximum nodes per zone in GKE node pool"
  type        = number
  default     = 5
}

variable "ssh_source_ranges" {
  description = "IP ranges allowed SSH access (restrict in prod)"
  type        = list(string)
  default     = ["10.0.0.0/8"]
}

variable "startup_script" {
  description = "Startup script for compute instances"
  type        = string
  default     = ""
}
