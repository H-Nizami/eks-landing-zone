#!/usr/bin/env python3
"""Reject tests that could reach a live provider or default to apply."""
from pathlib import Path
import re
import sys

roots = {
    Path("modules/vpc"): "aws",
    Path("modules/eks"): "aws",
    Path("modules/compute"): "aws",
    Path("modules/karpenter"): "aws",
    Path("modules/pod-identity"): "aws",
    Path("modules/platform"): "helm",
    Path("examples/foundation"): "aws",
    Path("examples/platform"): "helm",
}
errors = []
vpc_source = (Path("modules/vpc") / "main.tf").read_text()
if not re.search(r"nat_gateway_id\s*=\s*aws_nat_gateway\.this\[var\.single_nat\s*\?\s*local\.nat_az\s*:\s*each\.key\]\.id", vpc_source):
    errors.append("modules/vpc/main.tf: private routes must target the local NAT or the explicit single-NAT AZ")
if not re.search(r"route_table_id\s*=\s*aws_route_table\.private\[each\.key\]\.id", vpc_source):
    errors.append("modules/vpc/main.tf: private subnet associations must use same-AZ route tables")
for root, provider in roots.items():
    tests = list((root / "tests").glob("*.tftest.hcl"))
    if not tests:
        errors.append(f"{root}: no tests")
    for path in tests:
        source = path.read_text()
        if not re.search(rf'(?m)^mock_provider\s+"{provider}"\s*\{{', source):
            errors.append(f"{path}: missing {provider} mock provider")
        runs = list(re.finditer(r'(?m)^run\s+"[^"]+"\s*\{', source))
        if not runs:
            errors.append(f"{path}: no runs")
        for index, run in enumerate(runs):
            block = source[run.end():runs[index + 1].start() if index + 1 < len(runs) else len(source)]
            if not re.search(r'(?m)^\s*command\s*=\s*plan\s*$', block):
                errors.append(f"{path}: {run.group().strip()} does not explicitly plan")
if errors:
    print("\n".join(errors), file=sys.stderr)
    sys.exit(1)
print("check-iac-safety: all test runs use plan and a mocked provider")
