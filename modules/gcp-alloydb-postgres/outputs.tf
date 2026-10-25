output "cluster_name" {
  description = "Full resource name of the cluster."
  value       = google_alloydb_cluster.this.name
}

output "primary_instance_name" {
  description = "Full resource name of the primary instance (used by the AlloyDB Auth Proxy)."
  value       = google_alloydb_instance.primary.name
}

output "primary_ip_address" {
  description = "Private IP of the primary instance. Applications connect here on port 5432."
  value       = google_alloydb_instance.primary.ip_address
}

output "read_pool_ip_address" {
  description = "Private IP of the read pool, or null if there is no read pool."
  value       = try(google_alloydb_instance.read_pool[0].ip_address, null)
}
