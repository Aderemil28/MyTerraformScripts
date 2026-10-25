variable "project_id" {
  description = "Project to create the cluster in."
  type        = string
}

variable "region" {
  description = "Region for the cluster and its backups, for example northamerica-northeast2 (Toronto)."
  type        = string
}

variable "cluster_id" {
  description = "Cluster name. Lower case letters, numbers and hyphens. Instances are named <cluster_id>-primary and <cluster_id>-read-pool."
  type        = string

  validation {
    condition     = can(regex("^[a-z][a-z0-9-]{0,62}$", var.cluster_id))
    error_message = "cluster_id must start with a letter and use only lower case letters, numbers and hyphens (max 63 characters)."
  }
}

variable "network_id" {
  description = "VPC network ID, in the form projects/<project>/global/networks/<name>. The VPC needs private services access."
  type        = string
}

variable "allocated_ip_range" {
  description = "Name of the private services access range to use (range_name output of the gcp-private-service-access module). Null lets Google pick any range on the peering."
  type        = string
  default     = null
}

variable "database_version" {
  description = "PostgreSQL major version: POSTGRES_14 to POSTGRES_18. Defaults to 18, the latest AlloyDB supports (AlloyDB itself defaults to 17 if none is set). Raising it later upgrades the cluster, which cannot be undone."
  type        = string
  default     = "POSTGRES_18"
}

variable "initial_user" {
  description = "Name of the initial database user (gets the alloydbsuperuser role)."
  type        = string
  default     = "postgres"
}

variable "initial_user_password" {
  description = "Password for the initial user. Read it from Secret Manager in the calling configuration; never put it in a .tfvars file. It is stored in Terraform state, so the state bucket must be locked down."
  type        = string
  sensitive   = true
}

variable "availability_type" {
  description = "REGIONAL gives the primary a standby in another zone with automatic failover. ZONAL is cheaper, for dev and test."
  type        = string
  default     = "REGIONAL"

  validation {
    condition     = contains(["REGIONAL", "ZONAL"], var.availability_type)
    error_message = "availability_type must be REGIONAL or ZONAL."
  }
}

variable "primary_cpu_count" {
  description = "vCPUs for the primary instance, for example 2, 4, 8 or 16 (memory scales with it). Check the AlloyDB docs for the sizes available in your region."
  type        = number
  default     = 2
}

variable "read_pool_node_count" {
  description = "Nodes in the read pool. 0 means no read pool."
  type        = number
  default     = 0

  validation {
    condition     = var.read_pool_node_count >= 0 && floor(var.read_pool_node_count) == var.read_pool_node_count
    error_message = "read_pool_node_count must be a whole number, 0 or more."
  }
}

variable "read_pool_cpu_count" {
  description = "vCPUs for each read pool node."
  type        = number
  default     = 2
}

variable "database_flags" {
  description = "PostgreSQL settings as AlloyDB database flags, for example { \"log_min_duration_statement\" = \"1000\" }. Some flags restart the instance when changed."
  type        = map(string)
  default     = {}
}

variable "require_connectors" {
  description = "When true, only the AlloyDB Auth Proxy and language connectors can connect (IAM-authorized). Direct psql connections are refused."
  type        = bool
  default     = false
}

variable "pitr_window_days" {
  description = "Continuous backup window: you can restore to any point in the last N days (1 to 35)."
  type        = number
  default     = 14

  validation {
    condition     = var.pitr_window_days >= 1 && var.pitr_window_days <= 35
    error_message = "pitr_window_days must be between 1 and 35."
  }
}

variable "backup_days_of_week" {
  description = "Days to take the automated full backup."
  type        = list(string)
  default     = ["MONDAY", "TUESDAY", "WEDNESDAY", "THURSDAY", "FRIDAY", "SATURDAY", "SUNDAY"]

  validation {
    condition = length(var.backup_days_of_week) > 0 && alltrue([
      for d in var.backup_days_of_week : contains(["MONDAY", "TUESDAY", "WEDNESDAY", "THURSDAY", "FRIDAY", "SATURDAY", "SUNDAY"], d)
    ])
    error_message = "backup_days_of_week needs at least one day, written in capitals (MONDAY to SUNDAY)."
  }
}

variable "backup_start_hour" {
  description = "Hour (0 to 23, UTC) the automated backup starts."
  type        = number
  default     = 5
}

variable "backup_retention_count" {
  description = "Number of automated backups to keep."
  type        = number
  default     = 14
}

variable "maintenance_day" {
  description = "Day for Google's maintenance updates (MONDAY to SUNDAY)."
  type        = string
  default     = "SUNDAY"
}

variable "maintenance_start_hour" {
  description = "Hour (0 to 23, UTC) the maintenance window starts."
  type        = number
  default     = 6
}

variable "labels" {
  description = "Labels for the cluster, instances and backups, for example { env = \"dev\", owner = \"dba\" }."
  type        = map(string)
  default     = {}
}

variable "deletion_protection" {
  description = "When true, Terraform refuses to destroy the cluster. Set to false and apply before a planned teardown."
  type        = bool
  default     = true
}
