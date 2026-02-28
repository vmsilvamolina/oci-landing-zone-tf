# Module: security-baseline

Enables core OCI security controls for a Landing Zone environment. Designed to give teams a **secure-by-default** foundation without requiring deep OCI security expertise.

## Controls Enabled

| Control | OCI Service | CIS Benchmark |
|---------|-------------|---------------|
| Secrets & key management | OCI Vault + KMS | 3.1 |
| Audit log retention (365 days) | Object Storage + Service Connector | 2.1 |
| Threat detection | Cloud Guard | 2.5 |
| IAM change alerting | Events + ONS | 2.6 |
| Network change alerting | Events + ONS | 2.3 |

## Usage

```hcl
module "security_prod" {
  source = "../../modules/security-baseline"

  tenancy_ocid                 = var.tenancy_ocid
  region                       = var.region
  environment                  = "prod"
  environment_compartment_ocid = module.compartments.environment_compartment_ids["prod"]
  security_compartment_ocid    = module.compartments.workload_compartment_ids["prod-security"]
  security_alert_email         = "security-alerts@yourcompany.com"

  vault_type                   = "VIRTUAL_PRIVATE"  # Dedicated HSM for prod
  audit_log_retention_days     = 365
  enable_cloud_guard           = true

  tags = { "managed-by" = "terraform" }
}
```

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|----------|
| `tenancy_ocid` | OCID of root tenancy | `string` | — | yes |
| `region` | OCI region | `string` | — | yes |
| `environment` | Environment name | `string` | — | yes |
| `environment_compartment_ocid` | OCID of env compartment to protect | `string` | — | yes |
| `security_compartment_ocid` | OCID of security workload compartment | `string` | — | yes |
| `security_alert_email` | Alert email address | `string` | — | yes |
| `vault_type` | `DEFAULT` or `VIRTUAL_PRIVATE` | `string` | `"DEFAULT"` | no |
| `audit_log_retention_days` | Days to retain audit logs | `number` | `365` | no |
| `enable_cloud_guard` | Enable Cloud Guard | `bool` | `true` | no |
| `tags` | Free-form tags | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| `vault_id` | Vault OCID |
| `vault_management_endpoint` | Vault management endpoint |
| `master_key_id` | Master encryption key OCID |
| `audit_log_bucket_name` | Audit log Object Storage bucket |
| `security_alerts_topic_id` | ONS security alerts topic OCID |
| `cloud_guard_target_id` | Cloud Guard target OCID |

## Notes

- **Cloud Guard** can only be enabled once per tenancy. If you already have it configured, set `enable_cloud_guard = false`.
- **VIRTUAL_PRIVATE vault** has an associated hourly cost. Use `DEFAULT` for dev/staging and `VIRTUAL_PRIVATE` for production.
- **Service Connector** for audit logs requires the `serviceconnector` service to be authorized to write to Object Storage — this is handled automatically by OCI when the connector is created.
