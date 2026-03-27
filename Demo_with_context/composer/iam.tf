# -----------------------------------------------------------------------------
# Dedicated Service Account with least-privilege roles
# -----------------------------------------------------------------------------

resource "google_service_account" "composer" {
  account_id   = local.composer_sa_id
  display_name = "Cloud Composer Service Account - ${var.environment}"
  description  = "Least-privilege service account for Cloud Composer ${var.environment} environment"
  project      = var.project_id
}

resource "google_project_iam_member" "composer_worker" {
  project = var.project_id
  role    = "roles/composer.worker"
  member  = "serviceAccount:${google_service_account.composer.email}"
}

resource "google_project_iam_member" "log_writer" {
  project = var.project_id
  role    = "roles/logging.logWriter"
  member  = "serviceAccount:${google_service_account.composer.email}"
}

resource "google_project_iam_member" "metric_writer" {
  project = var.project_id
  role    = "roles/monitoring.metricWriter"
  member  = "serviceAccount:${google_service_account.composer.email}"
}

# -----------------------------------------------------------------------------
# Composer Service Agent V2 Extension
# -----------------------------------------------------------------------------

resource "google_service_account_iam_member" "composer_agent_v2ext" {
  service_account_id = google_service_account.composer.name
  role               = "roles/composer.ServiceAgentV2Ext"
  member             = "serviceAccount:${local.composer_service_agent}"
}
