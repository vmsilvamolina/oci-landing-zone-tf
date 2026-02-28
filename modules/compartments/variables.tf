variable "tenancy_ocid" {
  description = "OCID of the root tenancy compartment"
  type        = string
}

variable "environment_compartments" {
  description = "List of environment names to create as top-level compartments under the tenancy"
  type        = list(string)
  default     = ["dev", "staging", "prod"]

  validation {
    condition     = length(var.environment_compartments) > 0
    error_message = "At least one environment compartment must be specified."
  }
}

variable "workload_compartments" {
  description = "Map of environment name to list of workload compartment names to create under it"
  type        = map(list(string))
  default = {
    dev     = ["network", "compute", "database", "security"]
    staging = ["network", "compute", "database", "security"]
    prod    = ["network", "compute", "database", "security"]
  }

  validation {
    condition = alltrue([
      for env, workloads in var.workload_compartments :
      length(workloads) > 0
    ])
    error_message = "Each environment must have at least one workload compartment."
  }
}

variable "tags" {
  description = "Free-form tags to apply to all compartments created by this module"
  type        = map(string)
  default     = {}
}
