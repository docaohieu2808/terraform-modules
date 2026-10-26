# Offline unit tests: the google provider is mocked, nothing talks to GCP.
# Run from this module directory: terraform test
mock_provider "google" {}

variables {
  project_id = "example-lab-project"
  zone_name  = "example-zone"
  dns_name   = "example.com."
}

run "public_zone_defaults" {
  command = plan

  assert {
    condition     = google_dns_managed_zone.this.visibility == "public"
    error_message = "Zones must be public unless asked otherwise"
  }

  assert {
    condition     = length(google_dns_managed_zone.this.dnssec_config) == 0
    error_message = "DNSSEC must be off by default"
  }

  assert {
    condition     = length(google_dns_managed_zone.this.private_visibility_config) == 0
    error_message = "A public zone must not render private_visibility_config"
  }

  assert {
    condition     = length(google_dns_record_set.this) == 0
    error_message = "No records are created unless requested"
  }

  assert {
    condition     = output.zone_name == "example-zone" && output.dns_name == "example.com."
    error_message = "Outputs must expose the zone name and DNS name"
  }
}

run "records_are_keyed_by_name_and_type" {
  command = plan

  variables {
    records = [
      { name = "www.example.com.", type = "A", rrdatas = ["192.0.2.10"] },
      { name = "www.example.com.", type = "AAAA", rrdatas = ["2001:db8::10"], ttl = 60 },
      { name = "mail.example.com.", type = "CNAME", rrdatas = ["www.example.com."] },
    ]
  }

  assert {
    condition     = toset(keys(google_dns_record_set.this)) == toset(["www.example.com.-A", "www.example.com.-AAAA", "mail.example.com.-CNAME"])
    error_message = "Records must be keyed by <name>-<type> so the same name can carry several types"
  }

  assert {
    condition     = google_dns_record_set.this["www.example.com.-A"].ttl == 300
    error_message = "ttl must default to 300"
  }

  assert {
    condition     = google_dns_record_set.this["www.example.com.-AAAA"].ttl == 60
    error_message = "An explicit ttl must be kept"
  }

  assert {
    condition     = google_dns_record_set.this["www.example.com.-A"].rrdatas == tolist(["192.0.2.10"]) && google_dns_record_set.this["www.example.com.-A"].managed_zone == "example-zone"
    error_message = "Records must carry their rrdatas and attach to the managed zone"
  }
}

run "private_zone_renders_its_networks" {
  command = plan

  variables {
    visibility = "private"
    private_visibility_networks = [
      "https://www.googleapis.com/compute/v1/projects/example-lab-project/global/networks/vpc-a",
      "https://www.googleapis.com/compute/v1/projects/example-lab-project/global/networks/vpc-b",
    ]
  }

  assert {
    condition     = length(google_dns_managed_zone.this.private_visibility_config) == 1
    error_message = "A private zone with networks must render one private_visibility_config"
  }

  assert {
    condition     = length(google_dns_managed_zone.this.private_visibility_config[0].networks) == 2
    error_message = "Both VPC networks must be attached"
  }
}

run "private_zone_without_networks_renders_no_visibility_block" {
  command = plan

  variables {
    visibility = "private"
  }

  assert {
    condition     = length(google_dns_managed_zone.this.private_visibility_config) == 0
    error_message = "No networks means no private_visibility_config block"
  }
}

run "dnssec_toggle" {
  command = plan

  variables {
    dnssec_enabled = true
  }

  assert {
    condition     = length(google_dns_managed_zone.this.dnssec_config) == 1 && google_dns_managed_zone.this.dnssec_config[0].state == "on"
    error_message = "dnssec_enabled=true must turn DNSSEC on"
  }
}

run "dns_name_needs_trailing_dot" {
  command = plan

  variables {
    dns_name = "example.com"
  }

  expect_failures = [var.dns_name]
}

run "visibility_is_restricted" {
  command = plan

  variables {
    visibility = "internal"
  }

  expect_failures = [var.visibility]
}
