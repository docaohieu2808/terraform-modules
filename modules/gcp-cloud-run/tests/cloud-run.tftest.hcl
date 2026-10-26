# Offline unit tests: the google provider is mocked, nothing talks to GCP.
# Run from this module directory: terraform test
mock_provider "google" {}

variables {
  project_id   = "example-lab-project"
  service_name = "web"
  image        = "us-docker.pkg.dev/example-lab-project/apps/web:1.0.0"
}

run "private_by_default" {
  command = plan

  assert {
    condition     = length(google_cloud_run_v2_service_iam_member.public) == 0
    error_message = "No allUsers invoker binding unless allow_unauthenticated is set"
  }

  assert {
    condition     = google_cloud_run_v2_service.this.ingress == "INGRESS_TRAFFIC_ALL"
    error_message = "ingress must default to a value the Cloud Run v2 API accepts"
  }

  assert {
    condition     = length(google_cloud_run_v2_service.this.template[0].vpc_access) == 0
    error_message = "No VPC access block without a connector"
  }
}

run "sizing_defaults" {
  command = plan

  assert {
    condition = (
      google_cloud_run_v2_service.this.template[0].scaling[0].min_instance_count == 0 &&
      google_cloud_run_v2_service.this.template[0].scaling[0].max_instance_count == 10 &&
      google_cloud_run_v2_service.this.template[0].timeout == "300s" &&
      google_cloud_run_v2_service.this.template[0].max_instance_request_concurrency == 80
    )
    error_message = "Scale-to-zero, max 10, 300s timeout and concurrency 80 are the documented defaults"
  }

  assert {
    condition = (
      google_cloud_run_v2_service.this.template[0].containers[0].image == var.image &&
      google_cloud_run_v2_service.this.template[0].containers[0].ports[0].container_port == 8080 &&
      google_cloud_run_v2_service.this.template[0].containers[0].resources[0].limits["cpu"] == "1" &&
      google_cloud_run_v2_service.this.template[0].containers[0].resources[0].limits["memory"] == "512Mi"
    )
    error_message = "Container image, port 8080 and 1 CPU / 512Mi limits expected"
  }
}

run "public_service_gets_invoker_binding" {
  command = plan

  variables {
    allow_unauthenticated = true
  }

  assert {
    condition = (
      length(google_cloud_run_v2_service_iam_member.public) == 1 &&
      google_cloud_run_v2_service_iam_member.public[0].member == "allUsers" &&
      google_cloud_run_v2_service_iam_member.public[0].role == "roles/run.invoker"
    )
    error_message = "allow_unauthenticated=true must grant roles/run.invoker to allUsers, nothing broader"
  }
}

run "plain_and_secret_env_vars" {
  command = plan

  variables {
    env_vars        = { LOG_LEVEL = "info" }
    secret_env_vars = [{ env_var = "DB_PASSWORD", secret = "db-password" }]
  }

  assert {
    condition     = length(google_cloud_run_v2_service.this.template[0].containers[0].env) == 2
    error_message = "One plain and one secret env var expected"
  }

  assert {
    condition = anytrue([
      for e in google_cloud_run_v2_service.this.template[0].containers[0].env :
      e.name == "LOG_LEVEL" && e.value == "info"
    ])
    error_message = "The plain env var must carry its value"
  }

  assert {
    condition = anytrue([
      for e in google_cloud_run_v2_service.this.template[0].containers[0].env :
      e.name == "DB_PASSWORD" && e.value_source[0].secret_key_ref[0].secret == "db-password" && e.value_source[0].secret_key_ref[0].version == "latest"
    ])
    error_message = "A secret env var must reference Secret Manager, version latest by default, never a literal value"
  }
}

run "vpc_connector_renders_vpc_access" {
  command = plan

  variables {
    vpc_connector = "projects/example-lab-project/locations/us-central1/connectors/lab-connector"
    vpc_egress    = "ALL_TRAFFIC"
  }

  assert {
    condition = (
      length(google_cloud_run_v2_service.this.template[0].vpc_access) == 1 &&
      google_cloud_run_v2_service.this.template[0].vpc_access[0].egress == "ALL_TRAFFIC"
    )
    error_message = "A connector must render vpc_access with the requested egress"
  }
}

run "outputs_expose_name_and_location" {
  command = plan

  variables {
    region = "asia-southeast1"
  }

  assert {
    condition     = output.service_name == "web" && output.location == "asia-southeast1"
    error_message = "Outputs must reflect the service name and region"
  }
}

run "ingress_rejects_non_v2_values" {
  command = plan

  variables {
    ingress = "all"
  }

  expect_failures = [var.ingress]
}

run "vpc_egress_rejects_non_v2_values" {
  command = plan

  variables {
    vpc_egress = "private-ranges-only"
  }

  expect_failures = [var.vpc_egress]
}

run "max_instances_cannot_be_below_min" {
  command = plan

  variables {
    min_instance_count = 5
    max_instance_count = 2
  }

  expect_failures = [var.max_instance_count]
}

run "timeout_is_bounded" {
  command = plan

  variables {
    timeout_seconds = 7200
  }

  expect_failures = [var.timeout_seconds]
}
