variable "project_id" {
  description = "Project to build in."
  type        = string
}

variable "region" {
  description = "Region for the instance."
  type        = string
  default     = "northamerica-northeast2"
}

variable "network_name" {
  description = "Name of the existing VPC network."
  type        = string
}

variable "instance_name" {
  description = "Instance name."
  type        = string
  default     = "appdb-pg-dev"
}

variable "app_user_password_secret" {
  description = "Secret Manager secret that holds app_user's password."
  type        = string
  default     = "cloudsql-dev-app-user-password"
}
