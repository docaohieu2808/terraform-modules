#!/usr/bin/env bash
# Level 3: state is the source of truth. Apply "before", then switch to "after" (a rename + moved
# block) and prove the plan only moves the address: zero creates, zero destroys.
# Usage: ./demo.sh   (TF=tofu ./demo.sh to run it with OpenTofu)
set -euo pipefail

TF=${TF:-terraform}
here=$(cd "$(dirname "$0")" && pwd)
work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT

cp "$here/before/main.tf" "$work/main.tf"
"$TF" -chdir="$work" init -input=false >/dev/null
"$TF" -chdir="$work" apply -auto-approve -input=false >/dev/null
echo "state after apply:"
"$TF" -chdir="$work" state list

cp "$here/after/main.tf" "$work/main.tf"
"$TF" -chdir="$work" plan -input=false -out=plan.bin >/dev/null
"$TF" -chdir="$work" show -json plan.bin >"$work/plan.json"

# The only resource change must be a no-op that records where it moved from.
python3 - "$work/plan.json" <<'PY'
import json, sys
changes = json.load(open(sys.argv[1]))["resource_changes"]
assert len(changes) == 1, changes
change = changes[0]
assert change["change"]["actions"] == ["no-op"], change["change"]["actions"]
assert change["previous_address"] == "terraform_data.old_name", change
assert change["address"] == "terraform_data.new_name", change
print("OK: terraform_data.old_name -> terraform_data.new_name is a pure state move (no destroy/create)")
PY

"$TF" -chdir="$work" apply -auto-approve -input=false plan.bin >/dev/null
"$TF" -chdir="$work" state list
"$TF" -chdir="$work" destroy -auto-approve -input=false >/dev/null
