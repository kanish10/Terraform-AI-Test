# -----------------------------------------------------------------------------
# KMS Keyring and Crypto Key for CMEK
# -----------------------------------------------------------------------------

resource "google_kms_key_ring" "composer" {
  name     = var.kms_keyring_name
  location = var.region
  project  = var.project_id

  depends_on = [google_project_service.apis]
}

resource "google_kms_crypto_key" "composer" {
  name            = var.kms_key_name
  key_ring        = google_kms_key_ring.composer.id
  rotation_period = var.kms_key_rotation_period
  purpose         = "ENCRYPT_DECRYPT"

  labels = local.common_labels

  lifecycle {
    prevent_destroy = true
  }
}

# -----------------------------------------------------------------------------
# Grant CMEK access to all required service agents
# -----------------------------------------------------------------------------

resource "google_kms_crypto_key_iam_member" "cmek_bindings" {
  for_each = toset(local.cmek_service_agents)

  crypto_key_id = google_kms_crypto_key.composer.id
  role          = "roles/cloudkms.cryptoKeyEncrypterDecrypter"
  member        = "serviceAccount:${each.value}"
}
