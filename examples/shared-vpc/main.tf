provider "google" {
  project = "testing-gcp-ops"
  region  = "asia-northeast1"
  zone    = "asia-northeast1-a"
}

#####==============================================================================
##### gce-lb-http module call.
#####==============================================================================
module "gce-lb-http" {
  source            = "../../"
  name              = "group-http-lb"
  environment       = "test"
  target_tags       = ["allow-shared-vpc-mig"]
  firewall_projects = [var.host_project]
  firewall_networks = [module.vpc.vpc_id]

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
        enable      = true
        sample_rate = 1.0
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