provider "google" {
  project = "testing-gcp-ops"
  region  = "asia-northeast1"
  zone    = "asia-northeast1-a"
}

#####==============================================================================
##### vpc module call.
#####==============================================================================
module "vpc" {
  source                                    = "cypik/vpc/google"
  version                                   = "1.0.1"
  name                                      = "app"
  environment                               = "test"
  routing_mode                              = "REGIONAL"
  network_firewall_policy_enforcement_order = "AFTER_CLASSIC_FIREWALL"
}

#####==============================================================================
##### subnet module call.
#####==============================================================================
module "subnet" {
  source        = "cypik/subnet/google"
  version       = "1.0.1"
  name          = "app"
  environment   = "test"
  subnet_names  = ["subnet-a"]
  gcp_region    = "asia-northeast1"
  network       = module.vpc.vpc_id
  ip_cidr_range = ["10.10.1.0/24"]
}

#####==============================================================================
##### firewall module call.
#####==============================================================================
module "firewall" {
  source        = "cypik/firewall/google"
  version       = "1.0.1"
  name          = "app"
  environment   = "test"
  network       = module.vpc.vpc_id
  source_ranges = ["0.0.0.0/0"]

  allow = [
    { protocol = "tcp"
      ports    = ["22", "80"]
    }
  ]
}

#####==============================================================================
##### instance_template module call.
#####==============================================================================
module "instance_template" {
  source               = "cypik/template-instance/google"
  version              = "1.0.1"
  name                 = "template"
  environment          = "test"
  region               = "asia-northeast1"
  source_image         = "ubuntu-2204-jammy-v20230908"
  source_image_family  = "ubuntu-2204-lts"
  source_image_project = "ubuntu-os-cloud"
  disk_size_gb         = "20"
  subnetwork           = module.subnet.subnet_id
  instance_template    = true
  service_account      = null
  ## public IP if enable_public_ip is true
  enable_public_ip = true
  metadata = {
    ssh-keys = <<EOF
      dev:ssh-rsa AAAAB3NzaC1yc2EAA/3mwt2y+PDQMU= suresh@suresh
    EOF
  }
}

#####==============================================================================
##### instance_group module call.
#####==============================================================================
module "instance_group" {
  source              = "cypik/instance-group/google"
  version             = "1.0.1"
  region              = "asia-northeast1"
  hostname            = "test"
  autoscaling_enabled = true
  instance_template   = module.instance_template.self_link_unique
  min_replicas        = 2
  max_replicas        = 2
  autoscaling_cpu = [{
    target            = 0.5
    predictive_method = ""
  }]

  named_ports = [{
    name = "http"
    port = 80
  }]
}

#####==============================================================================
##### lb-http module call.
#####==============================================================================
module "lb-http" {
  source            = "../../"
  name              = "ci-https-redirect"
  environment       = "test"
  target_tags       = [var.network_name]
  firewall_networks = [module.vpc.vpc_id]
  ssl               = true
  ssl_certificates  = [google_compute_ssl_certificate.example.self_link]
  https_redirect    = true

  backends = {
    default = {
      protocol    = "HTTP"
      port        = 80
      port_name   = "http"
      timeout_sec = 10
      enable_cdn  = false

      health_check = {
        request_path = "/"
        port         = 80
      }

      log_config = {
        enable = false
      }

      groups = [
        {
          group = module.instance_group.instance_group
        }
      ]
      iap_config = {
        enable = false
      }
    }
  }
}