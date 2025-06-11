variable "project" {
  description = "Nom du projet"
  type        = string
  default     = "projet-c"
}

variable "environment" {
  description = "Environnement de déploiement"
  type        = string
  default     = "local"
}

variable "region" {
  description = "Région AWS"
  type        = string
  default     = "ca-central-1"
}

variable "vpc_cidr" {
  description = "CIDR du VPC"
  type        = string
  default     = "10.0.0.0/16"
}
