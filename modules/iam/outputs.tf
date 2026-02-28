output "group_ids" {
  description = "Map of group name to its OCID"
  value       = { for k, v in oci_identity_group.this : k => v.id }
}

output "policy_ids" {
  description = "Map of 'group__env' key to policy OCID"
  value       = { for k, v in oci_identity_policy.this : k => v.id }
}

output "group_names" {
  description = "List of all created group names"
  value       = keys(oci_identity_group.this)
}
