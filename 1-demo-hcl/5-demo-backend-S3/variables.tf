variable "environment" {
  type        = string
  description = "Environnement (dev, staging, prod)"
  default     = "dev"
  
  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment doit être dev, staging ou prod."
  }
}