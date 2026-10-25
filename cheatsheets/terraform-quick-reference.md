# Terraform quick reference

## The everyday loop

```bash
terraform init                     # download providers and modules, set up the backend
terraform fmt -recursive           # format every .tf file
terraform validate                 # check syntax and references
terraform plan -out=tfplan         # show what will change, save the plan
terraform apply tfplan             # apply exactly the saved plan
terraform output                   # show outputs
```

Always read the plan before applying. In the summary line, **destroy** or **replace** (`-/+`) on a database is the line to stop at.

## Reading a plan

| Symbol | Meaning |
|---|---|
| `+` | create |
| `~` | update in place |
| `-/+` | destroy and re-create (**data loss on a database**) |
| `-` | destroy |
| `<=` | read a data source |

`# forces replacement` next to an attribute tells you which change causes a re-create.

## State

```bash
terraform state list                                   # everything Terraform manages
terraform state show module.alloydb.google_alloydb_cluster.this
terraform state mv <old address> <new address>         # after renaming a resource
terraform state rm <address>                           # stop managing it (does not delete it)
terraform import <address> <cloud id>                  # bring an existing resource under Terraform
terraform force-unlock <lock id>                       # only if a crashed run left the state locked
```

Prefer `moved` and `import` blocks in code over the commands: they show up in a plan and get reviewed.

```hcl
moved {
  from = google_sql_database_instance.main
  to   = module.cloudsql.google_sql_database_instance.this
}

import {
  to = google_sql_database_instance.this
  id = "projects/my-project/instances/appdb-pg-dev"
}
```

## Safety habits for databases

- Keep `deletion_protection = true` everywhere except throwaway dev
- Add `lifecycle { prevent_destroy = true }` to anything you can't afford to lose
- Never use `-target` as a habit; it skips dependencies. Use it only to recover from a problem, then run a full plan
- `terraform plan -refresh-only` shows drift (changes made in the console) without changing anything
- State contains passwords: keep it in a locked-down GCS bucket with versioning, never in git
- Pin provider versions (`version = "~> 8.0"`) and commit `.terraform.lock.hcl` for root configurations

## Variables

```bash
terraform plan -var="project_id=my-project"
terraform plan -var-file=dev.tfvars
export TF_VAR_project_id=my-project
```

Order of precedence (last wins): defaults, `terraform.tfvars`, `*.auto.tfvars`, `-var-file`, `-var`.

## Useful when stuck

```bash
TF_LOG=DEBUG terraform plan 2> debug.log   # provider-level logging
terraform providers                        # which providers each module needs
terraform graph | dot -Tpng > graph.png    # dependency graph (needs Graphviz)
terraform console                          # try expressions: > cidrsubnet("10.0.0.0/16", 8, 1)
```
