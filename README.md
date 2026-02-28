# OCI Landing Zone Modular

> Terraform modules to deploy a production-ready, CIS-aligned Landing Zone on Oracle Cloud Infrastructure.

[![License](https://img.shields.io/badge/License-Apache_2.0-blue.svg)](LICENSE)
[![OCI Provider](https://img.shields.io/badge/OCI_Provider-%3E%3D5.0-red)](https://registry.terraform.io/providers/oracle/oci/latest)

---

## Why This Exists

The official OCI Landing Zone is comprehensive but overwhelming for small and mid-size teams. This modular approach lets you:

- **Start with only what you need** — each module is independently deployable
- **Grow incrementally** — add security controls, budgets, or more environments over time
- **Understand every decision** — all architectural choices are documented in [`docs/decisions.md`](docs/decisions.md)

---

## Architecture

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

Each environment compartment gets its own IAM policies, budget alerts, and security baseline configuration — fully isolated and independently manageable.

---

## Modules

| Module | Description | CIS Controls |
|--------|-------------|--------------|
| [compartments](modules/compartments/) | Environment and workload compartment hierarchy | 1.1, 1.2 |
| [iam](modules/iam/) | Groups and least-privilege policies per role | 1.3, 1.4, 1.7 |
| [budgets](modules/budgets/) | Cost tracking with forecast alerts per environment | 4.1 |
| [security-baseline](modules/security-baseline/) | Cloud Guard, Audit Logs, Vault, Security Zones | 2.x, 3.x |

---

## Quick Start

### Minimal (dev only, no budgets)

```hcl
module "compartments" {
  source  = "github.com/your-org/oci-landing-zone//modules/compartments"

  tenancy_ocid             = var.tenancy_ocid
  environment_compartments = ["dev"]
  workload_compartments = {
    dev = ["network", "compute", "database"]
  }
  tags = { "managed-by" = "terraform" }
}
```

### Full deployment

See [`examples/full/`](examples/full/) for a complete working example with all modules integrated.

---

## Requirements

| Tool | Version |
|------|---------|
| Terraform | >= 1.5 |
| OCI Provider | >= 5.0 |
| OCI CLI | >= 3.x (for initial setup) |

### OCI Permissions Required

The identity running `terraform apply` must have:
- `manage compartments` in tenancy
- `manage groups` in tenancy
- `manage policies` in tenancy
- `manage budgets` in tenancy
- `manage cloud-guard-family` in tenancy (for security-baseline module)

---

## Usage

### 1. Configure OCI credentials

```bash
# Option A: OCI CLI config file (~/.oci/config)
export TF_VAR_tenancy_ocid="ocid1.tenancy.oc1..xxxxx"
export TF_VAR_user_ocid="ocid1.user.oc1..xxxxx"
export TF_VAR_fingerprint="xx:xx:xx:xx"
export TF_VAR_private_key_path="~/.oci/oci_api_key.pem"
export TF_VAR_region="us-ashburn-1"

# Option B: Instance Principal (recommended for CI/CD)
# Set use_instance_principals = true in provider config
```

### 2. Copy and configure variables

```bash
cp examples/full/terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars with your values
```

### 3. Deploy

```bash
terraform init
terraform plan -out=tfplan
terraform apply tfplan
```

---

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines.

---

## License

Apache 2.0 — see [LICENSE](LICENSE).
