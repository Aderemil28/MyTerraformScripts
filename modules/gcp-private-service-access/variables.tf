variable "project_id" {
  description = "Project that owns the VPC."
  type        = string
}

variable "network_id" {
  description = "VPC network ID, in the form projects/<project>/global/networks/<name>."
  type        = string
}

variable "range_name" {
  description = "Name of the reserved IP range."
  type        = string
  default     = "google-managed-services-range"
}

variable "prefix_length" {
  description = "Size of the reserved range. 16 gives a /16 (65,536 addresses), enough for many instances. Must not overlap any subnet or peered network."
  type        = number
  default     = 16

  validation {
    condition     = var.prefix_length >= 8 && var.prefix_length <= 24
    error_message = "prefix_length must be between 8 and 24."
  }
}

variable "abandon_on_destroy" {
  description = "When true, terraform destroy removes the peering from state instead of deleting it in Google Cloud."
  type        = bool
  default     = true
}
