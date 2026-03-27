# -----------------------------------------------------------------------------
# Composer Environment
# -----------------------------------------------------------------------------

output "composer_environment_id" {
  description = "The full resource ID of the Composer environment"
  value       = google_composer_environment.main.id
}

output "composer_environment_name" {
  description = "The name of the Composer environment"
  value       = google_composer_environment.main.name
}

output "airflow_uri" {
  description = "The URI of the Airflow web interface (accessible only via VPC/IAP)"
  value       = google_composer_environment.main.config[0].airflow_uri
}

output "dag_gcs_prefix" {
  description = "The GCS prefix for uploading DAG files"
  value       = google_composer_environment.main.config[0].dag_gcs_prefix
}

output "gke_cluster" {
  description = "The GKE cluster backing the Composer environment"
  value       = google_composer_environment.main.config[0].gke_cluster
  sensitive   = true
}

# -----------------------------------------------------------------------------
# Service Account
# -----------------------------------------------------------------------------

output "composer_service_account_email" {
  description = "The email of the Composer service account"
  value       = google_service_account.composer.email
}

# -----------------------------------------------------------------------------
# Networking
# -----------------------------------------------------------------------------

output "network_self_link" {
  description = "The self-link of the VPC network"
  value       = google_compute_network.main.self_link
}

output "subnet_self_link" {
  description = "The self-link of the Composer subnet"
  value       = google_compute_subnetwork.main.self_link
}

# -----------------------------------------------------------------------------
# KMS
# -----------------------------------------------------------------------------

output "kms_key_id" {
  description = "The ID of the CMEK key used for encryption"
  value       = google_kms_crypto_key.composer.id
}
