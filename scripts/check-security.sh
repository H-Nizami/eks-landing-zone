#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
if [ ! -x .venv/bin/checkov ]; then
  python3 -m venv .venv
  .venv/bin/python -m ensurepip --upgrade
  .venv/bin/python -m pip install --disable-pip-version-check --require-hashes -r requirements-checkov.lock
fi
.venv/bin/checkov -d . --framework terraform --skip-download --skip-path '^.cache/' --skip-path '^.venv/' --quiet
.bin/trivy config --cache-dir .cache/trivy --exit-code 1 --severity HIGH,CRITICAL --skip-dirs .bin --skip-dirs .venv --skip-dirs policy-tests .
.bin/gitleaks git --redact --exit-code 1 --config .gitleaks.toml .
