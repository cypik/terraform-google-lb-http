output "load-balancer-ip" {
  value       = module.gce-lb-https.external_ip
  description = "The IP address of the HTTP load balancer"
}