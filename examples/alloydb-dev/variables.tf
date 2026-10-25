variable "project_id" {
  description = "Project to build in."
  type        = string
}

variable "region" {
  description = "Region for the cluster."
  type        = string
  default     = "northamerica-northeast2"
}

variable "network_name" {
  description = "Name of the existing VPC network."
  type        = string
}

variable "cluster_id" {
  description = "Cluster name."
  type        = string
  default     = "appdb-dev"
}

variable "admin_password_secret" {
  description = "Secret Manager secret that holds the initial user's password."
  type        = string
  default     = "alloydb-dev-admin-password"
}
