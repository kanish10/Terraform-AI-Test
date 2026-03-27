# -----------------------------------------------------------------------------
# Cloud Composer 2 Environment
# -----------------------------------------------------------------------------

resource "google_composer_environment" "main" {
  provider = google-beta
  name     = var.composer_env_name
  region   = var.region
  project  = var.project_id
  labels   = local.common_labels

  config {
    environment_size = var.composer_environment_size
    resilience_mode  = var.composer_resilience_mode

    # -------------------------------------------------------------------------
    # Software Configuration
    # -------------------------------------------------------------------------
    software_config {
      image_version            = var.composer_image_version
      airflow_config_overrides = var.airflow_config_overrides
      pypi_packages            = var.pypi_packages
      env_variables            = var.env_variables
    }

    # -------------------------------------------------------------------------
    # Node Configuration - Private GKE cluster with dedicated SA
    # -------------------------------------------------------------------------
    node_config {
      network              = google_compute_network.main.id
      subnetwork           = google_compute_subnetwork.main.id
      service_account      = google_service_account.composer.email
      tags                 = ["composer-node"]
      enable_ip_masq_agent = true

      ip_allocation_policy {
        cluster_secondary_range_name  = "pods"
        services_secondary_range_name = "services"
      }
    }

    # -------------------------------------------------------------------------
    # Private Environment - No public endpoints
    # -------------------------------------------------------------------------
    private_environment_config {
      enable_private_endpoint                = true
      enable_privately_used_public_ips       = false
      master_ipv4_cidr_block                 = var.master_ipv4_cidr_block
      cloud_sql_ipv4_cidr_block              = var.cloud_sql_ipv4_cidr_block
      cloud_composer_network_ipv4_cidr_block = var.cloud_composer_network_ipv4_cidr_block
      connection_type                        = "VPC_PEERING"
    }

    # -------------------------------------------------------------------------
    # Master Authorized Networks - Restrict GKE API access to VPC subnet only
    # -------------------------------------------------------------------------
    master_authorized_networks_config {
      enabled = true

      cidr_blocks {
        cidr_block   = var.subnet_cidr
        display_name = "VPC Subnet"
      }
    }

    # -------------------------------------------------------------------------
    # CMEK Encryption
    # -------------------------------------------------------------------------
    encryption_config {
      kms_key_name = google_kms_crypto_key.composer.id
    }

    # -------------------------------------------------------------------------
    # Web Server Access Control - IP allowlisting
    # -------------------------------------------------------------------------
    web_server_network_access_control {
      dynamic "allowed_ip_range" {
        for_each = var.web_server_allowed_ip_ranges
        content {
          value       = allowed_ip_range.value.value
          description = allowed_ip_range.value.description
        }
      }
    }

    # -------------------------------------------------------------------------
    # Workloads Configuration - Resource tuning
    # -------------------------------------------------------------------------
    workloads_config {
      scheduler {
        cpu        = var.scheduler_cpu
        memory_gb  = var.scheduler_memory_gb
        storage_gb = var.scheduler_storage_gb
        count      = var.scheduler_count
      }

      web_server {
        cpu        = var.web_server_cpu
        memory_gb  = var.web_server_memory_gb
        storage_gb = var.web_server_storage_gb
      }

      worker {
        cpu        = var.worker_cpu
        memory_gb  = var.worker_memory_gb
        storage_gb = var.worker_storage_gb
        min_count  = var.worker_min_count
        max_count  = var.worker_max_count
      }

      triggerer {
        cpu       = var.triggerer_cpu
        memory_gb = var.triggerer_memory_gb
        count     = var.triggerer_count
      }
    }

    # -------------------------------------------------------------------------
    # Maintenance Window
    # -------------------------------------------------------------------------
    maintenance_window {
      start_time = var.maintenance_window_start
      end_time   = var.maintenance_window_end
      recurrence = var.maintenance_window_recurrence
    }

    # -------------------------------------------------------------------------
    # Recovery - Daily scheduled snapshots
    # -------------------------------------------------------------------------
    recovery_config {
      scheduled_snapshots_config {
        enabled                    = true
        snapshot_location          = var.region
        snapshot_creation_schedule = "0 4 * * *"
        time_zone                  = "UTC"
      }
    }
  }

  depends_on = [
    google_project_service.apis,
    google_kms_crypto_key_iam_member.cmek_bindings,
    google_project_iam_member.composer_worker,
    google_project_iam_member.log_writer,
    google_project_iam_member.metric_writer,
    google_service_account_iam_member.composer_agent_v2ext,
    google_compute_router_nat.main,
  ]

  timeouts {
    create = "120m"
    update = "120m"
    delete = "30m"
  }
}
