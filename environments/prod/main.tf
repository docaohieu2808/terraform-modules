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
    },
    {
      name          = "${var.env}-gke-pods-subnet"
      ip_cidr_range = var.gke_pods_cidr
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

  enable_public_ip    = true
  deletion_protection = true
}

# ── GKE ───────────────────────────────────────────────────────────────────────
module "gke" {
  source = "../../modules/gcp-gke"

  project_id   = var.project_id
  region       = var.region
  cluster_name = "${var.env}-gke-cluster"

  network    = module.network.network_name
  subnetwork = module.network.subnet_self_links["${var.env}-subnet-${var.region}"]

  regional = true
  zones    = var.gke_zones

  node_pools = [
    {
      name               = "default-pool"
      machine_type       = var.gke_machine_type
      min_node_count     = var.gke_min_nodes
      max_node_count     = var.gke_max_nodes
      initial_node_count = var.gke_min_nodes
      disk_size_gb       = 100
    }
  ]

  master_authorized_networks = [
    {
      cidr_block   = var.subnet_cidr
      display_name = "prod-subnet"
    }
  ]

  deletion_protection = true
}

# ── Cloud Storage ─────────────────────────────────────────────────────────────
module "app_bucket" {
  source = "../../modules/gcp-storage"

  project_id         = var.project_id
  bucket_name        = "${var.project_id}-${var.env}-assets"
  location           = "US"
  storage_class      = "STANDARD"
  versioning_enabled = true
  force_destroy      = false

  lifecycle_rules = [
    {
      action_type        = "Delete"
      age_days           = 365
      num_newer_versions = 3
    }
  ]

  labels = {
    env     = var.env
    purpose = "app-assets"
  }
}
