variable "tenancy_ocid" {
  description = "OCID of the root tenancy. Groups and policies are always created at the tenancy level in OCI."
  type        = string
}

variable "groups" {
  description = <<-EOT
    Map of group configurations. Each key is the IAM group name.

    Fields:
    - description:  Human-readable description of the group's purpose
    - environments: List of environment compartment names this group can access
    - role:         Access role. Supported values: admin | developer | read-only | dba | network-admin | security-admin
  EOT
  type = map(object({
    description  = string
    environments = list(string)
    role         = string
  }))
  default = {}

  validation {
    condition = alltrue([
      for name, cfg in var.groups :
      contains(["admin", "developer", "read-only", "dba", "network-admin", "security-admin"], cfg.role)
    ])
    error_message = "Each group role must be one of: admin, developer, read-only, dba, network-admin, security-admin."
  }
}

variable "tags" {
  description = "Free-form tags to apply to all IAM resources created by this module"
  type        = map(string)
  default     = {}
}
