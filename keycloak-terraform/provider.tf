terraform {
  required_providers {
    keycloak = {
      source  = "mrparkers/keycloak"
      version = "4.4.0"
    }
  }
}

provider "keycloak" {
    client_id     = "admin-cli"
    url      = var.keycloak_url
    username = var.keycloak_username
    password = var.keycloak_password
}