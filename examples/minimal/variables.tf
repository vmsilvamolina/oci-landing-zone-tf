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
