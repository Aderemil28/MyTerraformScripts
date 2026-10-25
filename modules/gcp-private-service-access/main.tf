# Private services access: reserves an internal IP range in your VPC and peers
# it with Google's service producer network, so AlloyDB and Cloud SQL get
# private IP addresses inside your network (no public IP needed).
#
# Create this once per VPC. Every AlloyDB cluster and Cloud SQL instance in
# that VPC can share it.

resource "google_compute_global_address" "this" {
  project       = var.project_id
  name          = var.range_name
  description   = "Private services access range for managed databases"
  purpose       = "VPC_PEERING"
  address_type  = "INTERNAL"
  prefix_length = var.prefix_length
  network       = var.network_id
}

resource "google_service_networking_connection" "this" {
  network                 = var.network_id
  service                 = "servicenetworking.googleapis.com"
  reserved_peering_ranges = [google_compute_global_address.this.name]

  # Deleting the peering usually fails while any managed service still uses it,
  # so on destroy Terraform forgets it instead of trying to delete it.
  deletion_policy = var.abandon_on_destroy ? "ABANDON" : "DELETE"
}
