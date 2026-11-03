#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
cli="${1:-terraform}"
case "$cli" in terraform|tofu) ;; *) echo 'Use terraform or tofu' >&2; exit 2;; esac
if [ -x ".bin/$cli" ]; then bin="$(pwd)/.bin/$cli"; else bin="$(command -v "$cli")"; fi
python3 scripts/check-iac-safety.py
"$bin" fmt -check -recursive .
tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT
tar -cf - --exclude=.terraform modules examples | tar -xf - -C "$tmp"
for dir in modules/vpc modules/eks modules/pod-identity examples/foundation; do
  cp "locks/$cli.lock.hcl" "$tmp/$dir/.terraform.lock.hcl"
  "$bin" -chdir="$tmp/$dir" init -backend=false -input=false -lockfile=readonly
  "$bin" -chdir="$tmp/$dir" validate
  "$bin" -chdir="$tmp/$dir" test
done
