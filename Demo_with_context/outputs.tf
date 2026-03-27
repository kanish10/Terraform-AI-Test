# -----------------------------------------------------------------------------
# Outputs
# -----------------------------------------------------------------------------

output "pii_bucket_name" {
  description = "Name of the PII data bucket"
  value       = google_storage_bucket.pii_data.name
}

output "pii_bucket_url" {
  description = "URL of the PII data bucket"
  value       = google_storage_bucket.pii_data.url
}

output "access_log_bucket_name" {
  description = "Name of the storage access log bucket"
  value       = google_storage_bucket.access_logs.name
}

output "admin_activity_log_bucket_name" {
  description = "Name of the admin activity audit log bucket"
  value       = google_storage_bucket.admin_activity_logs.name
}

output "data_access_log_bucket_name" {
  description = "Name of the data access audit log bucket"
  value       = google_storage_bucket.data_access_logs.name
}
