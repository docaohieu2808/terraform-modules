output "zone_id" {
  description = "The ID of the DNS managed zone"
  value       = google_dns_managed_zone.this.id
}

output "zone_name" {
  description = "The resource name of the DNS managed zone"
  value       = google_dns_managed_zone.this.name
}

output "dns_name" {
  description = "The DNS name of the managed zone"
  value       = google_dns_managed_zone.this.dns_name
}

output "name_servers" {
  description = "Name servers assigned to the zone (for public zones)"
  value       = google_dns_managed_zone.this.name_servers
}

output "record_set_ids" {
  description = "Map of record key to record set ID"
  value       = { for k, v in google_dns_record_set.this : k => v.id }
}
