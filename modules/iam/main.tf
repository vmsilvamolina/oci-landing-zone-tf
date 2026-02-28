##############################################################################
# Module: iam
# Description: Creates IAM groups and least-privilege policies for the
#              OCI Landing Zone. Supports four built-in roles:
#              admin, developer, read-only, dba
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
# IAM Groups
# ---------------------------------------------------------------------------
resource "oci_identity_group" "this" {
  for_each = var.groups

  compartment_id = var.tenancy_ocid
  name           = each.key
  description    = each.value.description

  freeform_tags = merge(var.tags, {
    "lz-managed" = "true"
    "lz-role"    = each.value.role
  })
}

# ---------------------------------------------------------------------------
# Policy statement templates per role
# %s substitutions: 1=group_name, 2=compartment_name
# ---------------------------------------------------------------------------
locals {
  policy_templates = {
    admin = [
      "Allow group %s to manage all-resources in compartment %s"
    ]

    developer = [
      "Allow group %s to manage instances in compartment %s",
      "Allow group %s to manage object-family in compartment %s",
      "Allow group %s to manage functions-family in compartment %s",
      "Allow group %s to manage repos in compartment %s",
      "Allow group %s to use virtual-network-family in compartment %s",
      "Allow group %s to read secret-family in compartment %s",
      "Allow group %s to use vaults in compartment %s",
      "Allow group %s to inspect load-balancers in compartment %s"
    ]

    "read-only" = [
      "Allow group %s to inspect all-resources in compartment %s",
      "Allow group %s to read all-resources in compartment %s"
    ]

    dba = [
      "Allow group %s to manage database-family in compartment %s",
      "Allow group %s to manage autonomous-database-family in compartment %s",
      "Allow group %s to use virtual-network-family in compartment %s",
      "Allow group %s to read secret-family in compartment %s",
      "Allow group %s to use vaults in compartment %s",
      "Allow group %s to manage buckets in compartment %s",
      "Allow group %s to manage objects in compartment %s"
    ]

    network-admin = [
      "Allow group %s to manage virtual-network-family in compartment %s",
      "Allow group %s to manage load-balancers in compartment %s",
      "Allow group %s to manage dns in compartment %s",
      "Allow group %s to manage certificates in compartment %s",
      "Allow group %s to use network-security-groups in compartment %s"
    ]

    security-admin = [
      "Allow group %s to manage cloud-guard-family in compartment %s",
      "Allow group %s to manage vaults in compartment %s",
      "Allow group %s to manage keys in compartment %s",
      "Allow group %s to manage secret-family in compartment %s",
      "Allow group %s to manage bastion-family in compartment %s",
      "Allow group %s to read all-resources in compartment %s",
      "Allow group %s to manage security-zone in compartment %s"
    ]
  }

  # Build a flat map of {group_name}-{env} combinations for policy resources
  policy_combos = {
    for combo in flatten([
      for group_name, group_cfg in var.groups : [
        for env in group_cfg.environments : {
          key        = "${group_name}__${env}"
          group_name = group_name
          env        = env
          role       = group_cfg.role
        }
      ]
    ]) : combo.key => combo
  }
}

# ---------------------------------------------------------------------------
# IAM Policies — one policy resource per group/environment combination
# Keeps policy statements scoped to the minimum compartment needed
# ---------------------------------------------------------------------------
resource "oci_identity_policy" "this" {
  for_each = local.policy_combos

  compartment_id = var.tenancy_ocid
  name           = "lz-policy-${replace(each.value.group_name, "_", "-")}-${each.value.env}"
  description    = "LZ managed policy: ${each.value.role} role for ${each.value.group_name} on ${each.value.env}"

  statements = [
    for stmt in local.policy_templates[each.value.role] :
    format(stmt, each.value.group_name, each.value.env)
  ]

  freeform_tags = merge(var.tags, {
    "lz-managed"   = "true"
    "lz-group"     = each.value.group_name
    "lz-env"       = each.value.env
    "lz-role"      = each.value.role
  })
}
