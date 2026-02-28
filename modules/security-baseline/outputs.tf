output "vault_id" {
  description = "OCID of the Landing Zone Vault"
  value       = oci_kms_vault.lz.id
}

output "vault_management_endpoint" {
  description = "Management endpoint of the Vault (needed to create keys and secrets)"
  value       = oci_kms_vault.lz.management_endpoint
}

output "master_key_id" {
  description = "OCID of the master encryption key"
  value       = oci_kms_key.master.id
}

output "audit_log_bucket_name" {
  description = "Name of the Object Storage bucket storing audit logs"
  value       = oci_objectstorage_bucket.audit_logs.name
}

output "security_alerts_topic_id" {
  description = "OCID of the ONS topic for security event notifications"
  value       = oci_ons_notification_topic.security_alerts.id
}

output "cloud_guard_target_id" {
  description = "OCID of the Cloud Guard target (null if Cloud Guard was not enabled)"
  value       = var.enable_cloud_guard ? oci_cloud_guard_target.environment[0].id : null
}
