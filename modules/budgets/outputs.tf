output "budget_ids" {
  description = "Map of environment name to budget OCID"
  value       = { for k, v in oci_budget_budget.this : k => v.id }
}

output "forecast_alert_ids" {
  description = "Map of environment name to forecast alert rule OCID"
  value       = { for k, v in oci_budget_alert_rule.forecast : k => v.id }
}

output "actual_alert_ids" {
  description = "Map of environment name to actual spend alert rule OCID"
  value       = { for k, v in oci_budget_alert_rule.actual : k => v.id }
}
