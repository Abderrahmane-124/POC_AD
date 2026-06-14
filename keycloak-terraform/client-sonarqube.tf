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


}