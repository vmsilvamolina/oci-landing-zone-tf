# Module: iam

Creates IAM groups and least-privilege policies for the OCI Landing Zone. Each group is assigned a predefined role that maps to a curated set of policy statements per environment.

## Supported Roles

| Role | What it can do |
|------|---------------|
| `admin` | Full access to all resources in the environment |
| `developer` | Manage compute, objects, functions, repos; read secrets; use networking |
| `read-only` | Inspect and read all resources (no writes) |
| `dba` | Manage databases (including Autonomous), object storage; read secrets |
| `network-admin` | Manage VCNs, load balancers, DNS, certificates, NSGs |
| `security-admin` | Manage Cloud Guard, Vault, secrets, bastions, security zones; read everything |

## Usage

```hcl
module "iam" {
  source = "../../modules/iam"

  tenancy_ocid = var.tenancy_ocid

  groups = {
    "lz-platform-admins" = {
      description  = "Platform team - full access to all environments"
      environments = ["dev", "staging", "prod"]
      role         = "admin"
    }
    "lz-developers" = {
      description  = "Dev team - deploy access to dev and staging only"
      environments = ["dev", "staging"]
      role         = "developer"
    }
    "lz-dba-team" = {
      description  = "DBA team - database access across all environments"
      environments = ["dev", "staging", "prod"]
      role         = "dba"
    }
    "lz-security-team" = {
      description  = "Security team - Cloud Guard, Vault and compliance"
      environments = ["dev", "staging", "prod"]
      role         = "security-admin"
    }
  }

  tags = { "managed-by" = "terraform" }
}
```

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|----------|
| `tenancy_ocid` | OCID of the root tenancy | `string` | — | yes |
| `groups` | Map of group name → configuration | `map(object)` | `{}` | no |
| `tags` | Free-form tags | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| `group_ids` | Map of group name → OCID |
| `policy_ids` | Map of `group__env` → policy OCID |
| `group_names` | List of all created group names |

## Design Decisions

**Why one policy per group/environment combo?** OCI policies have a statement limit per resource. Scoping each policy to a single group+environment combination keeps policies small, readable, and easy to audit. It also allows Terraform to update or delete individual policies without touching others.

**Why no user-to-group membership here?** User membership is considered operational data (it changes frequently) and should be managed separately from infrastructure code — via OCI Console, SCIM provisioning, or a dedicated identity module. This module only creates the groups.
