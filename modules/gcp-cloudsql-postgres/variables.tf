variable "project_id" {
  description = "Project to create the instance in."
  type        = string
}

variable "region" {
  description = "Region, for example northamerica-northeast2 (Toronto)."
  type        = string
}

variable "instance_name" {
  description = "Instance name. Lower case letters, numbers and hyphens. A deleted name can't be reused for about a week."
  type        = string

  validation {
    condition     = can(regex("^[a-z][a-z0-9-]{0,96}$", var.instance_name))
    error_message = "instance_name must start with a letter and use only lower case letters, numbers and hyphens."
  }
}

variable "network_id" {
  description = "VPC network ID, in the form projects/<project>/global/networks/<name>. The VPC needs private services access."
  type        = string
}

variable "allocated_ip_range" {
  description = "Name of the private services access range to use (range_name output of the gcp-private-service-access module). Null lets Google pick."
  type        = string
  default     = null
}

variable "database_version" {
  description = "For example POSTGRES_16."
  type        = string
  default     = "POSTGRES_16"
}

variable "edition" {
  description = "ENTERPRISE or ENTERPRISE_PLUS. The tier must match the edition (db-custom-* for ENTERPRISE, db-perf-optimized-N-* for ENTERPRISE_PLUS)."
  type        = string
  default     = "ENTERPRISE"

  validation {
    condition     = contains(["ENTERPRISE", "ENTERPRISE_PLUS"], var.edition)
    error_message = "edition must be ENTERPRISE or ENTERPRISE_PLUS."
  }
}

variable "tier" {
  description = "Machine type. db-custom-<vCPUs>-<memory MB>, for example db-custom-2-7680 (2 vCPU, 7.5 GB) for ENTERPRISE."
  type        = string
  default     = "db-custom-2-7680"
}

variable "availability_type" {
  description = "REGIONAL gives a standby in another zone with automatic failover. ZONAL is cheaper, for dev and test."
  type        = string
  default     = "REGIONAL"

  validation {
    condition     = contains(["REGIONAL", "ZONAL"], var.availability_type)
    error_message = "availability_type must be REGIONAL or ZONAL."
  }
}

variable "disk_size_gb" {
  description = "Starting disk size in GB. Autoresize grows it; it can never be shrunk."
  type        = number
  default     = 20
}

variable "backup_start_time" {
  description = "HH:MM (UTC) when the daily backup starts."
  type        = string
  default     = "05:00"
}

variable "transaction_log_retention_days" {
  description = "Days of WAL kept for point-in-time recovery (1 to 7 for ENTERPRISE, up to 35 for ENTERPRISE_PLUS)."
  type        = number
  default     = 7
}

variable "retained_backups" {
  description = "Number of daily backups to keep."
  type        = number
  default     = 14
}

variable "maintenance_day" {
  description = "Maintenance day, 1 (Monday) to 7 (Sunday)."
  type        = number
  default     = 7

  validation {
    condition     = var.maintenance_day >= 1 && var.maintenance_day <= 7
    error_message = "maintenance_day must be 1 (Monday) to 7 (Sunday)."
  }
}

variable "maintenance_hour" {
  description = "Maintenance start hour, 0 to 23 (UTC)."
  type        = number
  default     = 6
}

variable "database_flags" {
  description = "PostgreSQL settings as Cloud SQL flags, for example { \"log_min_duration_statement\" = \"1000\" }. Some flags restart the instance when changed."
  type        = map(string)
  default     = {}
}

variable "databases" {
  description = "Databases to create on the instance."
  type        = list(string)
  default     = []
}

variable "users" {
  description = "Built-in database users to create, as { name = password }. Read the passwords from Secret Manager in the calling configuration. Passwords are stored in Terraform state."
  type        = map(string)
  default     = {}
  sensitive   = true
}

variable "labels" {
  description = "Labels for the instance, for example { env = \"dev\", owner = \"dba\" }."
  type        = map(string)
  default     = {}
}

variable "deletion_protection" {
  description = "When true, both Terraform and Google Cloud refuse to delete the instance."
  type        = bool
  default     = true
}
