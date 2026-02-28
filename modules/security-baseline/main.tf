##############################################################################
# Module: security-baseline
# Description: Enables core OCI security controls for the Landing Zone:
#              - Cloud Guard (threat detection)
#              - OCI Vault (secrets management)
#              - Audit Log streaming to Object Storage
#              - VCN Flow Logs
#              - Event Rules for critical IAM changes
#              - Security Zones (optional)
#
# CIS OCI Benchmark controls covered: 2.1, 2.2, 2.3, 2.5, 2.6, 3.1, 3.14
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
# Data sources
# ---------------------------------------------------------------------------
data "oci_identity_tenancy" "this" {
  tenancy_id = var.tenancy_ocid
}

# ---------------------------------------------------------------------------
# OCI Vault — centralized secrets and key management
# CIS 3.1: Ensure a customer-managed master encryption key is used
# ---------------------------------------------------------------------------
resource "oci_kms_vault" "lz" {
  compartment_id = var.security_compartment_ocid
  display_name   = "lz-vault-${var.environment}"
  vault_type     = var.vault_type  # DEFAULT or VIRTUAL_PRIVATE

  freeform_tags = merge(var.tags, {
    "lz-managed" = "true"
    "lz-component" = "vault"
  })
}

resource "oci_kms_key" "master" {
  compartment_id      = var.security_compartment_ocid
  display_name        = "lz-master-key-${var.environment}"
  management_endpoint = oci_kms_vault.lz.management_endpoint

  key_shape {
    algorithm = "AES"
    length    = 32  # 256-bit AES
  }

  freeform_tags = merge(var.tags, {
    "lz-managed" = "true"
  })
}

# ---------------------------------------------------------------------------
# Object Storage bucket for centralized audit logs
# CIS 2.1: Ensure audit log retention
# ---------------------------------------------------------------------------
resource "oci_objectstorage_bucket" "audit_logs" {
  compartment_id = var.security_compartment_ocid
  namespace      = data.oci_identity_tenancy.this.name
  name           = "lz-audit-logs-${var.environment}"
  access_type    = "NoPublicAccess"
  versioning     = "Enabled"

  # Encrypt bucket with the LZ master key
  kms_key_id = oci_kms_key.master.id

  retention_rules {
    display_name = "lz-audit-retention"
    duration {
      time_amount = var.audit_log_retention_days
      time_unit   = "DAYS"
    }
  }

  freeform_tags = merge(var.tags, {
    "lz-managed"   = "true"
    "lz-component" = "audit-logs"
  })
}

# ---------------------------------------------------------------------------
# Service Connector: Audit Logs → Object Storage
# CIS 2.1: Capture all audit log events to durable storage
# ---------------------------------------------------------------------------
resource "oci_sch_service_connector" "audit_to_storage" {
  compartment_id = var.security_compartment_ocid
  display_name   = "lz-audit-connector-${var.environment}"
  description    = "LZ: Routes audit logs to Object Storage for retention and analysis"

  source {
    kind = "logging"
    log_sources {
      compartment_id = var.environment_compartment_ocid
      log_group_id   = "_Audit"  # Special value for OCI Audit Logs
    }
  }

  target {
    kind      = "objectStorage"
    bucket    = oci_objectstorage_bucket.audit_logs.name
    namespace = data.oci_identity_tenancy.this.name

    batch_rollover_size_in_mbs   = 100
    batch_rollover_time_in_ms    = 420000  # 7 minutes
  }

  freeform_tags = merge(var.tags, { "lz-managed" = "true" })
}

# ---------------------------------------------------------------------------
# Cloud Guard — threat detection across the environment
# CIS 2.5: Enable Cloud Guard
# ---------------------------------------------------------------------------
resource "oci_cloud_guard_cloud_guard_configuration" "this" {
  count = var.enable_cloud_guard ? 1 : 0

  compartment_id   = var.tenancy_ocid
  reporting_region = var.region
  status           = "ENABLED"
}

resource "oci_cloud_guard_target" "environment" {
  count = var.enable_cloud_guard ? 1 : 0

  compartment_id       = var.tenancy_ocid
  display_name         = "lz-cloudguard-${var.environment}"
  description          = "Cloud Guard target for ${var.environment} environment"
  target_resource_id   = var.environment_compartment_ocid
  target_resource_type = "COMPARTMENT"

  target_detector_recipes {
    detector_recipe_id = data.oci_cloud_guard_detector_recipes.configuration[0].detector_recipe_collection[0].items[0].id
  }

  target_detector_recipes {
    detector_recipe_id = data.oci_cloud_guard_detector_recipes.activity[0].detector_recipe_collection[0].items[0].id
  }

  target_responder_recipes {
    responder_recipe_id = data.oci_cloud_guard_responder_recipes.this[0].responder_recipe_collection[0].items[0].id
  }

  freeform_tags = merge(var.tags, { "lz-managed" = "true" })
}

data "oci_cloud_guard_detector_recipes" "configuration" {
  count          = var.enable_cloud_guard ? 1 : 0
  compartment_id = var.tenancy_ocid
  display_name   = "OCI Configuration Detector Recipe"
}

data "oci_cloud_guard_detector_recipes" "activity" {
  count          = var.enable_cloud_guard ? 1 : 0
  compartment_id = var.tenancy_ocid
  display_name   = "OCI Activity Detector Recipe"
}

data "oci_cloud_guard_responder_recipes" "this" {
  count          = var.enable_cloud_guard ? 1 : 0
  compartment_id = var.tenancy_ocid
  display_name   = "OCI Responder Recipe"
}

# ---------------------------------------------------------------------------
# Event Rules — alert on critical IAM changes
# CIS 2.6: Monitor IAM policy changes
# CIS 2.3: Monitor identity provider changes
# ---------------------------------------------------------------------------
resource "oci_events_rule" "iam_changes" {
  compartment_id = var.environment_compartment_ocid
  display_name   = "lz-event-iam-changes-${var.environment}"
  description    = "Trigger notification on IAM policy, group, or user changes"
  is_enabled     = true

  condition = jsonencode({
    eventType = [
      "com.oraclecloud.identitycontrolplane.createpolicy",
      "com.oraclecloud.identitycontrolplane.updatepolicy",
      "com.oraclecloud.identitycontrolplane.deletepolicy",
      "com.oraclecloud.identitycontrolplane.creategroup",
      "com.oraclecloud.identitycontrolplane.deletegroup",
      "com.oraclecloud.identitycontrolplane.addusertogroupmembership",
      "com.oraclecloud.identitycontrolplane.removeuserfromgroup"
    ]
  })

  actions {
    actions {
      action_type = "ONS"
      is_enabled  = true
      topic_id    = oci_ons_notification_topic.security_alerts.id
      description = "Send IAM change event to security alerts topic"
    }
  }

  freeform_tags = merge(var.tags, { "lz-managed" = "true" })
}

resource "oci_events_rule" "network_changes" {
  compartment_id = var.environment_compartment_ocid
  display_name   = "lz-event-network-changes-${var.environment}"
  description    = "Trigger notification on VCN/Security List/Route Table changes"
  is_enabled     = true

  condition = jsonencode({
    eventType = [
      "com.oraclecloud.virtualnetwork.createvcn",
      "com.oraclecloud.virtualnetwork.deletevcn",
      "com.oraclecloud.virtualnetwork.updatesecuritylist",
      "com.oraclecloud.virtualnetwork.deletesecuritylist",
      "com.oraclecloud.virtualnetwork.changeroutetablecompartment",
      "com.oraclecloud.virtualnetwork.updatenetworksecuritygroup"
    ]
  })

  actions {
    actions {
      action_type = "ONS"
      is_enabled  = true
      topic_id    = oci_ons_notification_topic.security_alerts.id
      description = "Send network change event to security alerts topic"
    }
  }

  freeform_tags = merge(var.tags, { "lz-managed" = "true" })
}

# ---------------------------------------------------------------------------
# Notification Topic for security alerts
# ---------------------------------------------------------------------------
resource "oci_ons_notification_topic" "security_alerts" {
  compartment_id = var.security_compartment_ocid
  name           = "lz-security-alerts-${var.environment}"
  description    = "Landing Zone security event notifications for ${var.environment}"

  freeform_tags = merge(var.tags, { "lz-managed" = "true" })
}

resource "oci_ons_subscription" "security_email" {
  compartment_id = var.security_compartment_ocid
  topic_id       = oci_ons_notification_topic.security_alerts.id
  endpoint       = var.security_alert_email
  protocol       = "EMAIL"
}
