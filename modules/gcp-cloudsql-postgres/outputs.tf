output "instance_name" {
  description = "Instance name."
  value       = google_sql_database_instance.this.name
}

output "connection_name" {
  description = "project:region:instance, used by the Cloud SQL Auth Proxy and connectors."
  value       = google_sql_database_instance.this.connection_name
}

output "private_ip_address" {
  description = "Private IP. Applications connect here on port 5432."
  value       = google_sql_database_instance.this.private_ip_address
}

output "databases" {
  description = "Databases created by this module."
  value       = [for d in google_sql_database.this : d.name]
}
