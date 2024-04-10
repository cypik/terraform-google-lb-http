output "load-balancer-ip" {
  value       = module.lb-https.external_ip
  description = "The IP address of the HTTP load balancer"
}

output "asset-url" {
  value = "https://${module.lb-https.external_ip}/assets/gcp-logo.svg"
}