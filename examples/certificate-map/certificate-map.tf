locals {
  cert_map_name = "projects/${var.project_id}/locations/global/certificateMaps/certmgr-map"
}

data "google_client_config" "current" {
}

resource "google_certificate_manager_certificate" "all" {
  name        = "certmgr-cert"
  description = "The default cert for all domains"
  project     = data.google_client_config.current.project
  managed {
    domains = [
      "suresh.influbot.ai",
    ]
  }
}

resource "google_certificate_manager_certificate_map" "certificate_map" {
  name        = "certmgr-map"
  description = "My certificate map"
  project     = data.google_client_config.current.project
}

resource "google_certificate_manager_certificate_map_entry" "map_entry_web1" {
  project      = data.google_client_config.current.project
  name         = "certmgr-map-entry-web1"
  description  = "My test certificate map entry"
  map          = google_certificate_manager_certificate_map.certificate_map.name
  certificates = [google_certificate_manager_certificate.all.id]
  hostname     = "suresh.influbot.ai"
}