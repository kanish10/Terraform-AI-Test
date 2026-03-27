# -----------------------------------------------------------------------------
# Project & Region
# -----------------------------------------------------------------------------

variable "project_id" {
  description = "The GCP project ID where resources will be created"
  type        = string
}

variable "region" {
  description = "The GCP region for all resources"
  type        = string
  default     = "us-central1"
}

variable "environment" {
  description = "Environment name used in resource naming and labels"
  type        = string
  default     = "production"

  validation {
    condition     = contains(["production", "staging", "development"], var.environment)
    error_message = "Environment must be one of: production, staging, development."
  }
}

# -----------------------------------------------------------------------------
# Networking
# -----------------------------------------------------------------------------

variable "vpc_name" {
  description = "Name prefix for the VPC network"
  type        = string
  default     = "composer-vpc"
}

variable "subnet_cidr" {
  description = "Primary CIDR range for the Composer subnet"
  type        = string
  default     = "10.0.0.0/20"
}

variable "pods_secondary_cidr" {
  description = "Secondary CIDR range for GKE pods"
  type        = string
  default     = "10.4.0.0/14"
}

variable "services_secondary_cidr" {
  description = "Secondary CIDR range for GKE services"
  type        = string
  default     = "10.8.0.0/20"
}

variable "master_ipv4_cidr_block" {
  description = "CIDR block for the GKE master network (must be /28)"
  type        = string
  default     = "172.16.0.0/28"
}

variable "cloud_sql_ipv4_cidr_block" {
  description = "CIDR block for Cloud SQL private IP (avoid 172.17.0.0/16 - reserved by Cloud SQL)"
  type        = string
  default     = "10.10.0.0/24"
}

variable "cloud_composer_network_ipv4_cidr_block" {
  description = "CIDR block for the Composer tenant project network"
  type        = string
  default     = "172.31.245.0/24"
}

variable "web_server_allowed_ip_ranges" {
  description = "List of IP ranges allowed to access the Airflow web server"
  type = list(object({
    value       = string
    description = string
  }))
  default = []
}

# -----------------------------------------------------------------------------
# Cloud Composer
# -----------------------------------------------------------------------------

variable "composer_env_name" {
  description = "Name of the Cloud Composer environment"
  type        = string
  default     = "composer-prod"
}

variable "composer_image_version" {
  description = "Composer image version (pin to a specific version for production, e.g. composer-2.16.8-airflow-2.10.5)"
  type        = string
  default     = "composer-2-airflow-2"
}

variable "composer_environment_size" {
  description = "Environment size for Composer 2"
  type        = string
  default     = "ENVIRONMENT_SIZE_SMALL"

  validation {
    condition     = contains(["ENVIRONMENT_SIZE_SMALL", "ENVIRONMENT_SIZE_MEDIUM", "ENVIRONMENT_SIZE_LARGE"], var.composer_environment_size)
    error_message = "Must be one of: ENVIRONMENT_SIZE_SMALL, ENVIRONMENT_SIZE_MEDIUM, ENVIRONMENT_SIZE_LARGE."
  }
}

variable "composer_resilience_mode" {
  description = "Resilience mode for the Composer environment"
  type        = string
  default     = "STANDARD_RESILIENCE"

  validation {
    condition     = contains(["STANDARD_RESILIENCE", "HIGH_RESILIENCE"], var.composer_resilience_mode)
    error_message = "Must be one of: STANDARD_RESILIENCE, HIGH_RESILIENCE."
  }
}

# -----------------------------------------------------------------------------
# Workload Configuration - Scheduler
# -----------------------------------------------------------------------------

variable "scheduler_cpu" {
  description = "CPU allocation for the Airflow scheduler"
  type        = number
  default     = 2
}

variable "scheduler_memory_gb" {
  description = "Memory allocation (GB) for the Airflow scheduler"
  type        = number
  default     = 7.5
}

variable "scheduler_storage_gb" {
  description = "Storage allocation (GB) for the Airflow scheduler"
  type        = number
  default     = 5
}

variable "scheduler_count" {
  description = "Number of scheduler instances"
  type        = number
  default     = 2
}

# -----------------------------------------------------------------------------
# Workload Configuration - Worker
# -----------------------------------------------------------------------------

variable "worker_cpu" {
  description = "CPU allocation for Airflow workers"
  type        = number
  default     = 2
}

variable "worker_memory_gb" {
  description = "Memory allocation (GB) for Airflow workers"
  type        = number
  default     = 7.5
}

variable "worker_storage_gb" {
  description = "Storage allocation (GB) for Airflow workers"
  type        = number
  default     = 5
}

variable "worker_min_count" {
  description = "Minimum number of Airflow workers"
  type        = number
  default     = 2
}

variable "worker_max_count" {
  description = "Maximum number of Airflow workers"
  type        = number
  default     = 6
}

# -----------------------------------------------------------------------------
# Workload Configuration - Web Server
# -----------------------------------------------------------------------------

variable "web_server_cpu" {
  description = "CPU allocation for the Airflow web server"
  type        = number
  default     = 2
}

variable "web_server_memory_gb" {
  description = "Memory allocation (GB) for the Airflow web server"
  type        = number
  default     = 7.5
}

variable "web_server_storage_gb" {
  description = "Storage allocation (GB) for the Airflow web server"
  type        = number
  default     = 5
}

# -----------------------------------------------------------------------------
# Workload Configuration - Triggerer
# -----------------------------------------------------------------------------

variable "triggerer_cpu" {
  description = "CPU allocation for the Airflow triggerer"
  type        = number
  default     = 1
}

variable "triggerer_memory_gb" {
  description = "Memory allocation (GB) for the Airflow triggerer"
  type        = number
  default     = 1
}

variable "triggerer_count" {
  description = "Number of triggerer instances"
  type        = number
  default     = 1
}

# -----------------------------------------------------------------------------
# Airflow Configuration
# -----------------------------------------------------------------------------

variable "airflow_config_overrides" {
  description = "Airflow configuration property overrides (section-name = value)"
  type        = map(string)
  default     = {}
}

variable "pypi_packages" {
  description = "Custom PyPI packages to install (package = version_spec)"
  type        = map(string)
  default     = {}
}

variable "env_variables" {
  description = "Environment variables set in the Composer environment"
  type        = map(string)
  default     = {}
}

# -----------------------------------------------------------------------------
# KMS (Customer-Managed Encryption Keys)
# -----------------------------------------------------------------------------

variable "kms_keyring_name" {
  description = "Name of the KMS keyring"
  type        = string
  default     = "composer-keyring"
}

variable "kms_key_name" {
  description = "Name of the KMS crypto key for CMEK"
  type        = string
  default     = "composer-cmek-key"
}

variable "kms_key_rotation_period" {
  description = "Rotation period for the KMS key (in seconds). Default is 90 days."
  type        = string
  default     = "7776000s"
}

# -----------------------------------------------------------------------------
# Maintenance Window
# -----------------------------------------------------------------------------

variable "maintenance_window_start" {
  description = "Start time of the maintenance window (RFC 3339)"
  type        = string
  default     = "2026-01-01T00:00:00Z"
}

variable "maintenance_window_end" {
  description = "End time of the maintenance window (RFC 3339)"
  type        = string
  default     = "2026-01-01T04:00:00Z"
}

variable "maintenance_window_recurrence" {
  description = "RRULE recurrence for the maintenance window"
  type        = string
  default     = "FREQ=WEEKLY;BYDAY=SU"
}

# -----------------------------------------------------------------------------
# Labels
# -----------------------------------------------------------------------------

variable "labels" {
  description = "Additional labels to apply to all resources"
  type        = map(string)
  default     = {}
}
