output "load-balancer-ip" {
  value       = module.lb-http.external_ip
  description = "The IP address of the HTTP load balancer"
}

output "load-balancer-ipv6" {
  value       = module.lb-http.ipv6_enabled ? module.lb-http.external_ipv6_address : "undefined"
  description = "The IPv6 address of the load-balancer, if enabled; else \"undefined\""
}