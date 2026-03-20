output "cluster_id" {
  description = "The ID of the GKE cluster"
  value       = google_container_cluster.this.id
}

output "cluster_name" {
  description = "The name of the GKE cluster"
  value       = google_container_cluster.this.name
}

output "cluster_endpoint" {
  description = "The IP address of the cluster master"
  value       = google_container_cluster.this.endpoint
  sensitive   = true
}

output "cluster_ca_certificate" {
  description = "The cluster CA certificate (base64 encoded)"
  value       = google_container_cluster.this.master_auth[0].cluster_ca_certificate
  sensitive   = true
}

output "cluster_location" {
  description = "The location (region or zone) of the cluster"
  value       = google_container_cluster.this.location
}

output "node_pool_ids" {
  description = "Map of node pool name to node pool ID"
  value       = { for k, v in google_container_node_pool.this : k => v.id }
}

output "kubeconfig_command" {
  description = "gcloud command to configure kubectl"
  value       = "gcloud container clusters get-credentials ${google_container_cluster.this.name} --region ${google_container_cluster.this.location} --project ${var.project_id}"
}
