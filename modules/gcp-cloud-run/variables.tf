variable "project_id" {
  description = "GCP project ID"
  type        = string
}

variable "region" {
  description = "GCP region for the Cloud Run service"
  type        = string
  default     = "us-central1"
}

variable "service_name" {
  description = "Name of the Cloud Run service"
  type        = string
}

variable "image" {
  description = "Container image URL (e.g. gcr.io/project/image:tag)"
  type        = string
}

variable "container_port" {
  description = "Port the container listens on"
  type        = number
  default     = 8080
}

variable "cpu" {
  description = "CPU limit (e.g. '1', '2', '1000m')"
  type        = string
  default     = "1"
}

variable "memory" {
  description = "Memory limit (e.g. '512Mi', '1Gi')"
  type        = string
  default     = "512Mi"
}

variable "min_instance_count" {
  description = "Minimum number of instances (0 allows scale to zero)"
  type        = number
  default     = 0
}

variable "max_instance_count" {
  description = "Maximum number of instances"
  type        = number
  default     = 10
}

variable "concurrency" {
  description = "Maximum number of requests per container instance"
  type        = number
  default     = 80
}

variable "timeout_seconds" {
  description = "Request timeout in seconds"
  type        = number
  default     = 300
}

variable "env_vars" {
  description = "Environment variables for the container"
  type        = map(string)
  default     = {}
}

variable "secret_env_vars" {
  description = "Secret Manager secrets to inject as env vars"
  type = list(object({
    env_var    = string
    secret     = string
    version    = optional(string, "latest")
  }))
  default = []
}

variable "allow_unauthenticated" {
  description = "Allow unauthenticated (public) access to the service"
  type        = bool
  default     = false
}

variable "service_account_email" {
  description = "Service account email for the Cloud Run service identity"
  type        = string
  default     = ""
}

variable "vpc_connector" {
  description = "VPC connector name for VPC egress"
  type        = string
  default     = ""
}

variable "vpc_egress" {
  description = "VPC egress setting (all-traffic or private-ranges-only)"
  type        = string
  default     = "private-ranges-only"
}

variable "labels" {
  description = "Labels to apply to the service"
  type        = map(string)
  default     = {}
}

variable "ingress" {
  description = "Ingress setting (all, internal, internal-and-cloud-load-balancing)"
  type        = string
  default     = "all"
}
