output "environment_compartment_ids" {
  description = "Map of environment name to its compartment OCID"
  value       = { for k, v in oci_identity_compartment.environment : k => v.id }
}

output "workload_compartment_ids" {
  description = "Map of 'env-workload' composite key to its compartment OCID (e.g., 'prod-database')"
  value       = { for k, v in oci_identity_compartment.workload : k => v.id }
}

output "environment_compartments" {
  description = "Full compartment resource objects for environments (useful for referencing additional attributes)"
  value       = oci_identity_compartment.environment
  sensitive   = false
}
