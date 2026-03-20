# Level 6: Terragrunt DRY — dev environment
# Inherits root terragrunt.hcl for backend, provider, and common inputs

include "root" {
  path = find_in_parent_folders()
}

inputs = {
  project_id       = "iac-devops-484714"
  region           = "us-central1"
  zone             = "us-central1-a"
  env              = "dev"
  credentials_file = "/home/hieudc/iac-devops-terraform.json"

  subnet_cidr  = "10.10.0.0/24"
  machine_type = "e2-medium"
  disk_size_gb = 20

  # Restrict SSH to specific ranges (not 0.0.0.0/0) — OPA policy compliant
  ssh_source_ranges = ["10.0.0.0/8", "192.168.0.0/16"]
  ssh_public_key    = "hieudc:ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIHsZ8c/qSgMIx8tNfe7vLY4SiQ6uxAFlCF2KbhG2mVWC hieudc@server-2"
}
