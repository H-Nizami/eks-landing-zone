output "chart_versions" { value = { for name, chart in local.charts : name => chart.version } }
