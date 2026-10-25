# gcp-cloudsql-postgres

A Cloud SQL for PostgreSQL instance built to a sensible DBA baseline:

- **Private IP only** (no public IP; needs private services access on the VPC)
- **Encrypted connections only**
- **Regional** (standby in another zone with automatic failover) by default
- **Daily backups** kept by count, plus **point-in-time recovery**
- A fixed **maintenance window** on the `stable` update track
- **Query Insights** on
- **Deletion protection** in Terraform and in Google Cloud
- Optional databases and built-in users

## Usage

```hcl
data "google_secret_manager_secret_version" "app_user" {
  project = "my-project"
  secret  = "cloudsql-app-user-password"
}

module "cloudsql" {
  source = "../../modules/gcp-cloudsql-postgres"

  project_id         = "my-project"
  region             = "northamerica-northeast2"
  instance_name      = "appdb-dev"
  network_id         = "projects/my-project/global/networks/my-vpc"
  allocated_ip_range = module.psa.range_name

  availability_type = "ZONAL" # dev
  tier              = "db-custom-2-7680"

  databases = ["appdb"]
  users     = { app_user = data.google_secret_manager_secret_version.app_user.secret_data }

  labels = { env = "dev", owner = "dba" }
}
```

A full working example is in [examples/cloudsql-postgres-dev](../../examples/cloudsql-postgres-dev).

## Inputs

| Name | Description | Default |
|---|---|---|
| `project_id` | Project for the instance | required |
| `region` | Region | required |
| `instance_name` | Instance name | required |
| `network_id` | VPC network ID | required |
| `allocated_ip_range` | Private services access range name | `null` |
| `database_version` | For example `POSTGRES_18` | `POSTGRES_18` |
| `edition` | `ENTERPRISE` or `ENTERPRISE_PLUS` (the tier must match) | `ENTERPRISE` |
| `tier` | Machine type | `db-custom-2-7680` |
| `availability_type` | `REGIONAL` or `ZONAL` | `REGIONAL` |
| `disk_size_gb` | Starting disk size (autoresize on) | `20` |
| `backup_start_time` | Daily backup start, `HH:MM` UTC | `05:00` |
| `transaction_log_retention_days` | WAL kept for PITR | `7` |
| `retained_backups` | Daily backups to keep | `14` |
| `maintenance_day` | 1 (Monday) to 7 (Sunday) | `7` |
| `maintenance_hour` | 0 to 23 UTC | `6` |
| `database_flags` | PostgreSQL settings as flags | `{}` |
| `databases` | Databases to create | `[]` |
| `users` | Built-in users as `{ name = password }` (sensitive) | `{}` |
| `labels` | Instance labels | `{}` |
| `deletion_protection` | Block deletion in Terraform and Google Cloud | `true` |

## Outputs

| Name | Description |
|---|---|
| `instance_name` | Instance name |
| `connection_name` | `project:region:instance`, for the Auth Proxy |
| `private_ip_address` | Private IP |
| `databases` | Databases created |

## Notes

- **Edition and tier go together.** If you set `database_version` to POSTGRES_16 or later without an edition, Cloud SQL defaults to ENTERPRISE_PLUS, which needs a `db-perf-optimized-N-*` tier. This module sets the edition explicitly to avoid that surprise
- **Passwords are in Terraform state.** Keep state in a locked-down GCS bucket, or create users outside Terraform, or use IAM database authentication
- **Some database flags restart the instance.** Apply flag changes in a window
- **Disks only grow.** Autoresize can increase the disk; nothing can shrink it
- **Tearing down:** set `deletion_protection = false`, apply, then destroy
