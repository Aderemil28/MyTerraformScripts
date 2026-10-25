# Dev AlloyDB cluster: enables the APIs, sets up private services access on
# an existing VPC, reads the admin password from Secret Manager, and builds a
# zonal cluster with 2 vCPUs and no read pool.

terraform {
  required_version = ">= 1.5"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 8.0"
    }
  }
}

provider "google" {
  project = var.project_id
  region  = var.region
}

locals {
  apis = [
    "alloydb.googleapis.com",
    "compute.googleapis.com",
    "servicenetworking.googleapis.com",
    "secretmanager.googleapis.com",
  ]
}

resource "google_project_service" "apis" {
  for_each = toset(local.apis)

  project            = var.project_id
  service            = each.value
  disable_on_destroy = false
}

data "google_compute_network" "vpc" {
  project = var.project_id
  name    = var.network_name
}

module "psa" {
  source = "../../modules/gcp-private-service-access"

  project_id = var.project_id
  network_id = data.google_compute_network.vpc.id

  depends_on = [google_project_service.apis]
}

# The secret must exist before you apply:
#   gcloud secrets create alloydb-dev-admin-password --replication-policy=automatic
#   printf '%s' 'the-password' | gcloud secrets versions add alloydb-dev-admin-password --data-file=-
data "google_secret_manager_secret_version" "admin_password" {
  project = var.project_id
  secret  = var.admin_password_secret

  depends_on = [google_project_service.apis]
}

module "alloydb" {
  source = "../../modules/gcp-alloydb-postgres"

  project_id            = var.project_id
  region                = var.region
  cluster_id            = var.cluster_id
  network_id            = data.google_compute_network.vpc.id
  allocated_ip_range    = module.psa.range_name
  initial_user_password = data.google_secret_manager_secret_version.admin_password.secret_data

  # Dev sizing: one zone, smallest machine, no read pool
  availability_type    = "ZONAL"
  primary_cpu_count    = 2
  read_pool_node_count = 0
  pitr_window_days     = 7

  database_flags = {
    "log_min_duration_statement" = "1000" # log statements slower than 1 second
    "log_lock_waits"             = "on"
  }

  labels = {
    env   = "dev"
    owner = "dba"
  }

  # Dev only: allows terraform destroy. Keep true everywhere else.
  deletion_protection = false
}

output "primary_ip_address" {
  value = module.alloydb.primary_ip_address
}

output "primary_instance_name" {
  value = module.alloydb.primary_instance_name
}
