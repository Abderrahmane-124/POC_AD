resource "keycloak_saml_client" "saml_client" {
  realm_id  = keycloak_realm.realm.id
  client_id = "sonarqube"
  name      = "sonarqube"
  
  valid_redirect_uris    = [
    "http://localhost:9000/oauth2/callback/saml"
  ]
  name_id_format          = "username"

  sign_documents          = true
  sign_assertions         = false
  include_authn_statement = true
  signature_algorithm     = "RSA_SHA256"
  signature_key_name     = "NONE"
}

# mappers

resource "keycloak_saml_user_property_protocol_mapper" "saml_username_property_mapper" {
  realm_id  = keycloak_realm.realm.id
  client_id = keycloak_saml_client.saml_client.id
  name      = "name"

  user_property              = "username"
  saml_attribute_name        = "name"
  saml_attribute_name_format = "Basic"
}

resource "keycloak_saml_user_property_protocol_mapper" "saml_login_property_mapper" {
  realm_id  = keycloak_realm.realm.id
  client_id = keycloak_saml_client.saml_client.id
  name      = "login"

  user_property              = "username"
  saml_attribute_name        = "login"
  saml_attribute_name_format = "Basic"
}

# groups mapper maybe worng
resource "keycloak_generic_protocol_mapper" "saml_group_mapper" {
  realm_id        = keycloak_realm.realm.id
  client_id       = keycloak_saml_client.saml_client.id
  name            = "Groups"
  protocol        = "saml"
  protocol_mapper = "saml-hardcode-attribute-mapper"
  config = {
    "attribute.name"       = "groups"
    "attribute.nameformat" = "Basic"
  }
}