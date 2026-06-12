resource "keycloak_ldap_user_federation" "ldap_user_federation" {
  name     = "POC terraform"
  realm_id = keycloak_realm.realm.id
  enabled  = true

  username_ldap_attribute = "cn"
  rdn_ldap_attribute      = "cn"
  uuid_ldap_attribute     = "objectGUID"
  user_object_classes     = [
    "person",
    "organizationalPerson",
    "user"
  ]
  connection_url          = "ldap://samba:389"
  users_dn                = "OU=lab-users,DC=corp,DC=localdomain"
  bind_dn                 = "CN=svc_keycloak,OU=lab-user-service,DC=corp,DC=localdomain"
  bind_credential         = "Password@123"

  edit_mode               = "READ_ONLY"

}

resource "keycloak_ldap_group_mapper" "ldap_group_mapper" {
  realm_id                = keycloak_realm.realm.id
  ldap_user_federation_id = keycloak_ldap_user_federation.ldap_user_federation.id
  name                    = "groups mapper"

  ldap_groups_dn                 = "OU=lab-groups,DC=corp,DC=localdomain"
  group_name_ldap_attribute      = "cn"
  group_object_classes           = [
    "group"
  ]
  membership_attribute_type      = "DN"
  membership_ldap_attribute      = "member"
  membership_user_ldap_attribute = "sAMAccountName"
  memberof_ldap_attribute        = "memberOf"
}
