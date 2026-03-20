terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = ">= 5.0"
    }
  }
}

resource "google_dns_managed_zone" "this" {
  project     = var.project_id
  name        = var.zone_name
  dns_name    = var.dns_name
  description = var.description
  visibility  = var.visibility
  labels      = var.labels

  dynamic "private_visibility_config" {
    for_each = var.visibility == "private" && length(var.private_visibility_networks) > 0 ? [1] : []
    content {
      dynamic "networks" {
        for_each = var.private_visibility_networks
        content {
          network_url = networks.value
        }
      }
    }
  }

  dynamic "dnssec_config" {
    for_each = var.dnssec_enabled ? [1] : []
    content {
      state = "on"
    }
  }
}

resource "google_dns_record_set" "this" {
  for_each = { for r in var.records : "${r.name}-${r.type}" => r }

  project      = var.project_id
  managed_zone = google_dns_managed_zone.this.name
  name         = each.value.name
  type         = each.value.type
  ttl          = each.value.ttl
  rrdatas      = each.value.rrdatas
}
