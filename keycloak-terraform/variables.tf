variable "keycloak_url" {
    description = "The base URL of your Keycloak instance"
    type        = string
    default     = "http://keycloak:8080"
}

variable "keycloak_username" {
    description = "Keycloak admin username"
    type        = string
    sensitive   = true
    default     = "admin"
}

variable "keycloak_password" {
    description = "Keycloak admin password"
    type        = string
    sensitive   = true
    default     = "admin"
}

