# terraform.rego — Terraform plan policies (OPA/Rego)
# Evaluated against: terraform show -json tfplan > tfplan.json
# Run: conftest test tfplan.json -p policy/
#
# Policies:
#   - Deny VMs with machine_type larger than e2-standard-4
#   - Deny public SSH from 0.0.0.0/0
#   - Require all resources to have labels/tags
#   - Deny deletion_protection=false on production (label env=prod or name prod-*)
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
# A rule "allows SSH" when it lists port 22, a port range containing 22, or
# no ports at all (tcp/all with no port list means every port).
# ---------------------------------------------------------------------------
allows_ssh(rule) if {
	some port in rule.ports
	port == "22"
}

allows_ssh(rule) if {
	some port in rule.ports
	contains(port, "-")
	bounds := split(port, "-")
	to_number(bounds[0]) <= 22
	22 <= to_number(bounds[1])
}

allows_ssh(rule) if {
	count(object.get(rule, "ports", [])) == 0
	rule.protocol in {"tcp", "all"}
}

deny contains msg if {
	some rc in resource_changes
	rc.type == "google_compute_firewall"
	rc.change.actions[_] in {"create", "update"}

	# direction is computed (absent in a plan) when left at its INGRESS default
	object.get(rc.change.after, "direction", "INGRESS") == "INGRESS"
	some rule in rc.change.after.allow
	allows_ssh(rule)
	"0.0.0.0/0" in object.get(rc.change.after, "source_ranges", [])
	msg := sprintf(
		"DENY [public-ssh]: Firewall rule '%s' allows SSH from 0.0.0.0/0. Use specific IP ranges.",
		[rc.address],
	)
}

# ---------------------------------------------------------------------------
# DENY: Resources without labels
# The label attribute differs per type: GKE clusters use resource_labels and
# node pools carry labels inside node_config.
# ---------------------------------------------------------------------------
labeled_types := {
	"google_compute_instance",
	"google_compute_disk",
	"google_storage_bucket",
	"google_container_cluster",
	"google_container_node_pool",
}

as_object(value) := value if is_object(value)

as_object(value) := {} if not is_object(value)

labels_of(rc) := as_object(object.get(rc.change.after, "resource_labels", {})) if {
	rc.type == "google_container_cluster"
}

labels_of(rc) := as_object(object.get(node_config, "labels", {})) if {
	rc.type == "google_container_node_pool"
	node_config := object.get(rc.change.after, "node_config", [{}])[0]
}

labels_of(rc) := as_object(object.get(rc.change.after, "labels", {})) if {
	not rc.type in {"google_container_cluster", "google_container_node_pool"}
}

deny contains msg if {
	some rc in resource_changes
	rc.type in labeled_types
	rc.change.actions[_] in {"create", "update"}
	count(labels_of(rc)) == 0
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
	rc.type in {"google_container_cluster", "google_compute_instance", "google_sql_database_instance"}
	rc.change.actions[_] in {"create", "update"}
	is_production(rc)
	object.get(rc.change.after, "deletion_protection", true) == false

	msg := sprintf(
		"DENY [deletion-protection]: Production resource '%s' must have deletion_protection=true.",
		[rc.address],
	)
}

# Production = env=prod label, or a resource name with the prod- prefix.
# (The Terraform address, e.g. module.gke.google_container_cluster.this, never
# carries the environment, so it cannot be used.)
is_production(rc) if {
	object.get(labels_of(rc), "env", "") == "prod"
}

is_production(rc) if {
	startswith(object.get(rc.change.after, "name", ""), "prod-")
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
