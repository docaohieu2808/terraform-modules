# Level 6: Terragrunt DRY — staging environment
# Inherits root.hcl for backend, provider, and common inputs

include "root" {
  path = find_in_parent_folders("root.hcl")
}

inputs = {
  project_id       = get_env("TF_VAR_project_id", "your-gcp-project")
  region           = "us-central1"
  zone             = "us-central1-a"
  env              = "staging"
  credentials_file = get_env("GOOGLE_APPLICATION_CREDENTIALS", "")

  subnet_cidr      = "10.20.0.0/24"
  machine_type     = "e2-standard-2"
  disk_size_gb     = 50
  gke_machine_type = "e2-standard-2"

  # Restrict SSH to internal ranges — OPA policy compliant
  ssh_source_ranges = ["10.0.0.0/8", "172.16.0.0/12"]
}
