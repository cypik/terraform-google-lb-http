provider "google" {
  project = "testing-gcp-ops"
  region  = "asia-northeast1"
  zone    = "asia-northeast1-a"
}

resource "random_id" "assets-bucket" {
  prefix      = "terraform-static-content-"
  byte_length = 2
}

locals {
  health_check = {
    request_path = "/"
    port         = 80
  }
}

module "gce-lb-https" {
  source            = "../../"
  name              = var.network_name
  environment       = "test"
  firewall_networks = [module.vpc.vpc_id]
  url_map           = google_compute_url_map.https-multi-cert.self_link
  create_url_map    = false
  ssl               = true
  certificate_map   = local.cert_map_name

  backends = {
    default = {
      protocol    = "HTTP"
      port        = 80
      port_name   = "http"
      timeout_sec = 10
      enable_cdn  = false

      health_check = local.health_check
      log_config = {
        enable      = true
        sample_rate = 1.0
      }
      groups = [
        {
          group = module.instance_group.instance_group
        },
      ]

      iap_config = {
        enable = false
      }
    }

    mig1 = {
      protocol    = "HTTP"
      port        = 80
      port_name   = "http"
      timeout_sec = 10
      enable_cdn  = false

      health_check = local.health_check
      log_config = {
        enable      = true
        sample_rate = 1.0
      }
      groups = [
        {
          group = module.instance_group.instance_group
        },
      ]

      iap_config = {
        enable = false
      }
    }
  }

  depends_on = [google_certificate_manager_certificate_map.certificate_map]
}

resource "google_compute_url_map" "https-multi-cert" {
  name            = var.network_name
  default_service = module.gce-lb-https.backend_services["default"].self_link

  host_rule {
    hosts        = ["*"]
    path_matcher = "allpaths"
  }

  path_matcher {
    name            = "allpaths"
    default_service = module.gce-lb-https.backend_services["default"].self_link

    path_rule {
      paths = [
        "/group1",
        "/group1/*"
      ]
      service = module.gce-lb-https.backend_services["mig1"].self_link
    }

    path_rule {
      paths = [
        "/assets",
        "/assets/*"
      ]
      service = google_compute_backend_bucket.assets.self_link
    }
  }
}

resource "google_compute_backend_bucket" "assets" {
  name        = random_id.assets-bucket.hex
  description = "Contains static resources for example app"
  bucket_name = google_storage_bucket.assets.name
  enable_cdn  = true
}

resource "google_storage_bucket" "assets" {
  name          = random_id.assets-bucket.hex
  location      = "US"
  force_destroy = true
}


resource "google_storage_bucket_object" "image" {
  name         = "assets/gcp-logo.svg"
  content      = " "
  content_type = "text/plain; charset=utf-8"
  bucket       = google_storage_bucket.assets.name
}

resource "google_storage_object_acl" "image-acl" {
  bucket         = google_storage_bucket.assets.name
  object         = google_storage_bucket_object.image.name
  predefined_acl = "publicRead"
}