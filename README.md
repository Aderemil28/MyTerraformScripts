# MyTerraformScripts

My personal Terraform for managed PostgreSQL on Google Cloud: reusable modules for **AlloyDB** and **Cloud SQL for PostgreSQL**, the networking they need, working dev examples, and a quick reference.

Every module is built to a DBA baseline: private IP only, encrypted connections only, high availability by default, automated backups with point-in-time recovery, a fixed maintenance window, Query Insights, labels, and deletion protection.

## Modules

| Module | What it builds |
|---|---|
| [gcp-private-service-access](modules/gcp-private-service-access) | The reserved IP range and VPC peering that give managed databases private IPs. Once per VPC |
| [gcp-alloydb-postgres](modules/gcp-alloydb-postgres) | AlloyDB cluster, primary instance (regional HA), optional read pool, continuous backup, automated backups |
| [gcp-cloudsql-postgres](modules/gcp-cloudsql-postgres) | Cloud SQL for PostgreSQL instance, backups and PITR, maintenance window, optional databases and users |

## Examples

| Example | What it does |
|---|---|
| [alloydb-dev](examples/alloydb-dev) | Enables the APIs, sets up private services access on an existing VPC, reads the admin password from Secret Manager, builds a zonal 2 vCPU cluster |
| [cloudsql-postgres-dev](examples/cloudsql-postgres-dev) | Same pattern for a zonal Cloud SQL instance with one database and one application user |

## Running an example

```bash
cd examples/alloydb-dev
cp terraform.tfvars.example terraform.tfvars      # fill in project and VPC
# optional: cp backend.tf.example backend.tf      # keep state in GCS

gcloud auth application-default login
terraform init
terraform plan -out=tfplan
terraform apply tfplan
```

Create the Secret Manager secret first (the command is in the example's `main.tf`). Passwords never go in `.tfvars` files.

## Conventions

- **Provider:** `hashicorp/google ~> 8.0`, Terraform 1.5 or later
- **Secrets:** read from Secret Manager in the calling configuration, passed as `sensitive` variables. They still end up in state, so state lives in a locked-down GCS bucket
- **Safe defaults:** `deletion_protection = true` and `availability_type = "REGIONAL"` unless an example says otherwise for dev
- **No real names:** project, network and bucket names in examples are placeholders

## Validation

Every module and example passes `terraform fmt` and `tflint` (core rules plus the Google ruleset). Every resource attribute and nested block was also checked against the Google provider's documentation (v8.8). `terraform validate` and `plan` need the provider downloaded and a real project, so run them in your own environment before the first apply.

## Cheat sheet

- [Terraform quick reference](cheatsheets/terraform-quick-reference.md): the everyday loop, reading a plan, state commands, `moved` and `import` blocks, safety habits for databases

## Related

- [MyPostgresScripts](https://github.com/Aderemil28/MyPostgresScripts): PostgreSQL DBA scripts to run against what these modules build
- [MySqlScripts](https://github.com/Aderemil28/MySqlScripts): my SQL Server toolkit
- [SQL Server Docs](https://github.com/Aderemil28/sql-server-docs): my step-by-step runbooks
