terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = ">= 5.0"
    }
  }
}

resource "google_container_cluster" "this" {
  project  = var.project_id
  name     = var.cluster_name
  location = var.regional ? var.region : (length(var.zones) > 0 ? var.zones[0] : "${var.region}-a")

  network    = var.network
  subnetwork = var.subnetwork != "" ? var.subnetwork : null

  # Autopilot mode
  enable_autopilot = var.enable_autopilot

  # For standard clusters, remove the default node pool and manage separately
  remove_default_node_pool = var.enable_autopilot ? null : true
  initial_node_count       = var.enable_autopilot ? null : 1

  node_locations = var.regional && length(var.zones) > 0 ? var.zones : null

  release_channel {
    channel = var.release_channel
  }

  min_master_version = var.kubernetes_version != "" ? var.kubernetes_version : null

  dynamic "private_cluster_config" {
    for_each = var.enable_private_nodes ? [1] : []
    content {
      enable_private_nodes    = true
      enable_private_endpoint = var.enable_private_endpoint
      master_ipv4_cidr_block  = var.master_ipv4_cidr_block
    }
  }

  dynamic "master_authorized_networks_config" {
    for_each = length(var.master_authorized_networks) > 0 ? [1] : []
    content {
      dynamic "cidr_blocks" {
        for_each = var.master_authorized_networks
        content {
          cidr_block   = cidr_blocks.value.cidr_block
          display_name = cidr_blocks.value.display_name
        }
      }
    }
  }

  dynamic "ip_allocation_policy" {
    for_each = (var.pods_ipv4_cidr_block != "" || var.services_ipv4_cidr_block != "") ? [1] : []
    content {
      cluster_ipv4_cidr_block  = var.pods_ipv4_cidr_block != "" ? var.pods_ipv4_cidr_block : null
      services_ipv4_cidr_block = var.services_ipv4_cidr_block != "" ? var.services_ipv4_cidr_block : null
    }
  }

  addons_config {
    http_load_balancing {
      disabled = !var.enable_http_load_balancing
    }
    horizontal_pod_autoscaling {
      disabled = !var.enable_horizontal_pod_autoscaling
    }
  }

  dynamic "workload_identity_config" {
    for_each = var.enable_workload_identity ? [1] : []
    content {
      workload_pool = "${var.project_id}.svc.id.goog"
    }
  }

  resource_labels = var.labels

  deletion_protection = var.deletion_protection

  lifecycle {
    ignore_changes = [initial_node_count]
  }
}

resource "google_container_node_pool" "this" {
  for_each = var.enable_autopilot ? {} : { for np in var.node_pools : np.name => np }

  project    = var.project_id
  name       = each.value.name
  cluster    = google_container_cluster.this.id
  location   = google_container_cluster.this.location

  initial_node_count = each.value.initial_node_count

  autoscaling {
    min_node_count = each.value.min_node_count
    max_node_count = each.value.max_node_count
  }

  node_config {
    machine_type = each.value.machine_type
    disk_size_gb = each.value.disk_size_gb
    disk_type    = each.value.disk_type
    image_type   = each.value.image_type
    preemptible  = each.value.preemptible
    spot         = each.value.spot

    labels = each.value.labels
    tags   = each.value.tags

    oauth_scopes = each.value.oauth_scopes

    dynamic "taint" {
      for_each = each.value.taints
      content {
        key    = taint.value.key
        value  = taint.value.value
        effect = taint.value.effect
      }
    }

    dynamic "workload_metadata_config" {
      for_each = var.enable_workload_identity ? [1] : []
      content {
        mode = "GKE_METADATA"
      }
    }
  }

  management {
    auto_repair  = true
    auto_upgrade = true
  }

  lifecycle {
    ignore_changes = [initial_node_count]
  }
}
