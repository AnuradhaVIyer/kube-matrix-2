variable "name" {
  type        = string
  description = "ECR repository name"
}

variable "scan_on_push" {
  type    = bool
  default = true
}

variable "lifecycle_days" {
  type    = number
  default = 30
}

variable "project" {}
variable "environment" {}

