resource "tls_private_key" "example" {
  count     = 3
  algorithm = "RSA"
  rsa_bits  = 2048
}

resource "tls_self_signed_cert" "example" {
  count           = 3
  private_key_pem = tls_private_key.example[count.index].private_key_pem

  # Certificate expires after 12 hours.
  validity_period_hours = 12

  early_renewal_hours = 3

  allowed_uses = [
    "key_encipherment",
    "digital_signature",
    "server_auth",
  ]

  dns_names = ["example-${count.index + 1}.com"]

  subject {
    common_name  = "example-${count.index + 1}.com"
    organization = "ACME Examples, Inc"
  }
}

resource "google_compute_ssl_certificate" "example" {
  count       = 3
  name        = "cert-${count.index + 1}"
  private_key = tls_private_key.example[count.index].private_key_pem
  certificate = tls_self_signed_cert.example[count.index].cert_pem
}

resource "tls_private_key" "single_key" {
  algorithm = "RSA"
  rsa_bits  = 2048
}

resource "tls_self_signed_cert" "single_cert" {
  private_key_pem = tls_private_key.single_key.private_key_pem

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