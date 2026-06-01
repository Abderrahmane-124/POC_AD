#! /bin/bash

DOCKER_EXEC="docker exec samba"

# Créer l'OU pour ranger les utilisateurs
$DOCKER_EXEC samba-tool ou add "OU=lab-users"

# Créer l'OU pour ranger les groupes
$DOCKER_EXEC samba-tool ou add "OU=lab-groups"

# Créer l'OU pour ranger les compt de services (pour keyclock et vault)
$DOCKER_EXEC samba-tool ou add "OU=lab-user-service"

# creer les utilisateurs et les ajouter dans leurs OU
$DOCKER_EXEC samba-tool user create svc_keycloak Password@123 --description="Compte de lecture pour Keycloak" --userou="OU=lab-user-service"
$DOCKER_EXEC samba-tool user create a.elb Password@123 --userou="OU=lab-users"
$DOCKER_EXEC samba-tool user create h.ait Password@123 --userou="OU=lab-users"

# creer les groupes et les ajouter dans leurs OU
$DOCKER_EXEC samba-tool group add Admins_DevSecOps --groupou="OU=lab-groups"
$DOCKER_EXEC samba-tool group add Devs --groupou="OU=lab-groups"

# ajouter les users a leur groups
$DOCKER_EXEC samba-tool group addmembers Admins_DevSecOps a.elb
$DOCKER_EXEC samba-tool group addmembers Devs h.ait


