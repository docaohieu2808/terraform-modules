# Level 6: Terragrunt DRY — prod environment
# Inherits root.hcl for backend, provider, and common inputs

include "root" {
  path = find_in_parent_folders("root.hcl")
}

inputs = {
  project_id       = get_env("TF_VAR_project_id", "your-gcp-project")
  region           = "us-central1"
  zone             = "us-central1-a"
  env              = "prod"
  credentials_file = get_env("GOOGLE_APPLICATION_CREDENTIALS", "")

  subnet_cidr   = "10.30.0.0/24"
  gke_pods_cidr = "10.31.0.0/16"
  machine_type  = "e2-standard-4"
  disk_size_gb  = 100

  gke_machine_type = "e2-standard-4"
  gke_zones        = ["us-central1-a", "us-central1-b", "us-central1-c"]
  gke_min_nodes    = 1
  gke_max_nodes    = 5

  # Restrict SSH to internal corp ranges only — OPA policy compliant
  ssh_source_ranges = ["10.0.0.0/8"]
}
