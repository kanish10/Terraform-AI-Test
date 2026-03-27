# -----------------------------------------------------------------------------
# Project & Region
# -----------------------------------------------------------------------------

variable "project_id" {
  description = "The GCP project ID where resources will be created"
  type        = string
}

variable "region" {
  description = "The GCP region for the bucket"
  type        = string
  default     = "us-central1"
}

# -----------------------------------------------------------------------------
# Bucket Configuration
# -----------------------------------------------------------------------------

variable "bucket_name" {
  description = "Name of the PII data GCS bucket"
  type        = string
}

variable "storage_class" {
  description = "Storage class for the bucket"
  type        = string
  default     = "STANDARD"

  validation {
    condition     = contains(["STANDARD", "NEARLINE", "COLDLINE", "ARCHIVE"], var.storage_class)
    error_message = "Must be one of: STANDARD, NEARLINE, COLDLINE, ARCHIVE."
  }
}

variable "data_description" {
  description = "Description of the data stored in this bucket (used for sec_assets label)"
  type        = string
}

# -----------------------------------------------------------------------------
# Retention & Lifecycle
# -----------------------------------------------------------------------------

variable "object_retention_days" {
  description = "Number of days to retain objects before lifecycle deletion"
  type        = number
  default     = 730
}

variable "soft_delete_retention_seconds" {
  description = "Duration in seconds for soft-delete retention (default 7 days)"
  type        = number
  default     = 604800
}

# -----------------------------------------------------------------------------
# Logging
# -----------------------------------------------------------------------------

variable "data_access_log_retention_days" {
  description = "Retention in days for data access logs (PII requires > 2 years)"
  type        = number
  default     = 731

  validation {
    condition     = var.data_access_log_retention_days > 730
    error_message = "PII data access logs must be retained for more than 2 years (730 days)."
  }
}

variable "admin_activity_log_retention_days" {
  description = "Retention in days for admin activity logs (requires > 1 year)"
  type        = number
  default     = 366

  validation {
    condition     = var.admin_activity_log_retention_days > 365
    error_message = "Admin activity logs must be retained for more than 1 year (365 days)."
  }
}

# -----------------------------------------------------------------------------
# Labels
# -----------------------------------------------------------------------------

variable "additional_labels" {
  description = "Additional labels to apply to the bucket"
  type        = map(string)
  default     = {}
}
