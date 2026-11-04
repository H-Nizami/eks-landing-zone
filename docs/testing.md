# Offline verification

On 2026-11-02, Terraform 1.17.0 and OpenTofu 1.13.2 each passed 23 provider-mocked `command = plan` test runs across the VPC, EKS, Pod Identity and composed example. Both CLIs validated all four roots with pinned AWS provider 6.70.0. The engines use separate signed provider locks under `locks/`; `scripts/test-iac.sh` copies source into an isolated temporary workspace for each run. No AWS credentials or cloud resources were used.

`make lint` passed.

A deliberate regression flipped `endpoint_public_access` to true in the EKS module. `terraform test` exited 1 with both private-endpoint assertions failing. The source was immediately restored; `terraform fmt -check` passed afterward.

On 2026-11-04 the suite was extended to bootstrap compute, Karpenter IAM and the Helm platform layer: 41 provider-mocked plan runs with each CLI across eight roots. Kyverno 1.19.2 ran 10 fixture checks against the rendered policies. A kind cluster accepted every rendered local chart in a server-side dry run against the CRDs of the pinned upstream charts.

Two deliberate regressions confirmed that the tests detect failures. Setting `http_tokens` to `optional` failed the IMDSv2 assertion in the compute module. Disabling the privileged-container expression failed one Kyverno fixture check. Both changes were reverted.

Checkov 3.3.30 reported 113 passed, zero failed and four narrowly skipped checks (see `docs/security-exceptions.md`). Trivy's high/critical configuration scan was clean, excluding `policy-tests/`, whose pods are deliberately non-compliant. Gitleaks found nothing.

These are configuration tests. They do not demonstrate that AWS accepted an apply, that nodes join, that Karpenter scales, that Pod Identity serves running pods, or that the upstream charts run with these values. Live cost and teardown evidence remain unmeasured.
