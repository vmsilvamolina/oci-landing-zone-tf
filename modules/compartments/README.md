# Module: compartments

Creates an environment/workload compartment hierarchy as the foundation of the OCI Landing Zone.

## Usage

```hcl
module "compartments" {
  source = "../../modules/compartments"

  tenancy_ocid             = var.tenancy_ocid
  environment_compartments = ["dev", "staging", "prod"]

  workload_compartments = {
    dev     = ["network", "compute", "database", "security"]
    staging = ["network", "compute", "database"]
    prod    = ["network", "compute", "database", "security"]
  }

  tags = {
    "project"    = "landing-zone"
    "managed-by" = "terraform"
  }
}

# Access outputs in other modules
output "prod_db_compartment" {
  value = module.compartments.workload_compartment_ids["prod-database"]
}
```

## Hierarchy Created

```
Root Tenancy
├── dev/
│   ├── network
│   ├── compute
│   ├── database
│   └── security
├── staging/
│   ├── network
│   ├── compute
│   └── database
└── prod/
    ├── network
    ├── compute
    ├── database
    └── security
```

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|----------|
| `tenancy_ocid` | OCID of the root tenancy | `string` | — | yes |
| `environment_compartments` | List of environment names | `list(string)` | `["dev","staging","prod"]` | no |
| `workload_compartments` | Map of env to list of workload names | `map(list(string))` | See defaults | no |
| `tags` | Free-form tags for all compartments | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| `environment_compartment_ids` | Map of env name → compartment OCID |
| `workload_compartment_ids` | Map of `"env-workload"` → compartment OCID |
| `environment_compartments` | Full compartment resource objects |

## Notes

- Compartment names within the same parent must be unique — this module enforces that through the `for_each` key structure.
- Deleting compartments via `terraform destroy` will fail if they contain resources. Empty them first or use the OCI Console.
- Tags applied to environment compartments are inherited by child compartments for billing and cost tracking purposes.
