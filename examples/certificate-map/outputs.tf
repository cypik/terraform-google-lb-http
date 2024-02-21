output "group1_region" {
  value = var.group1_region
}

output "load-balancer-ip" {
  value       = module.gce-lb-https.external_ip
  description = "The IP address of the HTTP load balancer"
}