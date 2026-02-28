# ============================================================================
# Example: full
# Description: Complete Landing Zone deployment with all four modules:
#              compartments, IAM, budgets, and security-baseline.
#              Deploys dev, staging, and prod environments.
# ============================================================================

terraform {
  required_providers {
    oci = {
      source  = "oracle/oci"
      version = ">= 5.0"
    }
  }
  required_version = ">= 1.5"

  # Recommended: use remote state in production
  # backend "s3" {
  #   bucket   = "your-tf-state-bucket"
  #   key      = "landing-zone/terraform.tfstate"
  #   region   = "us-ashburn-1"
  #   endpoint = "https://<namespace>.compat.objectstorage.us-ashburn-1.oraclecloud.com"
  # }
}

provider "oci" {
  tenancy_ocid     = var.tenancy_ocid
  user_ocid        = var.user_ocid
  fingerprint      = var.fingerprint
  private_key_path = var.private_key_path
  region           = var.region
}

locals {
  common_tags = {
    "project"    = "landing-zone"
    "managed-by" = "terraform"
    "owner"      = var.owner_email
  }
}

# ---------------------------------------------------------------------------
# Module 1: Compartments
# ---------------------------------------------------------------------------
module "compartments" {
  source = "../../modules/compartments"

  tenancy_ocid             = var.tenancy_ocid
  environment_compartments = ["dev", "staging", "prod"]

  workload_compartments = {
    dev     = ["network", "compute", "database", "security"]
    staging = ["network", "compute", "database", "security"]
    prod    = ["network", "compute", "database", "security"]
  }

  tags = local.common_tags
}

# ---------------------------------------------------------------------------
# Module 2: IAM Groups and Policies
# ---------------------------------------------------------------------------
module "iam" {
  source = "../../modules/iam"

  tenancy_ocid = var.tenancy_ocid

  groups = {
    "lz-platform-admins" = {
      description  = "Platform / SRE team - full administrative access"
      environments = ["dev", "staging", "prod"]
      role         = "admin"
    }
    "lz-developers" = {
      description  = "Application developers - deploy to dev and staging only"
      environments = ["dev", "staging"]
      role         = "developer"
    }
    "lz-dba-team" = {
      description  = "DBA team - manage databases across all environments"
      environments = ["dev", "staging", "prod"]
      role         = "dba"
    }
    "lz-network-admins" = {
      description  = "Network team - VCN and connectivity management"
      environments = ["dev", "staging", "prod"]
      role         = "network-admin"
    }
    "lz-security-team" = {
      description  = "Security team - Cloud Guard, Vault, compliance"
      environments = ["dev", "staging", "prod"]
      role         = "security-admin"
    }
    "lz-auditors" = {
      description  = "Audit team - read-only access to all environments"
      environments = ["dev", "staging", "prod"]
      role         = "read-only"
    }
  }

  tags = local.common_tags
}

# ---------------------------------------------------------------------------
# Module 3: Budgets
# ---------------------------------------------------------------------------
module "budgets" {
  source = "../../modules/budgets"

  tenancy_ocid = var.tenancy_ocid
  alert_email  = var.budget_alert_email

  budgets = {
    dev = {
      amount                     = var.budget_dev
      compartment_ocid           = module.compartments.environment_compartment_ids["dev"]
      forecast_threshold_percent = 80
      actual_threshold_percent   = 90
    }
    staging = {
      amount                     = var.budget_staging
      compartment_ocid           = module.compartments.environment_compartment_ids["staging"]
      forecast_threshold_percent = 80
      actual_threshold_percent   = 90
    }
    prod = {
      amount                     = var.budget_prod
      compartment_ocid           = module.compartments.environment_compartment_ids["prod"]
      forecast_threshold_percent = 70   # More conservative threshold for prod
      actual_threshold_percent   = 85
    }
  }

  tags = local.common_tags
}

# ---------------------------------------------------------------------------
# Module 4: Security Baseline — applied to each environment
# ---------------------------------------------------------------------------
module "security_dev" {
  source = "../../modules/security-baseline"

  tenancy_ocid                 = var.tenancy_ocid
  region                       = var.region
  environment                  = "dev"
  environment_compartment_ocid = module.compartments.environment_compartment_ids["dev"]
  security_compartment_ocid    = module.compartments.workload_compartment_ids["dev-security"]
  security_alert_email         = var.security_alert_email

  vault_type               = "DEFAULT"  # Shared HSM for dev (no extra cost)
  audit_log_retention_days = 90         # Shorter retention for dev
  enable_cloud_guard       = true       # Enable once; set to false for staging/prod

  tags = local.common_tags
}

module "security_staging" {
  source = "../../modules/security-baseline"

  tenancy_ocid                 = var.tenancy_ocid
  region                       = var.region
  environment                  = "staging"
  environment_compartment_ocid = module.compartments.environment_compartment_ids["staging"]
  security_compartment_ocid    = module.compartments.workload_compartment_ids["staging-security"]
  security_alert_email         = var.security_alert_email

  vault_type               = "DEFAULT"
  audit_log_retention_days = 180
  enable_cloud_guard       = false  # Already enabled at tenancy level by dev module

  tags = local.common_tags
}

module "security_prod" {
  source = "../../modules/security-baseline"

  tenancy_ocid                 = var.tenancy_ocid
  region                       = var.region
  environment                  = "prod"
  environment_compartment_ocid = module.compartments.environment_compartment_ids["prod"]
  security_compartment_ocid    = module.compartments.workload_compartment_ids["prod-security"]
  security_alert_email         = var.security_alert_email

  vault_type               = "VIRTUAL_PRIVATE"  # Dedicated HSM for prod
  audit_log_retention_days = 365
  enable_cloud_guard       = false  # Already enabled at tenancy level

  tags = local.common_tags
}

# ---------------------------------------------------------------------------
# Summary outputs
# ---------------------------------------------------------------------------
output "environment_compartment_ids" {
  description = "Map of environment name to compartment OCID"
  value       = module.compartments.environment_compartment_ids
}

output "workload_compartment_ids" {
  description = "Map of 'env-workload' to compartment OCID"
  value       = module.compartments.workload_compartment_ids
}

output "iam_group_ids" {
  description = "Map of group name to OCID"
  value       = module.iam.group_ids
}

output "budget_ids" {
  description = "Map of environment to budget OCID"
  value       = module.budgets.budget_ids
}

output "vault_ids" {
  description = "Map of environment to Vault OCID"
  value = {
    dev     = module.security_dev.vault_id
    staging = module.security_staging.vault_id
    prod    = module.security_prod.vault_id
  }
}
