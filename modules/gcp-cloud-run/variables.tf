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

  validation {
    condition     = var.min_instance_count >= 0
    error_message = "min_instance_count cannot be negative."
  }
}

variable "max_instance_count" {
  description = "Maximum number of instances"
  type        = number
  default     = 10

  validation {
    condition     = var.max_instance_count >= 1 && var.max_instance_count >= var.min_instance_count
    error_message = "max_instance_count must be at least 1 and not below min_instance_count."
  }
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

  validation {
    condition     = var.timeout_seconds >= 1 && var.timeout_seconds <= 3600
    error_message = "timeout_seconds must be between 1 and 3600."
  }
}

variable "env_vars" {
  description = "Environment variables for the container"
  type        = map(string)
  default     = {}
}

variable "secret_env_vars" {
  description = "Secret Manager secrets to inject as env vars"
  type = list(object({
    env_var = string
    secret  = string
    version = optional(string, "latest")
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
  description = "VPC egress setting (ALL_TRAFFIC or PRIVATE_RANGES_ONLY)"
  type        = string
  default     = "PRIVATE_RANGES_ONLY"

  validation {
    condition     = contains(["ALL_TRAFFIC", "PRIVATE_RANGES_ONLY"], var.vpc_egress)
    error_message = "vpc_egress must be ALL_TRAFFIC or PRIVATE_RANGES_ONLY (Cloud Run v2 API values)."
  }
}

variable "labels" {
  description = "Labels to apply to the service"
  type        = map(string)
  default     = {}
}

variable "ingress" {
  description = "Ingress setting (INGRESS_TRAFFIC_ALL, INGRESS_TRAFFIC_INTERNAL_ONLY or INGRESS_TRAFFIC_INTERNAL_LOAD_BALANCER)"
  type        = string
  default     = "INGRESS_TRAFFIC_ALL"

  validation {
    condition     = contains(["INGRESS_TRAFFIC_ALL", "INGRESS_TRAFFIC_INTERNAL_ONLY", "INGRESS_TRAFFIC_INTERNAL_LOAD_BALANCER"], var.ingress)
    error_message = "ingress must be a Cloud Run v2 value: INGRESS_TRAFFIC_ALL, INGRESS_TRAFFIC_INTERNAL_ONLY or INGRESS_TRAFFIC_INTERNAL_LOAD_BALANCER."
  }
}
