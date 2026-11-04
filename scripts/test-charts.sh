#!/usr/bin/env bash
# Offline checks for local charts and Kyverno policies, plus a check that every pinned upstream chart exists.
set -euo pipefail
cd "$(dirname "$0")/.."
helm="$(pwd)/.bin/helm"
kyverno="$(pwd)/.bin/kyverno"
tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT
export HELM_CONFIG_HOME="$tmp/helm/config" HELM_CACHE_HOME="$tmp/helm/cache" HELM_DATA_HOME="$tmp/helm/data"

for chart in modules/platform/charts/*/; do
  "$helm" lint --strict "$chart"
  "$helm" template "$(basename "$chart")" "$chart" > "$tmp/$(basename "$chart").yaml"
done

# Unsafe settings must never render.
grep -q 'httpTokens: required' "$tmp/karpenter-config.yaml"
grep -q 'encrypted: true' "$tmp/karpenter-config.yaml"
if grep -q '@latest' "$tmp/karpenter-config.yaml"; then
  echo 'test-charts: the node class must not use a floating AMI alias' >&2
  exit 1
fi

cp -R policy-tests "$tmp/policy-tests"
cp "$tmp/kyverno-policies.yaml" "$tmp/policy-tests/policies.yaml"
"$kyverno" test "$tmp/policy-tests"

# Each upstream version in modules/platform/main.tf must resolve.
python3 - <<'PY' > "$tmp/charts.txt"
import re
source = open("modules/platform/main.tf").read()
for repository, chart, version in re.findall(r'repository = "([^"]+)", chart = "([^"]+)", version = "([^"]+)"', source):
    print(repository, chart, version)
PY
[ -s "$tmp/charts.txt" ]
while read -r repository chart version; do
  case "$repository" in
    oci://*) "$helm" show chart "$repository/$chart" --version "$version" > /dev/null ;;
    *) "$helm" show chart "$chart" --repo "$repository" --version "$version" > /dev/null ;;
  esac
  echo "test-charts: $chart $version resolves"
done < "$tmp/charts.txt"
