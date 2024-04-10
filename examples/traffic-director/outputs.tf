output "external_ip" {
  description = "The external IP assigned to the load balancer."
  value       = module.lb_traffic.external_ip
}

output "service_project" {
  description = "The service project the load balancer is in."
  value       = module.lb_traffic.backend_services
}