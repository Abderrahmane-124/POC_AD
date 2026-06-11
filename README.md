# Pourquoi l'AD seul ne suffit pas
## Les Protocoles de base de l'AD
AD s'appuie sur trois protocoles majeurs.

- **LDAP (Lightweight Directory Access Protocol)** : Le standard de lecture/écriture

  - Ce que c'est : C'est le langage utilisé pour interroger et modifier l'annuaire.

  - Pourquoi tu dois le connaître : C'est ce protocole que tu utiliseras à 99% du temps en DevSecOps. Quand tu configures GitLab, SonarQube, ArgoCD ou Keycloak pour s'authentifier sur l'AD d'entreprise, tu vas configurer un "Connecteur LDAP".

- **Kerberos** : Le vigile de l'authentification

  - Ce que c'est : C'est le protocole de sécurité (basé sur des tickets) utilisé par défaut par Windows pour vérifier les mots de passe de manière ultra-sécurisée sans jamais les faire transiter en clair sur le réseau.

  - Pourquoi tu dois le connaître : C'est lui qui permet le SSO natif sous Windows (ne pas retaper son mot de passe pour accéder à un dossier réseau).

- **DNS (Domain Name System)** : L'annuaire téléphonique interne

  	- Ce que c'est : L'AD ne peut pas fonctionner sans DNS. C'est lui qui permet aux machines de trouver l'adresse IP physique des "Domain Controllers" sur le réseau.

  - Pourquoi tu dois le connaître : Si ton infrastructure (ex: un cluster Kubernetes) ne parvient pas à joindre l'AD, le problème vient très souvent d'une mauvaise résolution DNS, et non de l'AD lui-même.


## Limites des 3 protocoles de l'AD
### Limite 1 : Kerberos est bloqué dans le réseau local (LAN)
- Le protocole Kerberos nécessite une connexion réseau directe (une ligne de vue) avec le Contrôleur de Domaine pour fonctionner. Il ne passe pas les pare-feux publics.

- **Le Problème :** Impossible d'utiliser Kerberos pour authentifier des utilisateurs sur Internet ou pour gérer facilement la sécurité entre des conteneurs isolés dans un cluster Kubernetes.

- **La Solution Keycloak (OIDC & JWT) :** Keycloak sert de traducteur. Les applications web front-end ou les microservices communiquent avec Keycloak via Internet (HTTPS) en utilisant des standards modernes comme OpenID Connect (OIDC) ou OAuth 2.0. Keycloak vérifie l'identité auprès de l'AD, puis délivre un Token JWT (un jeton cryptographique léger) à l'application.

### Limite 2 : LDAP n'est pas conçu pour le SSO Web
- LDAP est excellent pour lire un annuaire, mais lourd si chaque application s'en sert pour vérifier un mot de passe de son côté.

- **Le Problème (L'enfer des mots de passe) :** Dans une stack DevSecOps (GitLab, Grafana, ArgoCD...), si chaque outil est branché directement en LDAP à l'AD, l'utilisateur doit retaper ses identifiants à chaque ouverture de page. L'AD subit alors une charge de requêtes énorme.

- **La Solution Keycloak (SSO via Redirection) :** Keycloak s'intercale en tant que fournisseur d'identité central (IdP). L'utilisateur se connecte une seule fois sur la page de Keycloak. Ensuite, c'est Keycloak qui distribue les accès (Tokens) à GitLab, Grafana ou ArgoCD sans que l'utilisateur n'ait à se reconnecter.

### Limite 3 : L'AD est rigide face aux utilisateurs externes
- L'AD est la base de données interne de l'entreprise (les employés).

- **Le Problème :** Si l'on développe une plateforme externe (comme l'application AgroTrace) destinée à des clients ou des agriculteurs, on ne va pas créer un compte "Employé" dans l'Active Directory de l'entreprise pour chaque client. De même, intégrer du MFA (Multi-Factor Authentication) pour des prestataires externes est complexe sur un vieil AD.

- **La Solution Keycloak (Fédération et Identity Brokering) :** Keycloak permet de mixer les sources. Il peut :

  - Lire l'AD interne pour authentifier les employés.

  - Utiliser sa propre base de données pour stocker les comptes des clients de la plateforme.

  - Permettre à des prestataires de se connecter via leur compte GitHub ou Google (Social Login).

  - Ajouter nativement du MFA (Google Authenticator, YubiKey) pour tout le monde, sans toucher à la configuration de l'AD.

# Debut du POC
## 0- Mise en place d'un environement
> Voire `docker-compose.yaml`
- configurer `samba` (Active directory domain controller)
- configurer `keyclock`
## 1- Peuplement de l'AD
```bash
# en wsl
./init-samba-data.sh
```
## 2- Configuration & synchronisation entre Keycloak et Samba
### 2-1 Creation de Realm
> Bonne pratique de creer un realm pour isoler comme on le souhaite

![alt text](<screenshots/Screenshot 2026-06-03 112531.png>)
### 2-2 Configurer l'acces a l'AD
> User federation permet d'ajouter AD comme source de donnees externe.

`User federation > Add LDAP provider`
![alt text](<screenshots/Screenshot 2026-06-04 095708.png>)
![alt text](<screenshots/Screenshot 2026-06-03 094837.png>)
![alt text](<screenshots/Screenshot 2026-06-03 094902.png>)

### 2-3 Creation des Mappers 
> Un mapper est un traducteur entre 2 systemes de base de donnees (entre l'AD et Keycloak)

> l'AD et keycloak utilisent des noms differents pour les memes concepts

> On creee un group mapper pour pouvoir importer les groups des utilisateurs depuis l'AD
```
Name : groups mapper
Mapper type : group-ldap-mapper
LDAP Groups DN : OU=lab-groups,DC=corp,DC=localdomain
Group Name LDAP Attribute : cn
Group Object Classes : group
Preserve Group Inheritance : Off
Ignore Missing Groups : Off
Membership LDAP Attribute : member
Membership Attribute Type : DN
Membership User LDAP Attribute : sAMAccountName
Mode : READ_ONLY
User Groups Retrieve Strategy : LOAD_GROUPS_BY_MEMBER_ATTRIBUTE
```
Maintenant on force la synchronisation : en haut a droite de la page de ce mapper Action -> Sync LDAP groups to Keycloak

Puis verifier dans l'onglet Groups

## 3- Authentification et Autorisations des utilisateurs 
## Sonarqube
Dans cette architecture, Keycloak sert de passerelle (Identity Provider) :
- Redirection (SAML Request) : L'utilisateur tente de se connecter ; SonarQube le redirige vers Keycloak.
- Authentification (LDAP Bind) : Keycloak valide les identifiants saisis en interrogeant directement Samba AD.
- Collecte des attributs : Keycloak lit les groupes AD de l'utilisateur (ex: Admins_DevSecOps).
- Jeton Signé (SAML Response) : Keycloak crée un jeton cryptographique contenant l'identité et les groupes, puis renvoie l'utilisateur vers SonarQube.
- Vérification de sécurité : SonarQube valide la signature du jeton grâce au certificat public de Keycloak.
- Création à la volée (JIT) : Si c'est sa première connexion, SonarQube crée le profil de l'utilisateur instantanément.
- Autorisation (RBAC) : SonarQube fait correspondre les groupes du jeton avec ses groupes locaux et applique les droits finaux.

> Documentation : https://docs.sonarsource.com/sonarqube-community-build/instance-administration/authentication/saml/how-to-set-up-keycloak

### Dans Keycloak
> Avant tout on crée les groups (meme nom exact que les grps dans l'AD) et on leur attribue les droits, l'ajout des users dans leurs groups se fait automatiquement
#### 1- creer un client SAML 
> SAML car sonarqube le support
```
Client ID : sonarqube
Valid redirect URIs : http://localhost:9000/oauth2/callback/saml
```
#### 2- creer des Mappers pour ce client
Clients -> sonarqube -> Client scopes -> sonarqube-dedicated -> Add mapper
On creee 3 mappers 
```
# Mapper 1 
Mapper type : User Property
Name : name
Property : Username
SAML Attribute Name : name

# Mapper 2
Mapper type : User Property
Name : login
Property : Username
SAML Attribute Name : login

# Mapper 3
Mapper type : Group list
Name : Groups
Group attribute name : groups
Single Group Attribute : On
Full group path : Off
```
### Dans Sonarqube

Administration > Configuration > General Settings > Authentication > SAML > Create Configuration

```
Application ID : sonarqube

Provider name : SAML

# The value of the EntityDescriptor > entityID attribute in the IdP metadata file. 
# This can be found in Keycloak in Your realm > Realm settings > General > SAML 2.0 Identity Provider Metadata
Provider ID : http://localhost:8081/realms/POC   

# The value of SingleSignOnService > Location attribute in the IdP metadata file. 
# This can be found in Keycloak in Your realm > Realm settings > General > SAML 2.0 Identity Provider Metadata.
SAML login URL : http://localhost:8081/realms/POC/protocol/saml

# Copy-paste the realm’s certificate. It can be found in Keycloak:
# In Your realm > Realm settings > General > SAML 2.0 Identity Provider Metadata.
# or in Your realm > Realm Settings > Keys > RS256 and select Certificate
Identity provider certificate : 

SAML user login attribute : login

SAML user name attribute : name

SAML user email attribute : email

SAML group attribute : groups

Sign requests : off
```

## Grafana
> Avant tout on crée les groups (meme nom exact que les grps dans l'AD) et on leur attribue les droits, l'ajout des users dans leurs groups se fait automatiquement

### Dans Keycloak
#### 1- Creer un client OpenID
```
Client ID : grafana-oauth

# Optionnel, pour avoir le lien de Grafana dans keycloak
Home URL : http://localhost:3000
Valid redirect URIs : http://localhost:3000/login/generic_oauth
Client authentication : On
Authorization : On
Authentication flow : Standard flow / Direct access grants
```
#### 2- Creer un mapper
```
Mapper type : Group Membership
Token Claim Name : groups
Full group path : Off
Add to ID token : On
Add to access token : On
Add to userinfo : On
```
### Dans Grafana
Administration > Authentication > Generic OAuth
```
Client ID : grafana-oauth
Client secret : (get it from keycloak, go to the grafana client details)
Scopes : openid - offline_access - roles - profile - email
Auth URL : http://localhost:8081/realms/POC/protocol/openid-connect/auth
Token URL : http://keycloak:8080/realms/POC/protocol/openid-connect/token
API URL : http://keycloak:8080/realms/POC/protocol/openid-connect/userinfo
Allow sign up : on

# En dessous de User mapping
Role attribute path : contains(groups[*], 'Admins_DevSecOps') && 'Admin' || contains(groups[*], 'Devs') && 'Editor' || 'Viewer'
```