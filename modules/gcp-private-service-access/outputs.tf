output "range_name" {
  description = "Name of the reserved range. Pass it to the AlloyDB or Cloud SQL module as allocated_ip_range; doing so also makes them wait for the peering."
  value       = google_service_networking_connection.this.reserved_peering_ranges[0]
}

output "range_cidr" {
  description = "The reserved range in CIDR form, for firewall rules and documentation."
  value       = "${google_compute_global_address.this.address}/${google_compute_global_address.this.prefix_length}"
}
