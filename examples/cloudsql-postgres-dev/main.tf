# Dev Cloud SQL for PostgreSQL: enables the APIs, sets up private services
# access on an existing VPC, and builds a zonal ENTERPRISE instance with one
# database and one application user whose password comes from Secret Manager.

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
    "sqladmin.googleapis.com",
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
#   gcloud secrets create cloudsql-dev-app-user-password --replication-policy=automatic
#   printf '%s' 'the-password' | gcloud secrets versions add cloudsql-dev-app-user-password --data-file=-
data "google_secret_manager_secret_version" "app_user_password" {
  project = var.project_id
  secret  = var.app_user_password_secret

  depends_on = [google_project_service.apis]
}

module "cloudsql" {
  source = "../../modules/gcp-cloudsql-postgres"

  project_id         = var.project_id
  region             = var.region
  instance_name      = var.instance_name
  network_id         = data.google_compute_network.vpc.id
  allocated_ip_range = module.psa.range_name

  # Dev sizing
  edition           = "ENTERPRISE"
  tier              = "db-custom-2-7680"
  availability_type = "ZONAL"
  disk_size_gb      = 20

  database_flags = {
    "log_min_duration_statement" = "1000"
    "log_lock_waits"             = "on"
  }

  databases = ["appdb"]
  users = {
    app_user = data.google_secret_manager_secret_version.app_user_password.secret_data
  }

  labels = {
    env   = "dev"
    owner = "dba"
  }

  # Dev only: allows terraform destroy. Keep true everywhere else.
  deletion_protection = false
}

output "private_ip_address" {
  value = module.cloudsql.private_ip_address
}

output "connection_name" {
  value = module.cloudsql.connection_name
}
