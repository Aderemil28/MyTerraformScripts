# gcp-alloydb-postgres

An AlloyDB for PostgreSQL cluster built to a sensible DBA baseline:

- Primary instance, **regional** (standby in another zone with automatic failover) by default
- Optional **read pool** for read traffic
- **Continuous backup** for point-in-time recovery (14 days by default)
- **Automated full backups** on a weekly schedule, kept by count
- A fixed **maintenance window**
- **Encrypted connections only**, with the option to allow only the Auth Proxy and connectors
- **Query Insights** on
- **Private IP only** (needs private services access on the VPC)
- **Deletion protection** on

## Usage

```hcl
data "google_secret_manager_secret_version" "alloydb_admin" {
  project = "my-project"
  secret  = "alloydb-admin-password"
}

module "alloydb" {
  source = "../../modules/gcp-alloydb-postgres"

  project_id            = "my-project"
  region                = "northamerica-northeast2"
  cluster_id            = "appdb-dev"
  network_id            = "projects/my-project/global/networks/my-vpc"
  allocated_ip_range    = module.psa.range_name
  initial_user_password = data.google_secret_manager_secret_version.alloydb_admin.secret_data

  availability_type = "ZONAL" # dev
  primary_cpu_count = 2

  database_flags = {
    "log_min_duration_statement" = "1000"
  }

  labels = { env = "dev", owner = "dba" }
}
```

A full working example is in [examples/alloydb-dev](../../examples/alloydb-dev).

## Inputs

| Name | Description | Default |
|---|---|---|
| `project_id` | Project for the cluster | required |
| `region` | Region for the cluster and backups | required |
| `cluster_id` | Cluster name (instances get `-primary` / `-read-pool`) | required |
| `network_id` | VPC network ID | required |
| `initial_user_password` | Password for the initial user (sensitive; read from Secret Manager) | required |
| `allocated_ip_range` | Private services access range name | `null` |
| `database_version` | PostgreSQL major version (`POSTGRES_14` to `POSTGRES_18`) | `POSTGRES_18` |
| `initial_user` | Initial user name | `postgres` |
| `availability_type` | `REGIONAL` or `ZONAL` | `REGIONAL` |
| `primary_cpu_count` | vCPUs for the primary | `2` |
| `read_pool_node_count` | Read pool nodes (0 = none) | `0` |
| `read_pool_cpu_count` | vCPUs per read pool node | `2` |
| `database_flags` | PostgreSQL settings as flags | `{}` |
| `require_connectors` | Only allow Auth Proxy / connectors | `false` |
| `pitr_window_days` | Point-in-time recovery window (1 to 35) | `14` |
| `backup_days_of_week` | Days for automated backups | every day |
| `backup_start_hour` | Backup start hour (UTC) | `5` |
| `backup_retention_count` | Automated backups to keep | `14` |
| `maintenance_day` | Maintenance day | `SUNDAY` |
| `maintenance_start_hour` | Maintenance start hour (UTC) | `6` |
| `labels` | Labels for everything created | `{}` |
| `deletion_protection` | Block terraform destroy | `true` |

## Outputs

| Name | Description |
|---|---|
| `cluster_name` | Full resource name of the cluster |
| `primary_instance_name` | Full resource name of the primary (for the Auth Proxy) |
| `primary_ip_address` | Private IP of the primary |
| `read_pool_ip_address` | Private IP of the read pool, or null |

## Notes

- **The password is in Terraform state.** Keep state in a locked-down GCS bucket. With Terraform 1.11 or later you can use the provider's write-only `password_wo` argument instead, which keeps it out of state
- **`database_version` upgrades are one way.** Changing it to a higher version upgrades the cluster in place and can't be reversed
- **Some database flags restart the instance.** Apply flag changes in a window
- **Tearing down:** set `deletion_protection = false`, apply, then destroy
- After the first apply, connect and run the [MyPostgresScripts](https://github.com/Aderemil28/MyPostgresScripts) `server-overview.sql` and `settings-review.sql` to check the result
