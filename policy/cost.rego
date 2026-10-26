# cost.rego — Cost control policies (OPA/Rego)
# Evaluated against: terraform show -json tfplan > tfplan.json
# Run: conftest test tfplan.json -p policy/
#
# Policies:
#   - Max 10 VMs per environment (per plan)
#   - Max disk size 500 GB
#   - Deny n1/n2 machine types (expensive)

package main

import rego.v1

# ---------------------------------------------------------------------------
# DENY: More than 10 VM creates/updates in a single plan
# ---------------------------------------------------------------------------
vm_changes := [rc |
	some rc in input.resource_changes
	rc.type == "google_compute_instance"
	rc.change.actions[_] in {"create", "update"}
]

deny contains msg if {
	count(vm_changes) > 10
	msg := sprintf(
		"DENY [cost-vm-limit]: Plan contains %d VM instances. Max allowed per plan is 10.",
		[count(vm_changes)],
	)
}

# ---------------------------------------------------------------------------
# DENY: Disk size exceeds 500 GB
# ---------------------------------------------------------------------------
deny contains msg if {
	some rc in input.resource_changes
	rc.type in {"google_compute_instance", "google_compute_disk"}
	rc.change.actions[_] in {"create", "update"}

	# Check boot disk inside compute instance
	rc.type == "google_compute_instance"
	disk := rc.change.after.boot_disk[_]
	init_params := disk.initialize_params[_]
	size := object.get(init_params, "size", 0)
	size > 500

	msg := sprintf(
		"DENY [cost-disk-size]: '%s' boot disk size %dGB exceeds max allowed 500GB.",
		[rc.address, size],
	)
}

deny contains msg if {
	some rc in input.resource_changes
	rc.type == "google_compute_disk"
	rc.change.actions[_] in {"create", "update"}
	size := object.get(rc.change.after, "size", 0)
	size > 500
	msg := sprintf(
		"DENY [cost-disk-size]: Disk '%s' size %dGB exceeds max allowed 500GB.",
		[rc.address, size],
	)
}

# ---------------------------------------------------------------------------
# DENY: n1 or n2 machine types (expensive; use e2 equivalents)
# ---------------------------------------------------------------------------
expensive_machine_prefixes := {"n1-", "n2-", "n2d-", "c2-", "c2d-", "m1-", "m2-", "m3-"}

deny contains msg if {
	some rc in input.resource_changes
	rc.type == "google_compute_instance"
	rc.change.actions[_] in {"create", "update"}
	machine_type := rc.change.after.machine_type
	some prefix in expensive_machine_prefixes
	startswith(machine_type, prefix)
	msg := sprintf(
		"DENY [cost-machine-type]: '%s' uses expensive machine_type '%s'. Use e2-* equivalents.",
		[rc.address, machine_type],
	)
}
