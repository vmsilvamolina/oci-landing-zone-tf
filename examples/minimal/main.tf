# ============================================================================
# Example: minimal
# Description: Deploys only compartments and IAM for a single dev environment.
#              Ideal for teams just getting started with OCI or validating
#              the module before a full deployment.
# ============================================================================

terraform {
  required_providers {
    oci = {
      source  = "oracle/oci"
      version = ">= 5.0"
    }
  }
  required_version = ">= 1.5"
}

provider "oci" {
  tenancy_ocid     = var.tenancy_ocid
  user_ocid        = var.user_ocid
  fingerprint      = var.fingerprint
  private_key_path = var.private_key_path
  region           = var.region
}

# ---------------------------------------------------------------------------
# Compartments — dev environment only
# ---------------------------------------------------------------------------
module "compartments" {
  source = "../../modules/compartments"

  tenancy_ocid             = var.tenancy_ocid
  environment_compartments = ["dev"]

  workload_compartments = {
    dev = ["network", "compute", "database", "security"]
  }

  tags = {
    "project"    = "landing-zone"
    "managed-by" = "terraform"
    "example"    = "minimal"
  }
}

# ---------------------------------------------------------------------------
# IAM — two groups for the dev environment
# ---------------------------------------------------------------------------
module "iam" {
  source = "../../modules/iam"

  tenancy_ocid = var.tenancy_ocid

  groups = {
    "lz-admins" = {
      description  = "Landing Zone administrators - full access to dev"
      environments = ["dev"]
      role         = "admin"
    }
    "lz-developers" = {
      description  = "Development team - deploy access to dev"
      environments = ["dev"]
      role         = "developer"
    }
  }

  tags = {
    "project"    = "landing-zone"
    "managed-by" = "terraform"
  }
}

# ---------------------------------------------------------------------------
# Outputs
# ---------------------------------------------------------------------------
output "dev_compartment_id" {
  description = "OCID of the dev environment compartment"
  value       = module.compartments.environment_compartment_ids["dev"]
}

output "workload_compartment_ids" {
  description = "Map of all workload compartment OCIDs"
  value       = module.compartments.workload_compartment_ids
}

output "group_ids" {
  description = "Map of group name to OCID"
  value       = module.iam.group_ids
}
