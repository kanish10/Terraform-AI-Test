# -----------------------------------------------------------------------------
# Access Log Bucket — receives storage access logs from the PII bucket
# Label: sec_log = "storage_bucket_access" (per policy requirement #5)
# -----------------------------------------------------------------------------

resource "google_storage_bucket" "access_logs" {
  project  = var.project_id
  name     = "${var.bucket_name}-access-logs"
  location = var.region

  storage_class               = "STANDARD"
  uniform_bucket_level_access = true
  public_access_prevention    = "enforced"

  labels = {
    sec_log = "storage_bucket_access"
  }

  lifecycle_rule {
    action {
      type = "Delete"
    }
    condition {
      age = var.data_access_log_retention_days
    }
  }

  soft_delete_policy {
    retention_duration_in_seconds = var.soft_delete_retention_seconds
  }
}

# -----------------------------------------------------------------------------
# PII Data Bucket — private bucket with enforced security controls
# -----------------------------------------------------------------------------

resource "google_storage_bucket" "pii_data" {
  project  = var.project_id
  name     = var.bucket_name
  location = var.region

  storage_class               = var.storage_class
  uniform_bucket_level_access = true

  # Requirement #1: Prevent public access
  public_access_prevention = "enforced"

  # Requirement #3: Mandatory labels
  labels = merge(
    {
      sec_assets        = var.data_description
      sec_assets_pii    = "y"
      sec_assets_public = "n"
    },
    var.additional_labels,
  )

  # Requirement #2: Object retention period (sensitive data containing PII)
  retention_policy {
    is_locked        = true
    retention_period = var.object_retention_days * 86400 # convert days to seconds
  }

  # Requirement #2: Lifecycle deletion after retention period expires
  lifecycle_rule {
    action {
      type = "Delete"
    }
    condition {
      age = var.object_retention_days
    }
  }

  # Requirement #5: Access log configuration to the dedicated log bucket
  logging {
    log_bucket        = google_storage_bucket.access_logs.name
    log_object_prefix = "${var.bucket_name}/access-logs"
  }

  soft_delete_policy {
    retention_duration_in_seconds = var.soft_delete_retention_seconds
  }

  versioning {
    enabled = true
  }
}

# -----------------------------------------------------------------------------
# Requirement #4: Log sinks for admin activity and data access audit logs
# Admin activity logs — retained > 1 year
# Data access logs  — retained > 2 years (PII requirement)
# -----------------------------------------------------------------------------

resource "google_storage_bucket" "admin_activity_logs" {
  project  = var.project_id
  name     = "${var.bucket_name}-admin-activity-logs"
  location = var.region

  storage_class               = "STANDARD"
  uniform_bucket_level_access = true
  public_access_prevention    = "enforced"

  labels = {
    sec_log = "activity"
  }

  lifecycle_rule {
    action {
      type = "Delete"
    }
    condition {
      age = var.admin_activity_log_retention_days
    }
  }

  soft_delete_policy {
    retention_duration_in_seconds = var.soft_delete_retention_seconds
  }
}

resource "google_storage_bucket" "data_access_logs" {
  project  = var.project_id
  name     = "${var.bucket_name}-data-access-logs"
  location = var.region

  storage_class               = "STANDARD"
  uniform_bucket_level_access = true
  public_access_prevention    = "enforced"

  labels = {
    sec_log = "data_access"
  }

  lifecycle_rule {
    action {
      type = "Delete"
    }
    condition {
      age = var.data_access_log_retention_days
    }
  }

  soft_delete_policy {
    retention_duration_in_seconds = var.soft_delete_retention_seconds
  }
}

# -----------------------------------------------------------------------------
# Log Sinks — route audit logs to their respective buckets
# -----------------------------------------------------------------------------

resource "google_logging_project_sink" "admin_activity" {
  project     = var.project_id
  name        = "${var.bucket_name}-admin-activity-sink"
  destination = "storage.googleapis.com/${google_storage_bucket.admin_activity_logs.name}"

  filter = "resource.type=\"gcs_bucket\" AND resource.labels.bucket_name=\"${var.bucket_name}\" AND log_id(\"cloudaudit.googleapis.com/activity\")"

  unique_writer_identity = true
}

resource "google_logging_project_sink" "data_access" {
  project     = var.project_id
  name        = "${var.bucket_name}-data-access-sink"
  destination = "storage.googleapis.com/${google_storage_bucket.data_access_logs.name}"

  filter = "resource.type=\"gcs_bucket\" AND resource.labels.bucket_name=\"${var.bucket_name}\" AND log_id(\"cloudaudit.googleapis.com/data_access\")"

  unique_writer_identity = true
}

# -----------------------------------------------------------------------------
# IAM — grant log sink service accounts write access to log buckets
# -----------------------------------------------------------------------------

resource "google_storage_bucket_iam_member" "admin_activity_writer" {
  bucket = google_storage_bucket.admin_activity_logs.name
  role   = "roles/storage.objectCreator"
  member = google_logging_project_sink.admin_activity.writer_identity
}

resource "google_storage_bucket_iam_member" "data_access_writer" {
  bucket = google_storage_bucket.data_access_logs.name
  role   = "roles/storage.objectCreator"
  member = google_logging_project_sink.data_access.writer_identity
}
