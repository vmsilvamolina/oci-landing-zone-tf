variable "tenancy_ocid" {
  description = "OCID of the root tenancy"
  type        = string
}

variable "region" {
  description = "OCI region identifier (e.g., us-ashburn-1). Used for Cloud Guard reporting region."
  type        = string
}

variable "environment" {
  description = "Environment name (e.g., dev, staging, prod). Used in resource naming."
  type        = string
}

variable "environment_compartment_ocid" {
  description = "OCID of the environment compartment to protect (output from compartments module)"
  type        = string
}

variable "security_compartment_ocid" {
  description = "OCID of the security workload compartment where Vault, logs, and topics will be created"
  type        = string
}

variable "security_alert_email" {
  description = "Email address to receive security event notifications"
  type        = string
}

variable "vault_type" {
  description = "OCI Vault type. DEFAULT is a shared HSM partition (no extra cost). VIRTUAL_PRIVATE is a dedicated HSM (higher cost, use for prod)."
  type        = string
  default     = "DEFAULT"

  validation {
    condition     = contains(["DEFAULT", "VIRTUAL_PRIVATE"], var.vault_type)
    error_message = "vault_type must be DEFAULT or VIRTUAL_PRIVATE."
  }
}

variable "audit_log_retention_days" {
  description = "Number of days to retain audit logs in Object Storage. CIS recommends at least 365."
  type        = number
  default     = 365

  validation {
    condition     = var.audit_log_retention_days >= 90
    error_message = "audit_log_retention_days must be at least 90 days."
  }
}

variable "enable_cloud_guard" {
  description = "Whether to enable Cloud Guard. Set to false if Cloud Guard is already configured at the tenancy level."
  type        = bool
  default     = true
}

variable "tags" {
  description = "Free-form tags to apply to all security resources"
  type        = map(string)
  default     = {}
}
