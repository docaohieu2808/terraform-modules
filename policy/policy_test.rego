# Unit tests for the policies in this directory. Run: opa test policy/ -v
# Each deny rule has a failing input (must produce its message) and the
# compliant input must produce no message at all.

package main

import rego.v1

create := ["create"]

vm(overrides) := object.union(
	{
		"address": "module.compute.google_compute_instance.this",
		"type": "google_compute_instance",
		"change": {"actions": create, "after": {
			"name": "dev-app-server",
			"machine_type": "e2-medium",
			"labels": {"env": "dev"},
			"deletion_protection": false,
			"boot_disk": [{"initialize_params": [{"size": 20}]}],
		}},
	},
	overrides,
)

firewall(ranges, ports) := {
	"address": "module.network.google_compute_firewall.ssh[0]",
	"type": "google_compute_firewall",
	"change": {"actions": create, "after": {
		"name": "dev-vpc-allow-ssh",
		"direction": "INGRESS",
		"source_ranges": ranges,
		"allow": [{"protocol": "tcp", "ports": ports}],
	}},
}

bucket(after) := {
	"address": "module.app_bucket.google_storage_bucket.this",
	"type": "google_storage_bucket",
	"change": {"actions": create, "after": after},
}

good_bucket := {"name": "dev-proj-assets", "labels": {"env": "dev"}, "versioning": [{"enabled": true}]}

test_compliant_plan_has_no_denials if {
	count(deny) == 0 with input as {"resource_changes": [
		vm({}),
		firewall(["10.0.0.0/8"], ["22"]),
		bucket(good_bucket),
	]}
}

# -- terraform.rego ----------------------------------------------------------
test_deny_oversized_machine_type if {
	some msg in deny with input as {"resource_changes": [vm({"change": {"actions": create, "after": {"name": "dev-x", "machine_type": "e2-standard-8", "labels": {"env": "dev"}}}})]}
	contains(msg, "machine-type")
}

test_deny_public_ssh if {
	some msg in deny with input as {"resource_changes": [firewall(["0.0.0.0/0"], ["22"])]}
	contains(msg, "public-ssh")
}

test_deny_public_ssh_when_direction_is_unset_in_plan if {
	rule := firewall(["0.0.0.0/0"], ["22"])
	unset := json.remove(rule, ["change/after/direction"])
	some msg in deny with input as {"resource_changes": [unset]}
	contains(msg, "public-ssh")
}

test_egress_rules_are_not_ssh_exposure if {
	rule := object.union(firewall(["0.0.0.0/0"], ["22"]), {"change": {"actions": create, "after": {"direction": "EGRESS", "name": "dev-egress", "source_ranges": ["0.0.0.0/0"], "allow": [{"protocol": "tcp", "ports": ["22"]}]}}})
	count([m | some m in deny with input as {"resource_changes": [rule]}; contains(m, "public-ssh")]) == 0
}

test_deny_public_ssh_via_port_range if {
	some msg in deny with input as {"resource_changes": [firewall(["0.0.0.0/0"], ["1-1024"])]}
	contains(msg, "public-ssh")
}

test_deny_public_ssh_when_all_ports if {
	some msg in deny with input as {"resource_changes": [firewall(["0.0.0.0/0"], [])]}
	contains(msg, "public-ssh")
}

test_allow_public_https if {
	count([m | some m in deny with input as {"resource_changes": [firewall(["0.0.0.0/0"], ["443"])]}; contains(m, "public-ssh")]) == 0
}

test_deny_missing_labels if {
	some msg in deny with input as {"resource_changes": [vm({"change": {"actions": create, "after": {"name": "dev-x", "machine_type": "e2-micro", "labels": null}}})]}
	contains(msg, "labels-required")
}

cluster(labels) := {
	"address": "module.gke.google_container_cluster.this",
	"type": "google_container_cluster",
	"change": {"actions": create, "after": {"name": "dev-gke-cluster", "resource_labels": labels, "deletion_protection": false}},
}

test_gke_labels_are_resource_labels if {
	count([m | some m in deny with input as {"resource_changes": [cluster({"env": "dev"})]}; contains(m, "labels-required")]) == 0
	some msg in deny with input as {"resource_changes": [cluster({})]}
	contains(msg, "labels-required")
}

test_deny_unprotected_production_by_label if {
	some msg in deny with input as {"resource_changes": [vm({"change": {"actions": create, "after": {"name": "app", "machine_type": "e2-micro", "labels": {"env": "prod"}, "deletion_protection": false}}})]}
	contains(msg, "deletion-protection")
}

test_deny_unprotected_production_by_name if {
	some msg in deny with input as {"resource_changes": [vm({"change": {"actions": create, "after": {"name": "prod-app-server", "machine_type": "e2-micro", "labels": {"team": "x"}, "deletion_protection": false}}})]}
	contains(msg, "deletion-protection")
}

test_dev_may_skip_deletion_protection if {
	count([m | some m in deny with input as {"resource_changes": [vm({})]}; contains(m, "deletion-protection")]) == 0
}

test_deny_bucket_without_versioning if {
	some msg in deny with input as {"resource_changes": [bucket({"name": "dev-b", "labels": {"env": "dev"}, "versioning": []})]}
	contains(msg, "bucket-versioning")
}

test_deny_bucket_with_versioning_disabled if {
	some msg in deny with input as {"resource_changes": [bucket({"name": "dev-b", "labels": {"env": "dev"}, "versioning": [{"enabled": false}]})]}
	contains(msg, "bucket-versioning")
}

# -- naming.rego -------------------------------------------------------------
test_deny_name_without_env_prefix if {
	some msg in deny with input as {"resource_changes": [bucket(object.union(good_bucket, {"name": "my-proj-assets"}))]}
	contains(msg, "naming-prefix")
}

test_deny_name_with_underscore if {
	some msg in deny with input as {"resource_changes": [bucket(object.union(good_bucket, {"name": "dev_assets"}))]}
	contains(msg, "naming-format")
}

# -- cost.rego ---------------------------------------------------------------
test_deny_expensive_machine_family if {
	some msg in deny with input as {"resource_changes": [vm({"change": {"actions": create, "after": {"name": "dev-x", "machine_type": "n2-standard-2", "labels": {"env": "dev"}}}})]}
	contains(msg, "cost-machine-type")
}

test_deny_big_boot_disk if {
	some msg in deny with input as {"resource_changes": [vm({"change": {"actions": create, "after": {"name": "dev-x", "machine_type": "e2-micro", "labels": {"env": "dev"}, "boot_disk": [{"initialize_params": [{"size": 900}]}]}}})]}
	contains(msg, "cost-disk-size")
}

test_deny_more_than_ten_vms if {
	vms := [vm({"address": sprintf("module.vm%d.google_compute_instance.this", [i])}) | some i in numbers.range(1, 11)]
	some msg in deny with input as {"resource_changes": vms}
	contains(msg, "cost-vm-limit")
}
