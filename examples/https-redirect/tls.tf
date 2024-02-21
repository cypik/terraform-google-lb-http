resource "tls_private_key" "example" {
  algorithm = "RSA"
  rsa_bits  = 2048
}

resource "tls_self_signed_cert" "example" {
  private_key_pem = tls_private_key.example.private_key_pem

  # Certificate expires after 12 hours.
  validity_period_hours = 12

  early_renewal_hours = 3

  allowed_uses = [
    "key_encipherment",
    "digital_signature",
    "server_auth",
  ]

  dns_names = ["example.com"]

  subject {
    common_name  = "example.com"
    organization = "ACME Examples, Inc"
  }
}

resource "google_compute_ssl_certificate" "example" {
  name        = "${var.network_name}-cert"
  private_key = tls_private_key.example.private_key_pem
  certificate = tls_self_signed_cert.example.cert_pem
}