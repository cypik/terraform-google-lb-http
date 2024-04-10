output "external_ip" {
  description = "The external IP assigned to the load balancer."
  value       = module.lb_traffic.external_ip
}

output "service_project" {
  description = "The backend_services the load balancer is in."
  value       = module.lb_traffic.backend_services
}