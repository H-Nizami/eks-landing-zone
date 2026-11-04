#!/usr/bin/env bash
# Validate rendered local charts against the CRDs of the pinned upstream charts, using a
# server-side dry run on a disposable kind cluster. The cluster is always deleted.
set -euo pipefail
cd "$(dirname "$0")/.."
bin="$(pwd)/.bin"
tmp="$(mktemp -d)"
name="elz-crds-$$"
kubeconfig="$tmp/kubeconfig"
cleanup() {
  "$bin/kind" delete cluster --name "$name" > /dev/null 2>&1 || true
  rm -rf "$tmp"
}
trap cleanup EXIT
export HELM_CONFIG_HOME="$tmp/helm/config" HELM_CACHE_HOME="$tmp/helm/cache" HELM_DATA_HOME="$tmp/helm/data"
kube() { "$bin/kubectl" --kubeconfig "$kubeconfig" "$@"; }

version_of() {
  python3 -c 'import re,sys; print(re.search(r"chart = \"%s\", version = \"([^\"]+)\"" % sys.argv[1], open("modules/platform/main.tf").read()).group(1))' "$1"
}

"$bin/kind" create cluster --name "$name" --kubeconfig "$kubeconfig" --wait 120s

"$bin/helm" pull oci://public.ecr.aws/karpenter/karpenter-crd --version "$(version_of karpenter-crd)" --untar --untardir "$tmp/charts"
"$bin/helm" pull external-secrets --repo https://charts.external-secrets.io --version "$(version_of external-secrets)" --untar --untardir "$tmp/charts"
"$bin/helm" pull kyverno --repo https://kyverno.github.io/kyverno/ --version "$(version_of kyverno)" --untar --untardir "$tmp/charts"

"$bin/helm" template karpenter-crd "$tmp/charts/karpenter-crd" | kube apply --server-side -f -
"$bin/helm" template external-secrets "$tmp/charts/external-secrets" --set installCRDs=true --show-only templates/crds/clustersecretstore.yaml | kube apply --server-side -f -
"$bin/helm" template kyverno "$tmp/charts/kyverno" --show-only charts/kyverno-api/templates/crds/policies.kyverno.io_validatingpolicies.yaml | kube apply --server-side -f -
kube wait --for=condition=Established --timeout=60s crd/ec2nodeclasses.karpenter.k8s.aws crd/nodepools.karpenter.sh crd/clustersecretstores.external-secrets.io crd/validatingpolicies.policies.kyverno.io

for chart in modules/platform/charts/*/; do
  "$bin/helm" template "$(basename "$chart")" "$chart" | kube apply --dry-run=server -f -
done
echo 'test-crds: all rendered resources accepted'
