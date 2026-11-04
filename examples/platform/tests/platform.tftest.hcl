mock_provider "helm" {}
run "composed_platform" {
  command = plan
  assert {
    condition     = output.chart_versions.karpenter == "1.15.1" && output.chart_versions.kyverno == "3.9.2" && output.chart_versions.external_secrets == "2.14.0"
    error_message = "The example must install the pinned charts."
  }
}
