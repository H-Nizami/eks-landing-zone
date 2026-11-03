# Icon sources

Icons used by `docs/architecture.d2`, vendored unmodified. One row per file.

AWS icons come from the AWS Architecture Icons package, archive URL
`https://d1.awsstatic.com/onedam/marketing-channels/website/public/shared/architecture-icon-release/Icon-package_07312026.5846e92413caa21490223536cc97f1269e44fa92.zip`
(linked from https://aws.amazon.com/architecture/icons/). Terms as stated on that page: "We allow customers and partners to use these toolkits and assets to create architecture diagrams."

| File | Source URL | License / terms | License URL | Fetched |
|---|---|---|---|---|
| `AWS-Cloud-logo_32.svg` | AWS Architecture Icons package (archive above), path `Architecture-Group-Icons_07312026/AWS-Cloud-logo_32.svg` | AWS Architecture Icons terms ("We allow customers and partners to use these toolkits and assets to create architecture diagrams.") | https://aws.amazon.com/architecture/icons/ | 2026-10-22 |
| `Arch_Amazon-Virtual-Private-Cloud_64.svg` | AWS Architecture Icons package (archive above), path `Architecture-Service-Icons_07312026/Arch_Networking-Content-Delivery/64/Arch_Amazon-Virtual-Private-Cloud_64.svg` | AWS Architecture Icons terms (as above) | https://aws.amazon.com/architecture/icons/ | 2026-10-22 |
| `Arch_Amazon-Elastic-Kubernetes-Service_64.svg` | AWS Architecture Icons package (archive above), path `Architecture-Service-Icons_07312026/Arch_Containers/64/Arch_Amazon-Elastic-Kubernetes-Service_64.svg` | AWS Architecture Icons terms (as above) | https://aws.amazon.com/architecture/icons/ | 2026-10-22 |
| `Arch_AWS-Identity-and-Access-Management_64.svg` | AWS Architecture Icons package (archive above), path `Architecture-Service-Icons_07312026/Arch_Security-Identity/64/Arch_AWS-Identity-and-Access-Management_64.svg` | AWS Architecture Icons terms (as above) | https://aws.amazon.com/architecture/icons/ | 2026-10-22 |
| `Arch_AWS-Secrets-Manager_64.svg` | AWS Architecture Icons package (archive above), path `Architecture-Service-Icons_07312026/Arch_Security-Identity/64/Arch_AWS-Secrets-Manager_64.svg` | AWS Architecture Icons terms (as above) | https://aws.amazon.com/architecture/icons/ | 2026-10-22 |
| `workflow-24.svg` | https://raw.githubusercontent.com/primer/octicons/ad7dcd0ec8659f89fc1972dc6c65c571f99c950e/icons/workflow-24.svg | MIT License (primer/octicons) | https://github.com/primer/octicons/blob/main/LICENSE | 2026-10-22 |
| `karpenter-logo.png` | https://raw.githubusercontent.com/aws/karpenter-provider-aws/7f9fadd85f1f582acd721168506fafa7adea2f9c/website/static/logo.png | Apache License 2.0 (aws/karpenter-provider-aws repository license) for the file; Apache-2.0 §6 grants no trademark rights; the logo is used as a mark under nominative use | https://github.com/aws/karpenter-provider-aws/blob/main/LICENSE | 2026-10-22 |
| `kyverno-icon-color.png` | https://raw.githubusercontent.com/cncf/artwork/b4b5989332c822ef09d5b38a512e2b39c63e32f2/projects/kyverno/icon/color/kyverno-icon-color.png | Linux Foundation trademark usage guidelines (cncf/artwork LICENSE.md: "All artwork in this repo is made available under the Linux Foundation trademark usage guidelines") | https://github.com/cncf/artwork/blob/main/LICENSE.md ; https://www.linuxfoundation.org/trademark-usage | 2026-10-22 |

Notes:
- Karpenter and Kyverno use the official PNG files rather than SVG: d2 v0.9.0 PNG export rejects the Karpenter SVG (`duplicate id`) and the Kyverno SVG (`unsupported stylesheet selector`).
- No Anthropic or Claude logo is used.
- Octicons are MIT-licensed; the copyright and permission notice ships next to them in [`LICENSE-octicons.txt`](LICENSE-octicons.txt) (copied from primer/octicons at `ad7dcd0ec8659f89fc1972dc6c65c571f99c950e`).

Logos are trademarks of their owners and are used only to identify the project (nominative use); no endorsement implied.
