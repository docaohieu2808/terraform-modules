variable "project_id" {
  description = "GCP project ID"
  type        = string
}

variable "zone_name" {
  description = "Name of the DNS managed zone (resource name, not DNS name)"
  type        = string
}

variable "dns_name" {
  description = "DNS name for the managed zone (must end with a dot, e.g. 'example.com.')"
  type        = string
}

variable "description" {
  description = "Description of the DNS managed zone"
  type        = string
  default     = "Managed by Terraform"
}

variable "visibility" {
  description = "Zone visibility: public or private"
  type        = string
  default     = "public"
}

variable "private_visibility_networks" {
  description = "List of VPC network self_links for private zone visibility"
  type        = list(string)
  default     = []
}

variable "dnssec_enabled" {
  description = "Enable DNSSEC for the zone"
  type        = bool
  default     = false
}

variable "records" {
  description = "DNS records to create in the zone"
  type = list(object({
    name    = string
    type    = string
    ttl     = optional(number, 300)
    rrdatas = list(string)
  }))
  default = []
}

variable "labels" {
  description = "Labels to apply to the DNS zone"
  type        = map(string)
  default     = {}
}
