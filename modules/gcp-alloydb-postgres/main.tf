# AlloyDB for PostgreSQL: one cluster with a primary instance (regional HA by
# default), optional read pool, continuous backup (point-in-time recovery),
# weekly automated backups, a maintenance window, encrypted connections only,
# and Query Insights.

resource "google_alloydb_cluster" "this" {
  project          = var.project_id
  cluster_id       = var.cluster_id
  location         = var.region
  database_version = var.database_version
  labels           = var.labels

  network_config {
    network            = var.network_id
    allocated_ip_range = var.allocated_ip_range
  }

  initial_user {
    user     = var.initial_user
    password = var.initial_user_password
  }

  # Point-in-time recovery to any moment in the last N days
  continuous_backup_config {
    enabled              = true
    recovery_window_days = var.pitr_window_days
  }

  # Scheduled full backups, kept by count
  automated_backup_policy {
    enabled       = true
    location      = var.region
    backup_window = "3600s"
    labels        = var.labels

    weekly_schedule {
      days_of_week = var.backup_days_of_week
      start_times {
        hours   = var.backup_start_hour
        minutes = 0
        seconds = 0
        nanos   = 0
      }
    }

    quantity_based_retention {
      count = var.backup_retention_count
    }
  }

  maintenance_update_policy {
    maintenance_windows {
      day = var.maintenance_day
      start_time {
        hours   = var.maintenance_start_hour
        minutes = 0
        seconds = 0
        nanos   = 0
      }
    }
  }

  deletion_protection = var.deletion_protection
}

resource "google_alloydb_instance" "primary" {
  cluster           = google_alloydb_cluster.this.name
  instance_id       = "${var.cluster_id}-primary"
  instance_type     = "PRIMARY"
  availability_type = var.availability_type
  database_flags    = var.database_flags
  labels            = var.labels

  machine_config {
    cpu_count = var.primary_cpu_count
  }

  client_connection_config {
    require_connectors = var.require_connectors
    ssl_config {
      ssl_mode = "ENCRYPTED_ONLY"
    }
  }

  query_insights_config {
    query_string_length     = 1024
    record_application_tags = true
    record_client_address   = true
    query_plans_per_minute  = 5
  }
}

resource "google_alloydb_instance" "read_pool" {
  count = var.read_pool_node_count > 0 ? 1 : 0

  cluster       = google_alloydb_cluster.this.name
  instance_id   = "${var.cluster_id}-read-pool"
  instance_type = "READ_POOL"
  labels        = var.labels

  read_pool_config {
    node_count = var.read_pool_node_count
  }

  machine_config {
    cpu_count = var.read_pool_cpu_count
  }

  client_connection_config {
    require_connectors = var.require_connectors
    ssl_config {
      ssl_mode = "ENCRYPTED_ONLY"
    }
  }

  # A read pool can only be created once the primary exists
  depends_on = [google_alloydb_instance.primary]
}
