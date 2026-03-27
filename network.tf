# -----------------------------------------------------------------------------
# VPC Network
# -----------------------------------------------------------------------------

resource "google_compute_network" "main" {
  name                    = local.network_name
  project                 = var.project_id
  auto_create_subnetworks = false
  routing_mode            = "REGIONAL"

  depends_on = [google_project_service.apis]
}

# -----------------------------------------------------------------------------
# Subnet with secondary ranges for GKE pods and services
# -----------------------------------------------------------------------------

resource "google_compute_subnetwork" "main" {
  name                     = local.subnet_name
  project                  = var.project_id
  region                   = var.region
  network                  = google_compute_network.main.id
  ip_cidr_range            = var.subnet_cidr
  private_ip_google_access = true

  secondary_ip_range {
    range_name    = "pods"
    ip_cidr_range = var.pods_secondary_cidr
  }

  secondary_ip_range {
    range_name    = "services"
    ip_cidr_range = var.services_secondary_cidr
  }

  log_config {
    aggregation_interval = "INTERVAL_10_MIN"
    flow_sampling        = 0.5
    metadata             = "INCLUDE_ALL_METADATA"
  }
}

# -----------------------------------------------------------------------------
# Cloud Router (required for Cloud NAT)
# -----------------------------------------------------------------------------

resource "google_compute_router" "main" {
  name    = local.router_name
  project = var.project_id
  region  = var.region
  network = google_compute_network.main.id
}

# -----------------------------------------------------------------------------
# Cloud NAT - Provides outbound internet for private IP nodes
# -----------------------------------------------------------------------------

resource "google_compute_router_nat" "main" {
  name                               = local.nat_name
  project                            = var.project_id
  region                             = var.region
  router                             = google_compute_router.main.name
  nat_ip_allocate_option             = "AUTO_ONLY"
  source_subnetwork_ip_ranges_to_nat = "ALL_SUBNETWORKS_ALL_IP_RANGES"

  log_config {
    enable = true
    filter = "ERRORS_ONLY"
  }
}

# -----------------------------------------------------------------------------
# Firewall Rules
# -----------------------------------------------------------------------------

# Allow internal communication within VPC ranges
resource "google_compute_firewall" "allow_internal" {
  name    = "${local.network_name}-allow-internal"
  project = var.project_id
  network = google_compute_network.main.id

  direction = "INGRESS"
  priority  = 1000

  source_ranges = [
    var.subnet_cidr,
    var.pods_secondary_cidr,
    var.services_secondary_cidr,
  ]

  target_tags = ["composer-node"]

  allow {
    protocol = "tcp"
  }

  allow {
    protocol = "udp"
  }

  allow {
    protocol = "icmp"
  }

  log_config {
    metadata = "INCLUDE_ALL_METADATA"
  }
}

# Allow Google health check probes
resource "google_compute_firewall" "allow_health_checks" {
  name    = "${local.network_name}-allow-health-checks"
  project = var.project_id
  network = google_compute_network.main.id

  direction = "INGRESS"
  priority  = 1000

  source_ranges = [
    "130.211.0.0/22",
    "35.191.0.0/16",
  ]

  target_tags = ["composer-node"]

  allow {
    protocol = "tcp"
  }

  log_config {
    metadata = "INCLUDE_ALL_METADATA"
  }
}

# Allow IAP tunneling for SSH access to private nodes
resource "google_compute_firewall" "allow_iap_ssh" {
  name    = "${local.network_name}-allow-iap-ssh"
  project = var.project_id
  network = google_compute_network.main.id

  direction = "INGRESS"
  priority  = 1000

  source_ranges = ["35.235.240.0/20"]

  target_tags = ["composer-node"]

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  log_config {
    metadata = "INCLUDE_ALL_METADATA"
  }
}

# Default deny all ingress from the internet
resource "google_compute_firewall" "deny_all_ingress" {
  name    = "${local.network_name}-deny-all-ingress"
  project = var.project_id
  network = google_compute_network.main.id

  direction = "INGRESS"
  priority  = 65534

  source_ranges = ["0.0.0.0/0"]

  deny {
    protocol = "all"
  }

  log_config {
    metadata = "INCLUDE_ALL_METADATA"
  }
}
