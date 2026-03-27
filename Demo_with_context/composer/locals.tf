# -----------------------------------------------------------------------------
# Local Values
# -----------------------------------------------------------------------------

data "google_project" "current" {
  project_id = var.project_id
}

locals {
  # Naming
  resource_prefix = "${var.project_id}-${var.environment}"
  composer_sa_id  = "composer-${var.environment}-sa"
  network_name    = "${var.vpc_name}-${var.environment}"
  subnet_name     = "${local.network_name}-subnet-01"
  router_name     = "${local.network_name}-router"
  nat_name        = "${local.network_name}-nat"

  # Labels applied to all resources
  common_labels = merge(
    var.labels,
    {
      environment = var.environment
      managed_by  = "terraform"
      component   = "cloud-composer"
    }
  )

  # Project number for service agent email construction
  project_number = data.google_project.current.number

  # Service agent emails that need CMEK access
  composer_service_agent          = "service-${local.project_number}@cloudcomposer-accounts.iam.gserviceaccount.com"
  gke_service_agent               = "service-${local.project_number}@container-engine-robot.iam.gserviceaccount.com"
  pubsub_service_agent            = "service-${local.project_number}@gcp-sa-pubsub.iam.gserviceaccount.com"
  compute_service_agent           = "service-${local.project_number}@compute-system.iam.gserviceaccount.com"
  artifact_registry_service_agent = "service-${local.project_number}@gcp-sa-artifactregistry.iam.gserviceaccount.com"
  storage_service_agent           = "service-${local.project_number}@gs-project-accounts.iam.gserviceaccount.com"

  cmek_service_agents = [
    local.composer_service_agent,
    local.gke_service_agent,
    local.pubsub_service_agent,
    local.compute_service_agent,
    local.artifact_registry_service_agent,
    local.storage_service_agent,
  ]
}
