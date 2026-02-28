variable "tenancy_ocid" {
  description = "OCID of your OCI tenancy"
  type        = string
}

variable "user_ocid" {
  description = "OCID of the OCI user running Terraform"
  type        = string
}

variable "fingerprint" {
  description = "Fingerprint of the API signing key"
  type        = string
}

variable "private_key_path" {
  description = "Path to the OCI API signing private key (.pem)"
  type        = string
}

variable "region" {
  description = "OCI region (e.g., us-ashburn-1, sa-saopaulo-1)"
  type        = string
}

variable "owner_email" {
  description = "Email of the team or person owning this Landing Zone deployment (used as a tag)"
  type        = string
}

variable "budget_alert_email" {
  description = "Email address for budget threshold alerts"
  type        = string
}

variable "security_alert_email" {
  description = "Email address for security event notifications (IAM changes, network changes)"
  type        = string
}

variable "budget_dev" {
  description = "Monthly budget limit in USD for the dev environment"
  type        = number
  default     = 100
}

variable "budget_staging" {
  description = "Monthly budget limit in USD for the staging environment"
  type        = number
  default     = 250
}

variable "budget_prod" {
  description = "Monthly budget limit in USD for the prod environment"
  type        = number
  default     = 1000
}
