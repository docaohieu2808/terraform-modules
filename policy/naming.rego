# naming.rego — Resource naming convention policies (OPA/Rego)
# Evaluated against: terraform show -json tfplan > tfplan.json
# Run: conftest test tfplan.json -p policy/
#
# Policies:
#   - Names must start with env prefix (dev-, staging-, prod-)
#   - Names must be lowercase with hyphens only (no underscores, spaces, uppercase)

package main

import rego.v1

# Resource types whose names must follow naming conventions
named_resource_types := {
  "google_compute_instance",
  "google_compute_network",
  "google_compute_subnetwork",
  "google_compute_firewall",
  "google_compute_disk",
  "google_storage_bucket",
  "google_container_cluster",
  "google_container_node_pool",
}

valid_env_prefixes := {"dev-", "staging-", "prod-"}

# ---------------------------------------------------------------------------
# DENY: Name does not start with a valid env prefix
# ---------------------------------------------------------------------------
deny contains msg if {
  some rc in input.resource_changes
  rc.type in named_resource_types
  rc.change.actions[_] in {"create", "update"}
  name := rc.change.after.name
  not any_prefix_match(name, valid_env_prefixes)
  msg := sprintf(
    "DENY [naming-prefix]: '%s' name '%s' must start with one of: dev-, staging-, prod-",
    [rc.address, name],
  )
}

any_prefix_match(name, prefixes) if {
  some prefix in prefixes
  startswith(name, prefix)
}

# ---------------------------------------------------------------------------
# DENY: Name contains uppercase letters, underscores, or spaces
# ---------------------------------------------------------------------------
deny contains msg if {
  some rc in input.resource_changes
  rc.type in named_resource_types
  rc.change.actions[_] in {"create", "update"}
  name := rc.change.after.name
  not regex.match(`^[a-z0-9][a-z0-9\-]*[a-z0-9]$`, name)
  msg := sprintf(
    "DENY [naming-format]: '%s' name '%s' must be lowercase alphanumeric with hyphens only (no underscores, spaces, or uppercase).",
    [rc.address, name],
  )
}
