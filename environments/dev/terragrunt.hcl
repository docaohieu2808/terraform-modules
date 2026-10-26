# Level 6: Terragrunt DRY — dev environment
# Inherits root.hcl for backend, provider, and common inputs

include "root" {
  path = find_in_parent_folders("root.hcl")
}

inputs = {
  project_id       = get_env("TF_VAR_project_id", "your-gcp-project")
  region           = "us-central1"
  zone             = "us-central1-a"
  env              = "dev"
  credentials_file = get_env("GOOGLE_APPLICATION_CREDENTIALS", "")

  subnet_cidr  = "10.10.0.0/24"
  machine_type = "e2-medium"
  disk_size_gb = 20

  # Restrict SSH to specific ranges (not 0.0.0.0/0) — OPA policy compliant
  ssh_source_ranges = ["10.0.0.0/8", "192.168.0.0/16"]
  # Optional, e.g. export TF_VAR_ssh_public_key="alice:ssh-ed25519 AAAA... alice@laptop"
  ssh_public_key = get_env("TF_VAR_ssh_public_key", "")
}
