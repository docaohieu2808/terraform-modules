terraform {
  required_version = ">= 1.10"
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 8.0"
    }
  }
}

provider "google" {
  project     = var.project_id
  region      = var.region
  credentials = var.credentials_file != "" ? var.credentials_file : null
}

# ── Network ────────────────────────────────────────────────────────────────────
module "network" {
  source = "../../modules/gcp-network"

  project_id   = var.project_id
  region       = var.region
  network_name = "${var.env}-vpc"

  subnets = [
    {
      name          = "${var.env}-subnet-${var.region}"
      ip_cidr_range = var.subnet_cidr
      region        = var.region
    }
  ]

  enable_ssh   = true
  enable_http  = true
  enable_https = true

  ssh_source_ranges = var.ssh_source_ranges
}

# ── Compute ────────────────────────────────────────────────────────────────────
module "compute" {
  source = "../../modules/gcp-compute"

  project_id   = var.project_id
  zone         = var.zone
  name         = "${var.env}-app-server"
  machine_type = var.machine_type
  disk_size_gb = var.disk_size_gb

  network    = module.network.network_name
  subnetwork = module.network.subnet_self_links["${var.env}-subnet-${var.region}"]

  tags           = ["ssh", "http-server", "https-server"]
  labels         = { env = var.env }
  startup_script = var.startup_script

  enable_public_ip = true

  metadata = var.ssh_public_key != "" ? { ssh-keys = var.ssh_public_key } : {}
}

# ── Cloud Storage ─────────────────────────────────────────────────────────────
# The Terraform state bucket is NOT managed here: Terragrunt bootstraps it
# (`terragrunt backend bootstrap`, see README), so destroying dev can never
# delete the state that tracks it.
module "app_bucket" {
  source = "../../modules/gcp-storage"

  project_id         = var.project_id
  bucket_name        = "${var.env}-${var.project_id}-assets"
  location           = "US"
  versioning_enabled = true
  force_destroy      = true

  labels = {
    env     = var.env
    purpose = "app-assets"
  }
}
