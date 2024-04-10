# Terraform-google-lb-http
# Terraform Google Cloud lb-Http Module
## Table of Contents

- [Introduction](#introduction)
- [Usage](#usage)
- [Examples](#examples)
- [License](#license)
- [Author](#author)
- [Inputs](#inputs)
- [Outputs](#outputs)

## Introduction
This project deploys a Google Cloud infrastructure using Terraform to create lb-http.
## Usage
To use this module, you should have Terraform installed and configured for GCP. This module provides the necessary Terraform configuration for creating GCP resources, and you can customize the inputs as needed. Below is an example of how to use this module:
## Examples

# Example: cdn-policy
```hcl
module "lb-http" {
  source            = "cypik/lb-http/google"
  version           = "1.0.0"
  name              = "http-lb"
  environment       = "test"
  target_tags       = ["web-server"]
  firewall_networks = [module.vpc.vpc_id]

  backends = {
    default = {
      protocol    = "HTTP"
      port_name   = "http"
      timeout_sec = 10
      enable_cdn  = true

      health_check = {
        request_path = "/"
        port         = 80
      }

      log_config = {
        enable = false
      }

      cdn_policy = {
        cache_mode  = "CACHE_ALL_STATIC"
        default_ttl = 3600
        client_ttl  = 7200
        max_ttl     = 10800
        cache_key_policy = {
          include_host          = true
          include_protocol      = true
          include_query_string  = true
          include_named_cookies = ["__next_preview_data", "__prerender_bypass"]
        }
        bypass_cache_on_request_headers = ["example-header-1", "example-header-2"]
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
```
# Example: certificate-map
```hcl
module "lb-https" {
  source            = "cypik/lb-http/google"
  version           = "1.0.0"
  name              = "lb-https"
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

```

# Example: https-redirect

```hcl

module "lb-http" {
  source            = "cypik/lb-http/google"
  version           = "1.0.0"
  name              = "https-redirect"
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
```
# Example: shared-vpc

```hcl
module "lb-http" {
  source            = "cypik/lb-http/google"
  version           = "1.0.0"
  name              = "http-lb"
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
```
# Example: traffic-director

```hcl

module "lb_traffic" {
  source                = "cypik/lb-http/google"
  version               = "1.0.0"
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
```

# Example: user-managed-google-managed-ssl

```hcl

module "lb-https" {
  source                          = "cypik/lb-http/google"
  version                         = "1.0.0"
  name                            = "app"
  environment                     = "test"
  firewall_networks               = [module.vpc.self_link]
  url_map                         = google_compute_url_map.https-multi-cert.self_link
  create_url_map                  = false
  ssl                             = true
  create_ssl_certificate          = true
  private_key                     = tls_private_key.single_key.private_key_pem
  certificate                     = tls_self_signed_cert.single_cert.cert_pem
  managed_ssl_certificate_domains = ["test.example.com"]
  ssl_certificates                = google_compute_ssl_certificate.example[*].self_link

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

}
```
You can customize the input variables according to your specific requirements.

## Examples
For detailed examples on how to use this module, please refer to the [Examples](https://github.com/cypik/terraform-google-lb-http/tree/master/examples) directory within this repository.

## Author
Your Name Replace **MIT** and **Cypik** with the appropriate license and your information. Feel free to expand this README with additional details or usage instructions as needed for your specific use case.

## License
This project is licensed under the **MIT** License - see the [LICENSE](https://github.com/cypik/terraform-google-lb-http/blob/master/LICENSE) file for details.

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.6.6 |
| <a name="requirement_google"></a> [google](#requirement\_google) | >= 3.50, < 5.11.0 |
| <a name="requirement_google-beta"></a> [google-beta](#requirement\_google-beta) | >= 4.26, < 5.15.0 |
| <a name="requirement_random"></a> [random](#requirement\_random) | 3.6.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_google"></a> [google](#provider\_google) | >= 3.50, < 5.11.0 |
| <a name="provider_google-beta"></a> [google-beta](#provider\_google-beta) | >= 4.26, < 5.15.0 |
| <a name="provider_random"></a> [random](#provider\_random) | 3.6.0 |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_labels"></a> [labels](#module\_labels) | cypik/labels/google | 1.0.1 |

## Resources

| Name | Type |
|------|------|
| [google-beta_google_compute_backend_service.default](https://registry.terraform.io/providers/hashicorp/google-beta/latest/docs/resources/google_compute_backend_service) | resource |
| [google-beta_google_compute_global_address.default](https://registry.terraform.io/providers/hashicorp/google-beta/latest/docs/resources/google_compute_global_address) | resource |
| [google-beta_google_compute_global_address.default_ipv6](https://registry.terraform.io/providers/hashicorp/google-beta/latest/docs/resources/google_compute_global_address) | resource |
| [google-beta_google_compute_global_forwarding_rule.http](https://registry.terraform.io/providers/hashicorp/google-beta/latest/docs/resources/google_compute_global_forwarding_rule) | resource |
| [google-beta_google_compute_global_forwarding_rule.http_ipv6](https://registry.terraform.io/providers/hashicorp/google-beta/latest/docs/resources/google_compute_global_forwarding_rule) | resource |
| [google-beta_google_compute_global_forwarding_rule.https](https://registry.terraform.io/providers/hashicorp/google-beta/latest/docs/resources/google_compute_global_forwarding_rule) | resource |
| [google-beta_google_compute_global_forwarding_rule.https_ipv6](https://registry.terraform.io/providers/hashicorp/google-beta/latest/docs/resources/google_compute_global_forwarding_rule) | resource |
| [google-beta_google_compute_health_check.default](https://registry.terraform.io/providers/hashicorp/google-beta/latest/docs/resources/google_compute_health_check) | resource |
| [google-beta_google_compute_managed_ssl_certificate.default](https://registry.terraform.io/providers/hashicorp/google-beta/latest/docs/resources/google_compute_managed_ssl_certificate) | resource |
| [google-beta_google_compute_url_map.default](https://registry.terraform.io/providers/hashicorp/google-beta/latest/docs/resources/google_compute_url_map) | resource |
| [google_compute_firewall.default-hc](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_firewall) | resource |
| [google_compute_ssl_certificate.default](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_ssl_certificate) | resource |
| [google_compute_target_http_proxy.default](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_target_http_proxy) | resource |
| [google_compute_target_https_proxy.default](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_target_https_proxy) | resource |
| [google_compute_url_map.https_redirect](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_url_map) | resource |
| [random_id.certificate](https://registry.terraform.io/providers/hashicorp/random/3.6.0/docs/resources/id) | resource |
| [google_client_config.current](https://registry.terraform.io/providers/hashicorp/google/latest/docs/data-sources/client_config) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_address"></a> [address](#input\_address) | Existing IPv4 address to use (the actual IP address value) | `string` | `null` | no |
| <a name="input_backends"></a> [backends](#input\_backends) | Map backend indices to list of backend maps. | <pre>map(object({<br>    port                    = optional(number)<br>    project                 = optional(string)<br>    protocol                = optional(string)<br>    port_name               = optional(string)<br>    description             = optional(string)<br>    enable_cdn              = optional(bool)<br>    compression_mode        = optional(string)<br>    security_policy         = optional(string, null)<br>    edge_security_policy    = optional(string, null)<br>    custom_request_headers  = optional(list(string))<br>    custom_response_headers = optional(list(string))<br><br>    timeout_sec                     = optional(number)<br>    connection_draining_timeout_sec = optional(number)<br>    session_affinity                = optional(string)<br>    affinity_cookie_ttl_sec         = optional(number)<br>    locality_lb_policy              = optional(string)<br><br>    health_check = object({<br>      host                = optional(string)<br>      request_path        = optional(string)<br>      request             = optional(string)<br>      response            = optional(string)<br>      port                = optional(number)<br>      port_name           = optional(string)<br>      proxy_header        = optional(string)<br>      port_specification  = optional(string)<br>      protocol            = optional(string)<br>      check_interval_sec  = optional(number)<br>      timeout_sec         = optional(number)<br>      healthy_threshold   = optional(number)<br>      unhealthy_threshold = optional(number)<br>      logging             = optional(bool)<br>    })<br><br>    log_config = object({<br>      enable      = optional(bool)<br>      sample_rate = optional(number)<br>    })<br><br>    groups = list(object({<br>      group = string<br><br>      balancing_mode               = optional(string)<br>      capacity_scaler              = optional(number)<br>      description                  = optional(string)<br>      max_connections              = optional(number)<br>      max_connections_per_instance = optional(number)<br>      max_connections_per_endpoint = optional(number)<br>      max_rate                     = optional(number)<br>      max_rate_per_instance        = optional(number)<br>      max_rate_per_endpoint        = optional(number)<br>      max_utilization              = optional(number)<br>    }))<br>    iap_config = object({<br>      enable               = bool<br>      oauth2_client_id     = optional(string)<br>      oauth2_client_secret = optional(string)<br>    })<br>    cdn_policy = optional(object({<br>      cache_mode                   = optional(string)<br>      signed_url_cache_max_age_sec = optional(string)<br>      default_ttl                  = optional(number)<br>      max_ttl                      = optional(number)<br>      client_ttl                   = optional(number)<br>      negative_caching             = optional(bool)<br>      negative_caching_policy = optional(object({<br>        code = optional(number)<br>        ttl  = optional(number)<br>      }))<br>      serve_while_stale = optional(number)<br>      cache_key_policy = optional(object({<br>        include_host           = optional(bool)<br>        include_protocol       = optional(bool)<br>        include_query_string   = optional(bool)<br>        query_string_blacklist = optional(list(string))<br>        query_string_whitelist = optional(list(string))<br>        include_http_headers   = optional(list(string))<br>        include_named_cookies  = optional(list(string))<br>      }))<br>      bypass_cache_on_request_headers = optional(list(string))<br>    }))<br>    outlier_detection = optional(object({<br>      base_ejection_time = optional(object({<br>        seconds = number<br>        nanos   = optional(number)<br>      }))<br>      consecutive_errors                    = optional(number)<br>      consecutive_gateway_failure           = optional(number)<br>      enforcing_consecutive_errors          = optional(number)<br>      enforcing_consecutive_gateway_failure = optional(number)<br>      enforcing_success_rate                = optional(number)<br>      interval = optional(object({<br>        seconds = number<br>        nanos   = optional(number)<br>      }))<br>      max_ejection_percent        = optional(number)<br>      success_rate_minimum_hosts  = optional(number)<br>      success_rate_request_volume = optional(number)<br>      success_rate_stdev_factor   = optional(number)<br>    }))<br>  }))</pre> | n/a | yes |
| <a name="input_certificate"></a> [certificate](#input\_certificate) | Content of the SSL certificate. Requires `ssl` to be set to `true` and `create_ssl_certificate` set to `true` | `string` | `null` | no |
| <a name="input_certificate_map"></a> [certificate\_map](#input\_certificate\_map) | Certificate Map ID in format projects/{project}/locations/global/certificateMaps/{name}. Identifies a certificate map associated with the given target proxy.  Requires `ssl` to be set to `true` | `string` | `null` | no |
| <a name="input_create_address"></a> [create\_address](#input\_create\_address) | Create a new global IPv4 address | `bool` | `true` | no |
| <a name="input_create_ipv6_address"></a> [create\_ipv6\_address](#input\_create\_ipv6\_address) | Allocate a new IPv6 address. Conflicts with "ipv6\_address" - if both specified, "create\_ipv6\_address" takes precedence. | `bool` | `false` | no |
| <a name="input_create_ssl_certificate"></a> [create\_ssl\_certificate](#input\_create\_ssl\_certificate) | If `true`, Create certificate using `private_key/certificate` | `bool` | `false` | no |
| <a name="input_create_url_map"></a> [create\_url\_map](#input\_create\_url\_map) | Set to `false` if url\_map variable is provided. | `bool` | `true` | no |
| <a name="input_edge_security_policy"></a> [edge\_security\_policy](#input\_edge\_security\_policy) | The resource URL for the edge security policy to associate with the backend service | `string` | `null` | no |
| <a name="input_enable_ipv6"></a> [enable\_ipv6](#input\_enable\_ipv6) | Enable IPv6 address on the CDN load-balancer | `bool` | `false` | no |
| <a name="input_environment"></a> [environment](#input\_environment) | Environment (e.g. `prod`, `dev`, `staging`). | `string` | `""` | no |
| <a name="input_firewall_networks"></a> [firewall\_networks](#input\_firewall\_networks) | Names of the networks to create firewall rules in | `list(string)` | <pre>[<br>  "default"<br>]</pre> | no |
| <a name="input_firewall_projects"></a> [firewall\_projects](#input\_firewall\_projects) | Names of the projects to create firewall rules in | `list(string)` | <pre>[<br>  "default"<br>]</pre> | no |
| <a name="input_http_forward"></a> [http\_forward](#input\_http\_forward) | Set to `false` to disable HTTP port 80 forward | `bool` | `true` | no |
| <a name="input_https_redirect"></a> [https\_redirect](#input\_https\_redirect) | Set to `true` to enable https redirect on the lb. | `bool` | `false` | no |
| <a name="input_ipv6_address"></a> [ipv6\_address](#input\_ipv6\_address) | An existing IPv6 address to use (the actual IP address value) | `string` | `null` | no |
| <a name="input_label_order"></a> [label\_order](#input\_label\_order) | Label order, e.g. sequence of application name and environment `name`,`environment`,'attribute' [`webserver`,`qa`,`devops`,`public`,] . | `list(any)` | <pre>[<br>  "name",<br>  "environment"<br>]</pre> | no |
| <a name="input_labels"></a> [labels](#input\_labels) | The labels to attach to resources created by this module | `map(string)` | `{}` | no |
| <a name="input_load_balancing_scheme"></a> [load\_balancing\_scheme](#input\_load\_balancing\_scheme) | Load balancing scheme type (EXTERNAL for classic external load balancer, EXTERNAL\_MANAGED for Envoy-based load balancer, and INTERNAL\_SELF\_MANAGED for traffic director) | `string` | `"EXTERNAL"` | no |
| <a name="input_managed_ssl_certificate_domains"></a> [managed\_ssl\_certificate\_domains](#input\_managed\_ssl\_certificate\_domains) | Create Google-managed SSL certificates for specified domains. Requires `ssl` to be set to `true` | `list(string)` | `[]` | no |
| <a name="input_managedby"></a> [managedby](#input\_managedby) | ManagedBy, eg 'cypik'. | `string` | `"cypik"` | no |
| <a name="input_name"></a> [name](#input\_name) | Name of the resource. Provided by the client when the resource is created. | `string` | `""` | no |
| <a name="input_network"></a> [network](#input\_network) | Network for INTERNAL\_SELF\_MANAGED load balancing scheme | `string` | `"default"` | no |
| <a name="input_private_key"></a> [private\_key](#input\_private\_key) | Content of the private SSL key. Requires `ssl` to be set to `true` and `create_ssl_certificate` set to `true` | `string` | `null` | no |
| <a name="input_quic"></a> [quic](#input\_quic) | Specifies the QUIC override policy for this resource. Set true to enable HTTP/3 and Google QUIC support, false to disable both. Defaults to null which enables support for HTTP/3 only. | `bool` | `null` | no |
| <a name="input_random_certificate_suffix"></a> [random\_certificate\_suffix](#input\_random\_certificate\_suffix) | Bool to enable/disable random certificate name generation. Set and keep this to true if you need to change the SSL cert. | `bool` | `false` | no |
| <a name="input_repository"></a> [repository](#input\_repository) | Terraform current module repo | `string` | `"https://github.com/cypik/terraform-google-lb-http"` | no |
| <a name="input_security_policy"></a> [security\_policy](#input\_security\_policy) | The resource URL for the security policy to associate with the backend service | `string` | `null` | no |
| <a name="input_server_tls_policy"></a> [server\_tls\_policy](#input\_server\_tls\_policy) | The resource URL for the server TLS policy to associate with the https proxy service | `string` | `null` | no |
| <a name="input_ssl"></a> [ssl](#input\_ssl) | Set to `true` to enable SSL support. If `true` then at least one of these are required: 1) `ssl_certificates` OR 2) `create_ssl_certificate` set to `true` and `private_key/certificate` OR  3) `managed_ssl_certificate_domains`, OR 4) `certificate_map` | `bool` | `false` | no |
| <a name="input_ssl_certificates"></a> [ssl\_certificates](#input\_ssl\_certificates) | SSL cert self\_link list. Requires `ssl` to be set to `true` | `list(string)` | `[]` | no |
| <a name="input_ssl_policy"></a> [ssl\_policy](#input\_ssl\_policy) | Selfink to SSL Policy | `string` | `null` | no |
| <a name="input_target_service_accounts"></a> [target\_service\_accounts](#input\_target\_service\_accounts) | List of target service accounts for health check firewall rule. Exactly one of target\_tags or target\_service\_accounts should be specified. | `list(string)` | `[]` | no |
| <a name="input_target_tags"></a> [target\_tags](#input\_target\_tags) | List of target tags for health check firewall rule. Exactly one of target\_tags or target\_service\_accounts should be specified. | `list(string)` | `[]` | no |
| <a name="input_url_map"></a> [url\_map](#input\_url\_map) | The url\_map resource to use. Default is to send all traffic to first backend. | `string` | `null` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_backend_services"></a> [backend\_services](#output\_backend\_services) | The backend service resources. |
| <a name="output_external_ip"></a> [external\_ip](#output\_external\_ip) | The external IPv4 assigned to the global fowarding rule. |
| <a name="output_external_ipv6_address"></a> [external\_ipv6\_address](#output\_external\_ipv6\_address) | The external IPv6 assigned to the global fowarding rule. |
| <a name="output_http_proxy"></a> [http\_proxy](#output\_http\_proxy) | The HTTP proxy used by this module. |
| <a name="output_https_proxy"></a> [https\_proxy](#output\_https\_proxy) | The HTTPS proxy used by this module. |
| <a name="output_ipv6_enabled"></a> [ipv6\_enabled](#output\_ipv6\_enabled) | Whether IPv6 configuration is enabled on this load-balancer |
| <a name="output_ssl_certificate_created"></a> [ssl\_certificate\_created](#output\_ssl\_certificate\_created) | The SSL certificate create from key/pem |
| <a name="output_url_map"></a> [url\_map](#output\_url\_map) | The default URL map used by this module. |
<!-- END_TF_DOCS -->