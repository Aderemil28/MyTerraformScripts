# gcp-private-service-access

Reserves an internal IP range in a VPC and peers it with Google's service producer network ([private services access](https://cloud.google.com/vpc/docs/private-services-access)). AlloyDB and Cloud SQL use this range to get private IP addresses inside your network.

Create it **once per VPC**. Every AlloyDB cluster and Cloud SQL instance in that VPC shares it.

## Usage

```hcl
module "psa" {
  source     = "../../modules/gcp-private-service-access"
  project_id = "my-project"
  network_id = "projects/my-project/global/networks/my-vpc"
}
```

Pass `module.psa.range_name` to the database modules as `allocated_ip_range`. That also makes Terraform wait for the peering before creating the database.

## Inputs

| Name | Description | Default |
|---|---|---|
| `project_id` | Project that owns the VPC | required |
| `network_id` | VPC network ID (`projects/<project>/global/networks/<name>`) | required |
| `range_name` | Name of the reserved range | `google-managed-services-range` |
| `prefix_length` | Size of the range (8 to 24). Must not overlap any subnet or peered network | `16` |
| `abandon_on_destroy` | On destroy, forget the peering instead of deleting it | `true` |

## Outputs

| Name | Description |
|---|---|
| `range_name` | Reserved range name, for `allocated_ip_range` |
| `range_cidr` | The range in CIDR form |

## Notes

- Agree the range with your network team first: it must not overlap any on-premises range reachable over VPN or Interconnect
- If your VPC already has private services access (check **VPC network > Private services access** in the console), don't create a second one: pass the existing range name to the database modules instead
