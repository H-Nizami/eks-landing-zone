# 0002. One module set, tested with both terraform and tofu

## Status

Accepted (2026-10-22)

## Context

Teams that adopt this landing zone run either HashiCorp Terraform or OpenTofu, and some are mid-migration between the two. The CLIs share the HCL language and most provider behaviour, but they are diverging: each adds features the other lacks, and lock files and state handling can differ. Maintaining two copies of the modules would double the work and let them drift.

## Decision

- Keep one set of modules (vpc, eks, karpenter, addons).
- Use only language features both CLIs support at the pinned versions (terraform 1.17, OpenTofu 1.13).
- CI runs a matrix: `init`, `validate` and `plan` with both CLIs on every change, plus tflint, trivy and checkov.
- A feature that only one CLI supports needs a new ADR before use.

## Consequences

- Users can pick either CLI without forking the modules.
- Some newer features of either tool stay off-limits until both support them.
- CI time roughly doubles for the plan stage; static analysis runs once.
- Real `apply` runs are short and rare because the EKS control plane is billed hourly (see README Limits); most proof comes from `validate`/`plan`.
