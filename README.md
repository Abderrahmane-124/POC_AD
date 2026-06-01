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

- **La Solution Keycloak (Le véritable SSO) :** Keycloak s'intercale en tant que fournisseur d'identité central (IdP). L'utilisateur se connecte une seule fois sur la page de Keycloak. Ensuite, c'est Keycloak qui distribue les accès (Tokens) à GitLab, Grafana ou ArgoCD sans que l'utilisateur n'ait à se reconnecter.

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
