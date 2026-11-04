# Contributing

Terraform and OpenTofu EKS landing zone (VPC, EKS, bootstrap compute, Pod Identity, Karpenter, External Secrets, Kyverno). Every module is tested with both CLIs.

## Pinned versions

| Tool | Version | Where pinned |
|---|---|---|
| terraform | 1.17.0 | `scripts/tools.sh` |
| opentofu | 1.13.2 | `scripts/tools.sh` |
| tflint | v0.64.0 | `scripts/tools.sh` |
| checkov | 3.3.30 | `requirements-checkov.lock` |
| helm | v3.22.1 | `scripts/tools.sh` |
| kyverno CLI | v1.19.2 | `scripts/tools.sh` |
| kind | v0.33.0 | `scripts/tools.sh` |
| kubectl | v1.34.11 | `scripts/tools.sh` |
| d2 | v0.9.0 | `scripts/tools.sh` |
| actionlint | 1.7.12 | `scripts/tools.sh` |
| gitleaks | 8.30.1 | `scripts/tools.sh`, `security.yml` |
| trivy | v0.76.1 | `scripts/tools.sh`, `security.yml` |
| GitHub Actions | commit SHAs | workflow `uses:` lines; table in [`docs/pins.md`](docs/pins.md) |

Pin versions exactly. Check the upstream release notes and `--help` output before upgrading a tool or relying on a new flag.

## Conventions

- No secrets in the repo. Use placeholders only (for example account `000000000000`, `example.com`).
- No employer references.
- Don't publish numbers that were not measured. Unmeasured numbers in the README or diagram are marked `Not yet measured: …`.
- Pin every GitHub Action to a full commit SHA with a `# vX.Y.Z` comment.
- Workflows use least-privilege `permissions:` (top level `{}`, each job grants only what it needs).
- Commit the provider lock files in `locks/`; never commit state, plans or `.terraform/`.

## Commands

- `make tools`: install pinned binaries into `.bin/`.
- `make lint`: actionlint, shellcheck, `d2 validate`, hygiene checks, `fmt -check` with both CLIs, tflint.
- `make test`: hygiene and IaC safety checks, then the provider-mocked plan tests with terraform and tofu, then chart and policy checks.
- `make test-charts`: lint and render local charts, run Kyverno policy fixtures, check that pinned upstream charts resolve.
- `make test-crds`: server-side dry run of rendered charts against upstream CRDs on a disposable kind cluster (needs Docker).
- `make test-iac CLI=terraform|tofu`: run one CLI's plan tests.
- `make security`: local secret and configuration scanners.
- `make diagram`: render `docs/img/architecture.{svg,png}` (PNG 2400–4000 px wide, target 3000).
- `make up` / `make down`: disabled until a bounded, approved AWS deployment is planned.

## Layout

- `modules/`: VPC, EKS, compute, Karpenter, Pod Identity and platform modules, each with its own tests.
- `examples/foundation/` and `examples/platform/`: the two deployment roots.
- `policy-tests/`: Kyverno fixtures, including deliberately non-compliant pods excluded from Trivy.
- `locks/`: provider lock files per CLI.
- `docs/`: architecture diagram source, icons, rendered images, ADRs, pins, testing notes, security exceptions.
- `scripts/`: test runner, tool installer, diagram rendering, hygiene, safety and author checks.
- `.github/workflows/`: CI, security scans, author check.

## Definition of done

`make lint test diagram` is green and `actionlint` is clean.
