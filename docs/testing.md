# Offline verification

On 2026-11-02, Terraform 1.17.0 and OpenTofu 1.13.2 each passed 23 provider-mocked `command = plan` test runs across the VPC, EKS, Pod Identity and composed example. Both CLIs validated all four roots with pinned AWS provider 6.70.0. The engines use separate signed provider locks under `locks/`; `scripts/test-iac.sh` copies source into an isolated temporary workspace for each run. No AWS credentials or cloud resources were used.

`make lint` passed. Checkov 3.3.30 reported 71 passed, zero failed and three narrowly skipped checks (the three NAT gateway EIPs; see `docs/security-exceptions.md`). Trivy's high/critical configuration scan was clean. Gitleaks scanned committed history with no findings. The hash-locked local Checkov install was still downloading when this note was written; the scan used the already installed 3.3.30 binary in the sibling portfolio repo. CI will install from `requirements-checkov.lock` in its own environment.

A deliberate regression flipped `endpoint_public_access` to true in the EKS module. `terraform test` exited 1 with both private-endpoint assertions failing. The source was immediately restored; `terraform fmt -check` passed afterward.

These are configuration tests. They do not demonstrate that AWS accepted an apply, that Pod Identity serves running pods, or that this foundation is deployable without the planned nodes and add-ons. Live cost and teardown evidence remain unmeasured.
