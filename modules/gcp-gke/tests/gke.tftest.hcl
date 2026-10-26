# Offline unit tests: the google provider is mocked, nothing talks to GCP.
# Run from this module directory: terraform test
mock_provider "google" {}

variables {
  project_id   = "example-lab-project"
  cluster_name = "dev-gke-cluster"
}

run "standard_cluster_manages_its_own_node_pools" {
  command = plan

  variables {
    node_pools = [{ name = "dev-default-pool", machine_type = "e2-standard-2" }]
  }

  assert {
    condition     = google_container_cluster.this.remove_default_node_pool == true
    error_message = "Standard clusters must drop the default node pool"
  }

  assert {
    condition     = length(google_container_node_pool.this) == 1
    error_message = "One node pool expected"
  }
}

run "autopilot_has_no_node_pools" {
  command = plan

  variables {
    enable_autopilot = true
  }

  assert {
    condition     = google_container_cluster.this.enable_autopilot == true && length(google_container_node_pool.this) == 0
    error_message = "Autopilot clusters manage nodes themselves"
  }
}
