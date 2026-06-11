# Root Terragrunt configuration — DRY common settings for all environments
# Each environment's terragrunt.hcl should include this file via find_in_parent_folders()

locals {
  project_id      = get_env("TF_VAR_project_id", "your-gcp-project")
  region          = get_env("TF_VAR_region", "us-central1")
  credentials     = get_env("GOOGLE_APPLICATION_CREDENTIALS", "")
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

# Provider config is in each environment's main.tf
# Terragrunt handles only backend + inputs (DRY)

# Common inputs available to all child modules
inputs = {
  project_id       = local.project_id
  region           = local.region
  credentials_file = local.credentials
}
