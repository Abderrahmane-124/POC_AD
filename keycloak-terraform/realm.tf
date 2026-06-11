resource "keycloak_realm" "realm" {
  realm             = "terraform-realm"
  enabled           = true
  display_name      = "Terraform Realm"
}