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
  auto_create_subnetworks                   = true
}

#####==============================================================================
##### gce-lb-http module call.
#####==============================================================================
module "load_balancer" {
  source                = "../../"
  name                  = "traffic-director-lb"
  environment           = "test"
  create_address        = false
  load_balancing_scheme = "INTERNAL_SELF_MANAGED"
  network               = module.vpc.vpc_id
  address               = "0.0.0.0"
  firewall_networks     = []

  backends = {
    default = {
      protocol                        = "HTTP"
      port                            = 80
      port_name                       = "http"
      timeout_sec                     = 30
      connection_draining_timeout_sec = 0
      enable_cdn                      = false

      health_check = {
        check_interval_sec  = 15
        timeout_sec         = 15
        healthy_threshold   = 4
        unhealthy_threshold = 4
        request_path        = "/api/health"
        port                = 443
        logging             = true
      }

      log_config = {
        enable = false
      }

      groups = []

      iap_config = {
        enable = false
      }
    }
  }
}