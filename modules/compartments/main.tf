##############################################################################
# Module: compartments
# Description: Creates an environment/workload compartment hierarchy for the
#              OCI Landing Zone. Designed to be used as the foundation for
#              all other Landing Zone modules.
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
# Environment compartments (e.g., dev, staging, prod)
# Created directly under the root tenancy compartment
# ---------------------------------------------------------------------------
resource "oci_identity_compartment" "environment" {
  for_each = toset(var.environment_compartments)

  compartment_id = var.tenancy_ocid
  name           = each.value
  description    = "Landing Zone - ${each.value} environment"

  freeform_tags = merge(var.tags, {
    "lz-managed"  = "true"
    "environment" = each.value
  })
}

# ---------------------------------------------------------------------------
# Workload compartments (e.g., network, compute, database, security)
# Created under each environment compartment
# ---------------------------------------------------------------------------
locals {
  # Flatten to a list of {env, workload} pairs for for_each
  workload_pairs = flatten([
    for env, workloads in var.workload_compartments : [
      for wl in workloads : {
        env      = env
        workload = wl
        key      = "${env}-${wl}"
      }
    ]
  ])

  workload_map = {
    for pair in local.workload_pairs : pair.key => pair
  }
}

resource "oci_identity_compartment" "workload" {
  for_each = local.workload_map

  compartment_id = oci_identity_compartment.environment[each.value.env].id
  name           = each.value.workload
  description    = "Landing Zone - ${each.value.env}/${each.value.workload}"

  freeform_tags = merge(var.tags, {
    "lz-managed"  = "true"
    "environment" = each.value.env
    "workload"    = each.value.workload
  })
}
