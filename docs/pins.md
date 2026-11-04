# Pinned versions

Looked up on 2026-10-22. GitHub Actions are pinned to the full commit SHA the release tag resolves to (`gh api repos/<owner>/<repo>/commits/<tag> --jq .sha`). Binaries are pinned to an exact version and verified against the sha256 in the project's published checksums file (see `scripts/tools.sh`).

## GitHub Actions

| Action | Tag | Commit SHA | Looked up |
|---|---|---|---|
| `actions/checkout` | v7.0.1 | `3d3c42e5aac5ba805825da76410c181273ba90b1` | 2026-10-22 |
| `actions/setup-python` | v7.1.0 | `6d4fd22b20465ccc0f7354476588e8df7c9ca0e0` | 2026-10-22 |
| `actions/upload-artifact` | v7.0.2 | `cf430e030ddbb5b0abf93d22962f4752f3646cd9` | 2026-10-22 |

## Binaries (`scripts/tools.sh`)

| Tool | Version | Checksums file |
|---|---|---|
| d2 | v0.9.0 | https://github.com/terrastruct/d2/releases/download/v0.9.0/SHA256SUMS |
| actionlint | 1.7.12 | https://github.com/rhysd/actionlint/releases/download/v1.7.12/actionlint_1.7.12_checksums.txt |
| gitleaks | 8.30.1 | https://github.com/gitleaks/gitleaks/releases/download/v8.30.1/gitleaks_8.30.1_checksums.txt |
| trivy | 0.76.1 | https://github.com/aquasecurity/trivy/releases/download/v0.76.1/trivy_0.76.1_checksums.txt |
| Terraform | 1.17.0 | https://releases.hashicorp.com/terraform/1.17.0/terraform_1.17.0_SHA256SUMS |
| OpenTofu | 1.13.2 | https://github.com/opentofu/opentofu/releases/download/v1.13.2/tofu_1.13.2_SHA256SUMS |
| TFLint | 0.64.0 | https://github.com/terraform-linters/tflint/releases/download/v0.64.0/checksums.txt |
| Helm | 3.22.1 | https://get.helm.sh/helm-v3.22.1-linux-amd64.tar.gz.sha256sum (one file per platform) |
| Kyverno CLI | 1.19.2 | https://github.com/kyverno/kyverno/releases/download/v1.19.2/checksums.txt |
| kind | 0.33.0 | Release assets at https://github.com/kubernetes-sigs/kind/releases/tag/v0.33.0 |
| kubectl | 1.34.11 | https://dl.k8s.io/release/v1.34.11/bin/linux/amd64/kubectl.sha256 (one file per platform) |

The AWS provider is pinned to 6.70.0 in every root. The initial 6.71.0 target
could not be downloaded in this environment; 6.70.0 is available in verified
local provider caches. Terraform and OpenTofu
must retain their own signed registry-derived lock files; checksum sets can
differ by registry and should never be rewritten by hand. Checkov is pinned to
3.3.30 with transitively hashed requirements in `requirements-checkov.lock`.

Sums are hardcoded for `darwin-arm64`, `darwin-amd64`, `linux-amd64` and `linux-arm64`. Other platforms fail with a clear error.

## Platform versions

Looked up on 2026-11-04.

| Component | Version | Source |
|---|---|---|
| Kubernetes | 1.36 | EKS standard support until August 2, 2027; newest version in the Karpenter compatibility matrix |
| Helm provider | 3.3.0 | Separate lock files: `locks/*.platform.lock.hcl` |
| Karpenter and karpenter-crd charts | 1.15.1 | https://github.com/aws/karpenter-provider-aws/releases/tag/v1.15.1 |
| External Secrets chart | 2.14.0 | https://github.com/external-secrets/external-secrets/releases/tag/helm-chart-2.14.0 |
| Kyverno chart | 3.9.2 (app v1.19.2) | https://github.com/kyverno/kyverno/releases/tag/v1.19.2 |
| EKS node AMI alias | `al2023@v20261031` | https://github.com/awslabs/amazon-eks-ami/releases/tag/v20261031 |
| VPC CNI add-on | v1.23.2-eksbuild.8 | https://docs.aws.amazon.com/eks/latest/userguide/managing-vpc-cni.html |
| kube-proxy add-on | v1.36.0-eksbuild.58 | https://docs.aws.amazon.com/eks/latest/userguide/managing-kube-proxy.html |
| CoreDNS add-on | v1.14.7-eksbuild.22 | https://docs.aws.amazon.com/eks/latest/userguide/managing-coredns.html |
| Pod Identity agent add-on | Required input | No public version table; use `aws eks describe-addon-versions` |

AWS add-on availability can change by region. Confirm these versions with `aws eks describe-addon-versions` before a deployment.
