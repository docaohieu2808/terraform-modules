# Root Terragrunt configuration — DRY common settings for all environments
# Each environment's terragrunt.hcl should include this file via find_in_parent_folders()

locals {
  project_id      = "devops-pipeline-481120"
  region          = "us-central1"
  credentials     = "/home/hieudc/terraform/service-account.json"
  tfstate_bucket  = "${local.project_id}-tfstate"

  # Derive environment name from directory structure: environments/<env>/
  env = element(split("/", path_relative_to_include()), 1)
}

# Remote state configuration — each environment gets its own prefix
remote_state {
  backend = "gcs"
  generate = {
    path      = "backend.tf"
    if_exists = "overwrite_terragrunt"
  }
  config = {
    project  = local.project_id
    location = local.region
    bucket   = local.tfstate_bucket
    prefix   = "environments/${local.env}"

    gcs_bucket_labels = {
      env     = local.env
      managed = "terragrunt"
    }
  }
}

# Generate provider configuration for all environments
generate "provider" {
  path      = "provider_generated.tf"
  if_exists = "overwrite_terragrunt"
  contents  = <<EOF
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
  project     = "${local.project_id}"
  region      = "${local.region}"
  credentials = "${local.credentials}"
}
EOF
}

# Common inputs available to all child modules
inputs = {
  project_id       = local.project_id
  region           = local.region
  credentials_file = local.credentials
}
