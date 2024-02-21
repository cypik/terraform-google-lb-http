variable "host_project" {
  type        = string
  default     = "testing-gcp-ops"
  description = "ID for the Shared VPC host project"
}

variable "service_project" {
  type        = string
  default     = "testing-gcp-ops"
  description = "ID for the Shared VPC service project where instances will be deployed"
}