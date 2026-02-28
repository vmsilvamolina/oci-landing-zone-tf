# Module: budgets

Creates OCI Budget resources with dual alert rules (forecast + actual spend) per environment. Enables teams to track and control cloud costs from day one.

## Usage

```hcl
module "budgets" {
  source = "../../modules/budgets"

  tenancy_ocid = var.tenancy_ocid
  alert_email  = "platform-alerts@yourcompany.com"

  budgets = {
    dev = {
      amount           = 100
      compartment_ocid = module.compartments.environment_compartment_ids["dev"]
      forecast_threshold_percent = 75
      actual_threshold_percent   = 90
    }
    staging = {
      amount           = 250
      compartment_ocid = module.compartments.environment_compartment_ids["staging"]
    }
    prod = {
      amount           = 1000
      compartment_ocid = module.compartments.environment_compartment_ids["prod"]
      forecast_threshold_percent = 70
      actual_threshold_percent   = 85
    }
  }

  tags = { "managed-by" = "terraform" }
}
```

## Alert Types

Each budget creates two alert rules:

- **FORECAST**: Triggers when OCI projects you will exceed the threshold by end of period. Use this as your early warning.
- **ACTUAL**: Triggers when real spend has already hit the threshold. Use this as your action trigger.

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|----------|
| `tenancy_ocid` | OCID of root tenancy | `string` | — | yes |
| `alert_email` | Email(s) for alert notifications | `string` | — | yes |
| `budgets` | Map of environment → budget config | `map(object)` | `{}` | no |
| `tags` | Free-form tags | `map(string)` | `{}` | no |

### Budget object fields

| Field | Description | Default |
|-------|-------------|---------|
| `amount` | Monthly budget in USD | required |
| `compartment_ocid` | Target compartment OCID | required |
| `forecast_threshold_percent` | Forecast alert threshold (%) | `80` |
| `actual_threshold_percent` | Actual spend alert threshold (%) | `90` |
| `reset_period` | Reset frequency | `"MONTHLY"` |

## Outputs

| Name | Description |
|------|-------------|
| `budget_ids` | Map of env name → budget OCID |
| `forecast_alert_ids` | Map of env name → forecast alert OCID |
| `actual_alert_ids` | Map of env name → actual alert OCID |
