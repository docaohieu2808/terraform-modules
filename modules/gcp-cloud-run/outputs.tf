output "service_id" {
  description = "The ID of the Cloud Run service"
  value       = google_cloud_run_v2_service.this.id
}

output "service_name" {
  description = "The name of the Cloud Run service"
  value       = google_cloud_run_v2_service.this.name
}

output "service_url" {
  description = "The URL of the Cloud Run service"
  value       = google_cloud_run_v2_service.this.uri
}

output "latest_revision" {
  description = "The name of the latest revision"
  value       = google_cloud_run_v2_service.this.latest_created_revision
}

output "location" {
  description = "The region where the service is deployed"
  value       = google_cloud_run_v2_service.this.location
}
