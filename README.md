# eks-landing-zone

[![ci](https://github.com/H-Nizami/eks-landing-zone/actions/workflows/ci.yml/badge.svg)](https://github.com/H-Nizami/eks-landing-zone/actions/workflows/ci.yml)

> **Result:** 41/41 mocked plan tests pass with Terraform 1.17 and OpenTofu 1.13, 10/10 Kyverno policy fixture checks pass, and all rendered local charts are accepted against the upstream CRDs on kind. Not yet measured: live deploy and teardown cost after an approved AWS run.

Terraform and OpenTofu EKS landing zone for agent and LLM workloads: a private cluster, bootstrap capacity, Karpenter, External Secrets and Kyverno, all with exact versions. It has been verified offline only and has not been deployed to AWS yet.

![Architecture](docs/img/architecture.png)

## Architecture

The same modules and mock-provider plan tests run with Terraform 1.17 and OpenTofu 1.13. The VPC spans three availability zones and gives private subnets NAT egress. EKS uses only those private subnets, a private API endpoint, encrypted logs and secrets, and an explicit operator access entry. Optional Pod Identity restricts a workload role to a specific cluster, namespace, service account and secret ARNs.

Deployment has two stages, because Helm needs a network path to the private API ([ADR 0004](docs/decisions/0004-two-stage-deployment.md)):

| Stage | Root | Contents |
|---|---|---|
| Foundation | [`examples/foundation`](examples/foundation) | VPC, EKS, tainted bootstrap node group, pinned core add-ons, Karpenter IAM, interruption queue and discovery tags, optional secrets role |
| Platform | [`examples/platform`](examples/platform) | Karpenter 1.15.1 with a default node pool, External Secrets 2.14.0 with a cluster secret store, Kyverno 1.19.2 with baseline admission policies |

Nodes require IMDSv2 with hop limit 1 and encrypted root volumes. Kyverno denies pods without resource requests, privileged containers, host namespaces and floating image tags outside the system namespaces.

Orange boxes are built in this repo; grey boxes are AWS services and existing projects. Diagram source: [`docs/architecture.d2`](docs/architecture.d2).

## Quickstart

```bash
make tools     # install pinned tools into .bin/
make diagram   # render docs/img/architecture.{svg,png}
make lint test
make test-crds # needs Docker
make security
```

`make test-iac CLI=terraform` and `make test-iac CLI=tofu` run the offline suites individually. See [testing notes](docs/testing.md) and [example inputs](examples/foundation/terraform.tfvars.example). `make up` and `make down` intentionally fail pending deployment approval. No credentials are required for the mocked tests.

## Design decisions

- [0001: Record decisions as short ADRs](docs/decisions/0001-record-decisions.md)
- [0002: One module set, tested with both terraform and tofu](docs/decisions/0002-terraform-and-opentofu.md)
- [0003: Validate the foundation offline first](docs/decisions/0003-offline-foundation.md)
- [0004: Deploy in two stages](docs/decisions/0004-two-stage-deployment.md)
- [Pinned action SHAs and tool versions](docs/pins.md)

## Limits

- The EKS control plane is billed hourly, so real deploys are short and rare; most testing is `validate`, `plan` and static analysis.
- The module set targets a single AWS account and region.
- Nothing here has been applied to AWS. The tests prove configuration contracts, not AWS acceptance, node joins or scaling behavior.
- The private API needs a network path for operators, such as a VPN or a host inside the VPC. This repo does not create one.
- The Pod Identity agent add-on version is a required input, because AWS publishes no public version table for it.

## How I'd do this for your team

- Discovery: review your current AWS accounts, network layout, IAM model and which CLI (terraform or OpenTofu) you run.
- Adapt: fit the modules to your CIDR plan, node pool shapes, secret stores and admission policies.
- Prove: run the plan matrix in your CI and a short, torn-down deploy in a sandbox account.
- Hand-over: runbooks for upgrades (EKS, Karpenter, add-ons), adding a workload role, and rotating secrets.

## Status

| Stage | Scope | Status |
|---|---|---|
| Scaffold | Repo standards, CI, cover diagram | Done |
| Offline foundation | VPC/EKS/Pod Identity modules and offline dual-CLI tests | Done |
| Compute and add-ons | Bootstrap nodes, core add-ons, Karpenter, External Secrets, Kyverno, offline tests | Done |
| Live deploy | Short real deploy, cost record and teardown | Planned (needs AWS credits) |

## License

Apache-2.0. See LICENSE.
