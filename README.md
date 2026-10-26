# terraform-modules

**Tier 1 of 5 in a zero-to-max Infrastructure-as-Code ladder: Terraform + Terragrunt + OPA policy-as-code.**

[![ci](https://github.com/docaohieu2808/terraform-modules/actions/workflows/ci.yml/badge.svg)](https://github.com/docaohieu2808/terraform-modules/actions/workflows/ci.yml)

Six reusable GCP modules (network, compute, storage, DNS, GKE, Cloud Run), three environments
(dev / staging / prod) wired together with Terragrunt, and OPA/Rego policies that check a Terraform
plan before anything is applied. The first three levels need no cloud at all, so the whole ladder runs
(and is tested) on a laptop or a free CI runner.

## Level map

| Level | Folder | You learn | How it is proven |
|-------|--------|-----------|------------------|
| L1 | `levels/l1-local-basics` | resources, variables + validation, outputs, providers (`random`, `local`) | `terraform test` applies for real |
| L2 | `levels/l2-modules-for-each` | child modules, `for_each`, `templatefile`, collection outputs | `terraform test` applies for real |
| L3 | `levels/l3-state-moved` | state as source of truth, `moved` refactors without destroy/create | `demo.sh` asserts the plan JSON is a pure no-op move |
| L4 | `modules/*` | production-style GCP modules, provider v8, validation rules | `validate` + `terraform test` with a **mocked** google provider |
| L5 | `environments/*` | composing modules per environment | offline `terraform plan` with a fake token, then L6 policies on the plan |
| L6 | `root.hcl`, `environments/*/terragrunt.hcl`, `policy/` | Terragrunt DRY config, generated backend, OPA policies + unit tests | `terragrunt` render/validate, `opa test`, `conftest` on real plan JSON |

Where this tier sits in the whole ladder:

| Tier | Tool | Trade-off vs this tier |
|------|------|------------------------|
| **1 (this)** | Terraform + Terragrunt + OPA | Declarative, largest ecosystem and vendor support. DRY comes from Terragrunt, not the language. |
| 2 | OpenTofu (`opentofu-modules`) | Open-source fork (MPL-2.0; Terraform is BUSL-1.1), adds state encryption. Otherwise the same HCL. |
| 3 | Pulumi | A real programming language: loops, types, unit tests. Steeper curve, smaller module registry. |
| 4 | AWS CDK | Synthesizes to CloudFormation. AWS only, deep construct library. |
| 5 | Crossplane | Kubernetes-native control plane with a reconciliation loop. Powerful, operationally heavy. |

## Layout

```
levels/                    L1-L3: local-only exercises (no cloud, no credentials)
modules/                   L4: 6 reusable GCP modules, each with required_version and provider ~> 8.0
  gcp-network|compute|storage|gke/tests/   terraform test files (mock_provider "google")
environments/{dev,staging,prod}/            L5: compose the modules
root.hcl                   L6: shared Terragrunt config (generated GCS backend, common inputs)
policy/                    L6: OPA/Rego (rego.v1) policies + policy_test.rego
.github/workflows/ci.yml   everything above, on every push and weekly
```

## Running it

Versions used and tested: Terraform 1.17.0, google provider 8.x (`~> 8.0`, locked in
`.terraform.lock.hcl` for linux/mac/windows), Terragrunt 1.2.1, OPA 1.21, conftest 0.71.

```bash
# L1 / L2: real applies on your machine, cleaned up by the test runner
cd levels/l1-local-basics && terraform init && terraform test
cd ../l2-modules-for-each  && terraform init && terraform test
# L3: rename a resource with a moved block and prove nothing is destroyed
levels/l3-state-moved/demo.sh            # TF=tofu levels/l3-state-moved/demo.sh also works

# L4: unit-test a module with the cloud mocked away
cd modules/gcp-network && terraform init -backend=false && terraform test

# L5: offline plan of an environment. A fake token is enough because planning new
# resources makes no API call; use real credentials only when you want to apply.
export GOOGLE_OAUTH_ACCESS_TOKEN=fake TF_VAR_project_id=example-lab-project
cd environments/dev && terraform init -backend=false
terraform plan -out=tfplan

# L6: policy-as-code on the plan. The policies read the plan JSON (input.resource_changes),
# NOT the .tf files:
terraform show -json tfplan > plan.json
conftest test plan.json -p ../../policy
opa test ../../policy                    # unit tests of the policies themselves
```

### Real deployments with Terragrunt

```bash
export TF_VAR_project_id="your-gcp-project"
export GOOGLE_APPLICATION_CREDENTIALS="/path/to/sa.json"
cd environments/dev
terragrunt backend bootstrap     # creates the state bucket once (see "State bucket" below)
terragrunt plan
terragrunt apply
```

## Design decisions (and the bugs they fixed)

- **Provider `~> 8.0`**, `required_version >= 1.10` everywhere (modules included). The old `>= 5, < 7`
  range meant the repo never used a current provider. Moving to v8 was validated and planned offline.
- **State bucket lives outside the stack it stores.** The bucket used to be a module inside the dev
  environment, i.e. dev's state tracked the bucket that held dev's state (and it broke the naming
  policy). It is now bootstrapped by Terragrunt (`terragrunt backend bootstrap`, a flag/command that
  Terragrunt 1.x requires explicitly), so `destroy` in dev can never delete its own state.
- **`backend.tf` is generated, never committed.** `root.hcl` generates it; the two committed copies that
  made Terragrunt fail with "file exists and was not generated by terragrunt" are gone and
  `backend.tf` is git-ignored. The root file is `root.hcl` (Terragrunt's current convention) and every
  environment includes it with `find_in_parent_folders("root.hcl")`.
- **Terragrunt copies the stack into `.terragrunt-cache`**, which broke the relative `../../modules/*`
  sources. `root.hcl` sets `terraform { source = "<repo root>//environments/<env>" }` so the modules
  come along.
- **SSH never defaults to the internet.** `gcp-network` defaults to the RFC 1918 ranges and rejects
  `0.0.0.0/0` for SSH with a validation block (covered by `terraform test`). The personal SSH key that
  was hard-coded in `dev/terragrunt.hcl` is now the optional `TF_VAR_ssh_public_key`.
- **Policies were fixed by testing them.** Running conftest against real plan JSON showed:
  `is_production` could never match (a Terraform address never contains the environment);
  `labels-required` silently passed when `labels` was `null` and could never be satisfied on GKE
  (`resource_labels`) or node pools (`node_config.labels`); the public-SSH rule missed plans where the
  computed `direction` is absent; and the duplicated SSH rule is now one rule that also understands
  port ranges. 20 `opa test` cases cover every deny rule, and CI proves a non-compliant plan is rejected.
- **A real GKE bug surfaced by the offline plan:** the provider rejects `remove_default_node_pool`
  together with *any* `enable_autopilot` value, even `false`; the module now passes `null` for Standard
  clusters. Environment resources are also named/labelled the way the policies require.
- **Credentials**: the provider takes `credentials = null` when `credentials_file` is empty, so
  Application Default Credentials work.

## What CI checks

`.github/workflows/ci.yml` runs on push, pull request, `workflow_dispatch` and every Monday 02:23 UTC:

| Job | Checks |
|-----|--------|
| `lint` | `terraform fmt -check`, `tflint` (recommended preset), `opa fmt`, `opa check --strict` |
| `validate` | `init -backend=false -lockfile=readonly` + `validate` for 3 environments, 6 modules, L1, L2 |
| `test` | `terraform test` with mocked google provider (network, compute, storage, gke), real-apply tests for L1/L2, the L3 demo |
| `policy` | `opa test`, offline plan of dev/staging/prod -> `conftest` on the plan JSON, and a negative test (SSH open to the world must be rejected) |
| `terragrunt` | `hcl fmt --check`, `render`, `init -backend=false` + `validate` through Terragrunt, generated `backend.tf` present |

## Honest limits

- Nothing is applied to a real cloud in CI. `terraform apply` of the GCP modules, the state-bucket
  bootstrap and remote state locking need a GCP project and are validated only up to a plan.
- `gcp-dns` and `gcp-cloud-run` have `validate` coverage but no mocked unit tests yet.
- The mocked tests assert configuration the modules control; values the cloud computes (IPs, self links)
  are unknown at plan time and are not asserted.
- Tool versions are pinned in `ci.yml` (Dependabot updates the actions and the Terraform lock files);
  bump the `env:` versions deliberately.
