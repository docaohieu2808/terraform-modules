# terraform.rego — Terraform plan policies (OPA/Rego)
# Evaluated against: terraform show -json tfplan > tfplan.json
# Run: conftest test tfplan.json -p policy/
#
# Policies:
#   - Deny VMs with machine_type larger than e2-standard-4
#   - Deny public SSH from 0.0.0.0/0
#   - Require all resources to have labels/tags
#   - Deny deletion_protection=false on production
#   - Require GCS buckets to have versioning enabled

package main

import rego.v1

# Allowed machine types (ordered by size — nothing larger than e2-standard-4)
allowed_machine_types := {
  "e2-micro",
  "e2-small",
  "e2-medium",
  "e2-standard-2",
  "e2-standard-4",
}

# ---------------------------------------------------------------------------
# Helper: collect all resource changes from the plan
# ---------------------------------------------------------------------------
resource_changes := input.resource_changes

# ---------------------------------------------------------------------------
# DENY: VM machine_type larger than e2-standard-4
# ---------------------------------------------------------------------------
deny contains msg if {
  some rc in resource_changes
  rc.type == "google_compute_instance"
  rc.change.actions[_] in {"create", "update"}
  machine_type := rc.change.after.machine_type
  not machine_type in allowed_machine_types
  msg := sprintf(
    "DENY [machine-type]: '%s' uses machine_type '%s'. Max allowed: e2-standard-4",
    [rc.address, machine_type],
  )
}

# ---------------------------------------------------------------------------
# DENY: Public SSH from 0.0.0.0/0
# ---------------------------------------------------------------------------
deny contains msg if {
  some rc in resource_changes
  rc.type == "google_compute_firewall"
  rc.change.actions[_] in {"create", "update"}
  rule := rc.change.after.allow[_]
  rule.ports[_] == "22"
  "0.0.0.0/0" in rc.change.after.source_ranges
  msg := sprintf(
    "DENY [public-ssh]: Firewall rule '%s' allows SSH from 0.0.0.0/0. Use specific IP ranges.",
    [rc.address],
  )
}

# Also check source_ranges at top level (some configs put it there)
deny contains msg if {
  some rc in resource_changes
  rc.type == "google_compute_firewall"
  rc.change.actions[_] in {"create", "update"}
  "22" in rc.change.after.allow[_].ports
  "0.0.0.0/0" in object.get(rc.change.after, "source_ranges", [])
  msg := sprintf(
    "DENY [public-ssh]: Firewall rule '%s' allows SSH from 0.0.0.0/0.",
    [rc.address],
  )
}

# ---------------------------------------------------------------------------
# DENY: Resources without labels/tags
# ---------------------------------------------------------------------------
labeled_types := {
  "google_compute_instance",
  "google_compute_disk",
  "google_storage_bucket",
  "google_container_cluster",
  "google_container_node_pool",
}

deny contains msg if {
  some rc in resource_changes
  rc.type in labeled_types
  rc.change.actions[_] in {"create", "update"}
  labels := object.get(rc.change.after, "labels", {})
  count(labels) == 0
  msg := sprintf(
    "DENY [labels-required]: '%s' (type: %s) must have at least one label.",
    [rc.address, rc.type],
  )
}

# ---------------------------------------------------------------------------
# DENY: deletion_protection=false on production resources
# ---------------------------------------------------------------------------
deny contains msg if {
  some rc in resource_changes
  rc.type in {"google_container_cluster", "google_sql_database_instance"}
  rc.change.actions[_] in {"create", "update"}

  # Detect prod by label or address prefix
  is_production(rc)

  deletion_protection := object.get(rc.change.after, "deletion_protection", true)
  deletion_protection == false

  msg := sprintf(
    "DENY [deletion-protection]: Production resource '%s' must have deletion_protection=true.",
    [rc.address],
  )
}

is_production(rc) if {
  startswith(rc.address, "prod")
}

is_production(rc) if {
  rc.change.after.labels.env == "prod"
}

# ---------------------------------------------------------------------------
# DENY: GCS buckets without versioning enabled
# ---------------------------------------------------------------------------
deny contains msg if {
  some rc in resource_changes
  rc.type == "google_storage_bucket"
  rc.change.actions[_] in {"create", "update"}
  versioning := object.get(rc.change.after, "versioning", [])
  count(versioning) == 0
  msg := sprintf(
    "DENY [bucket-versioning]: GCS bucket '%s' must have versioning enabled.",
    [rc.address],
  )
}

deny contains msg if {
  some rc in resource_changes
  rc.type == "google_storage_bucket"
  rc.change.actions[_] in {"create", "update"}
  versioning := rc.change.after.versioning[_]
  versioning.enabled == false
  msg := sprintf(
    "DENY [bucket-versioning]: GCS bucket '%s' has versioning disabled. Set versioning.enabled=true.",
    [rc.address],
  )
}
