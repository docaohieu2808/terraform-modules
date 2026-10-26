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
  description = "GCP zone"
  type        = string
  default     = "us-central1-a"
}

variable "env" {
  description = "Environment name (dev, staging, prod)"
  type        = string
  default     = "dev"
}

variable "credentials_file" {
  description = "Path to GCP service account JSON credentials file"
  type        = string
  default     = ""
}

variable "subnet_cidr" {
  description = "CIDR block for the main subnet"
  type        = string
  default     = "10.10.0.0/24"
}

variable "machine_type" {
  description = "Compute instance machine type"
  type        = string
  default     = "e2-medium"
}

variable "disk_size_gb" {
  description = "Boot disk size in GB"
  type        = number
  default     = 20
}

variable "ssh_source_ranges" {
  description = "IP ranges allowed SSH access"
  type        = list(string)
  default     = ["10.0.0.0/8", "172.16.0.0/12", "192.168.0.0/16"]
}

variable "startup_script" {
  description = "Startup script for compute instances"
  type        = string
  default     = ""
}
variable "ssh_public_key" {
  description = "Optional '<user>:<public key>' line for instance metadata; set via TF_VAR_ssh_public_key (never commit a real one)"
  type        = string
  default     = ""
}
