# terraform-modules

**Tier 1 of 5 — HCL declarative IaC with Terragrunt DRY + OPA policy enforcement**

## Purpose

Baseline GCP infrastructure using Terraform HCL. Seven reusable modules (network, compute, storage, DNS, GKE, Cloud Run) composed per environment via Terragrunt. OPA Rego policies enforce naming, cost limits, and security rules at plan time.

## Position in the IaC spectrum

| Tier | Tool | Trade-off vs this tier |
|------|------|----------------------|
| **1 (this)** | Terraform + Terragrunt + OPA | Declarative, vendor-supported, largest ecosystem. DRY via Terragrunt. No real loops or abstraction — large state files at scale. |
| 2 | OpenTofu | Open-source fork (MPL-2.0 vs BUSL-1.1), adds state encryption and `tofu test`. Otherwise identical HCL. |
| 3 | Pulumi | Real language (TS/Python/Go) — full loops, types, unit tests. Steeper learning curve; smaller module registry than Terraform. |
| 4 | AWS CDK | Synthesizes to CloudFormation. AWS-only but deep L2/L3 construct library. Vendor lock-in trade-off. |
| 5 | Crossplane | Kubernetes-native control plane. GitOps-first, reconciliation loop — no CLI apply needed. High operational complexity. |

## Structure

```
modules/          # 7 reusable GCP modules (source-of-truth)
environments/     # dev / staging / prod — terragrunt.hcl per env
policy/           # OPA Rego policies (rego.v1 syntax — OPA 1.0+)
terragrunt.hcl    # Root DRY config: remote state, common inputs
```

## Running

```bash
# Prerequisites: terraform >= 1.5, terragrunt >= 0.50, conftest

export TF_VAR_project_id="your-gcp-project"
export GOOGLE_APPLICATION_CREDENTIALS="/path/to/sa.json"

# Plan dev
cd environments/dev
terragrunt plan

# Validate OPA policies
conftest test --policy ../../policy environments/dev/main.tf
```

## Key design decisions

- Terragrunt `remote_state` generates `backend.tf` at runtime — do **not** commit `backend.tf` in dev/staging/prod (already gitignored via `backend_generated.tf`).
- `ssh_source_ranges` defaults to private RFC-1918 ranges — OPA policy blocks `0.0.0.0/0`.
- Provider pinned `>= 5.0, < 7.0` to prevent silent breaking changes across major versions.
