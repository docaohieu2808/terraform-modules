terraform {
  required_version = ">= 1.5"
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = ">= 5.0"
    }
  }
}

provider "google" {
  project     = var.project_id
  region      = var.region
  credentials = var.credentials_file
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
  region       = var.region
  zone         = var.zone
  name         = "${var.env}-app-server"
  machine_type = var.machine_type
  disk_size_gb = var.disk_size_gb

  network    = module.network.network_name
  subnetwork = module.network.subnet_self_links["${var.env}-subnet-${var.region}"]

  tags           = ["ssh", "http-server", "https-server"]
  startup_script = var.startup_script

  enable_public_ip = true
}

# ── GCS State Bucket (bootstrap) ──────────────────────────────────────────────
module "tfstate_bucket" {
  source = "../../modules/gcp-storage"

  project_id         = var.project_id
  bucket_name        = "${var.project_id}-tfstate"
  location           = "US"
  versioning_enabled = true
  force_destroy      = false

  labels = {
    env     = var.env
    purpose = "terraform-state"
  }
}
