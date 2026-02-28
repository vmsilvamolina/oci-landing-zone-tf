variable "tenancy_ocid" {
  description = "OCID of the root tenancy. Budget resources must be created at the tenancy level."
  type        = string
}

variable "alert_email" {
  description = "Email address (or comma-separated list) to receive budget alert notifications"
  type        = string

  validation {
    condition     = can(regex("^[^@]+@[^@]+\\.[^@]+", var.alert_email))
    error_message = "alert_email must be a valid email address."
  }
}

variable "budgets" {
  description = <<-EOT
    Map of budget configurations. Each key is the environment name.

    Fields:
    - amount:                      Monthly budget amount in USD
    - compartment_ocid:            OCID of the target compartment to track
    - forecast_threshold_percent:  % of budget at which to send a FORECAST alert (default: 80)
    - actual_threshold_percent:    % of budget at which to send an ACTUAL spend alert (default: 90)
    - reset_period:                Budget reset period. Must be MONTHLY.
  EOT
  type = map(object({
    amount                     = number
    compartment_ocid           = string
    forecast_threshold_percent = optional(number, 80)
    actual_threshold_percent   = optional(number, 90)
    reset_period               = optional(string, "MONTHLY")
  }))
  default = {}

  validation {
    condition = alltrue([
      for name, cfg in var.budgets : cfg.amount > 0
    ])
    error_message = "Budget amount must be greater than 0."
  }

  validation {
    condition = alltrue([
      for name, cfg in var.budgets :
      cfg.forecast_threshold_percent > 0 && cfg.forecast_threshold_percent < 100
    ])
    error_message = "forecast_threshold_percent must be between 1 and 99."
  }
}

variable "tags" {
  description = "Free-form tags to apply to all budget resources"
  type        = map(string)
  default     = {}
}
