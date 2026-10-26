# Offline unit tests: the google provider is mocked, nothing talks to GCP.
# Run from this module directory: terraform test
mock_provider "google" {}

variables {
  project_id = "example-lab-project"
  name       = "dev-app-server"
}

run "defaults" {
  command = plan

  assert {
    condition     = google_compute_instance.this.machine_type == "e2-medium"
    error_message = "Default machine type should be e2-medium"
  }

  assert {
    condition     = length(google_compute_instance.this.network_interface[0].access_config) == 1
    error_message = "enable_public_ip defaults to true: one ephemeral access_config"
  }
}

run "private_instance" {
  command = plan

  variables {
    enable_public_ip = false
  }

  assert {
    condition     = length(google_compute_instance.this.network_interface[0].access_config) == 0
    error_message = "No external IP when enable_public_ip is false"
  }
}

run "additional_disks_are_attached" {
  command = plan

  variables {
    additional_disks = [{ name = "data", size_gb = 100, type = "pd-ssd" }]
  }

  assert {
    condition     = length(google_compute_disk.additional) == 1 && google_compute_disk.additional["data"].size == 100
    error_message = "One 100 GB additional disk should be planned"
  }
}

run "startup_script_lands_in_metadata" {
  command = plan

  variables {
    startup_script = "#!/bin/sh\necho hello"
  }

  assert {
    condition     = google_compute_instance.this.metadata["startup-script"] == "#!/bin/sh\necho hello"
    error_message = "startup_script must be merged into instance metadata"
  }
}
