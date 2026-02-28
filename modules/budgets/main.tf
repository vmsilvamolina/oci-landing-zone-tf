##############################################################################
# Module: budgets
# Description: Creates OCI Budget resources with forecast-based alert rules
#              per environment compartment. Helps teams track and control
#              cloud spend from day one.
##############################################################################

terraform {
  required_providers {
    oci = {
      source  = "oracle/oci"
      version = ">= 5.0"
    }
  }
  required_version = ">= 1.5"
}

# ---------------------------------------------------------------------------
# Budget resources
# One budget per environment compartment target
# ---------------------------------------------------------------------------
resource "oci_budget_budget" "this" {
  for_each = var.budgets

  compartment_id = var.tenancy_ocid
  display_name   = "lz-budget-${each.key}"
  description    = "Landing Zone managed budget for ${each.key} environment"

  amount       = each.value.amount
  reset_period = each.value.reset_period
  budget_processing_period_start_offset = 1  # Start from the 1st of each month

  target_type = "COMPARTMENT"
  targets     = [each.value.compartment_ocid]

  freeform_tags = merge(var.tags, {
    "lz-managed"   = "true"
    "lz-budget-env" = each.key
  })
}

# ---------------------------------------------------------------------------
# Alert rules — one FORECAST alert and one ACTUAL alert per budget
# FORECAST: triggers before you hit the limit (early warning)
# ACTUAL:   triggers when you've already spent the threshold
# ---------------------------------------------------------------------------
resource "oci_budget_alert_rule" "forecast" {
  for_each = var.budgets

  budget_id    = oci_budget_budget.this[each.key].id
  display_name = "lz-alert-forecast-${each.key}"
  description  = "Forecast alert: ${each.key} is projected to exceed ${each.value.forecast_threshold_percent}% of budget"

  type           = "FORECAST"
  threshold      = each.value.forecast_threshold_percent
  threshold_type = "PERCENTAGE"

  recipients = var.alert_email
  message    = "[OCI LZ] FORECAST ALERT: The ${each.key} environment is projected to reach ${each.value.forecast_threshold_percent}% of its $${each.value.amount} monthly budget. Please review resource consumption."
}

resource "oci_budget_alert_rule" "actual" {
  for_each = var.budgets

  budget_id    = oci_budget_budget.this[each.key].id
  display_name = "lz-alert-actual-${each.key}"
  description  = "Actual spend alert: ${each.key} has exceeded ${each.value.actual_threshold_percent}% of budget"

  type           = "ACTUAL"
  threshold      = each.value.actual_threshold_percent
  threshold_type = "PERCENTAGE"

  recipients = var.alert_email
  message    = "[OCI LZ] ACTUAL SPEND ALERT: The ${each.key} environment has consumed ${each.value.actual_threshold_percent}% of its $${each.value.amount} monthly budget. Review and take action if needed."
}
