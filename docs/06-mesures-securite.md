# Mesures de sécurité

## 1. Transport — HTTPS self-signed

Toutes les communications passent par HTTPS via Nginx (port 8443).  
Un CA auto-signé (`ca.crt`) est généré localement et injecté dans :
- le conteneur Mastodon (`update-ca-certificates`) pour qu'il fasse confiance à Keycloak
- le poste client (à importer manuellement dans le navigateur)

**Pourquoi** : empêche l'interception des tokens OIDC et des cookies de session en clair.

## 2. Authentification centralisée — Keycloak + LDAP

```
Navigateur → Keycloak (OIDC) → OpenLDAP (vérification credentials)
                ↓
           Token JWT signé
                ↓
          Mastodon (vérifie le token)
```

- Les mots de passe ne transitent **jamais** vers Mastodon
- Mastodon ne stocke pas de credentials — uniquement le `sub` (UUID Keycloak)
- `OIDC_PROMPT=login` : force la re-saisie des credentials à chaque connexion SSO

## 3. Mapping de rôles — moindre privilège

| LDAP group | Keycloak role | Mastodon role |
|------------|---------------|---------------|
| `teacher`  | `teacher`     | Admin         |
| `tutor`    | `tutor`       | Moderator     |
| `student`  | `student`     | User          |

Les rôles sont synchronisés automatiquement à chaque login via l'OmniAuth callback.  
Un étudiant ne peut jamais obtenir les droits moderator/admin sans changement dans LDAP.

## 4. Isolation réseau Docker

Tous les conteneurs sont sur un réseau privé `172.33.0.0/16` sans accès Internet.  
Seul Nginx expose des ports vers l'hôte (8080, 8443).

```
Internet → Nginx (8443) → Mastodon / Keycloak
                         ↑ réseau interne uniquement
OpenLDAP ←→ Keycloak
```

- OpenLDAP n'est **pas** accessible depuis l'extérieur
- Keycloak n'est accessible qu'en interne sauf via le proxy Nginx

## 5. Pas d'email — confirmation désactivée

`disable_mailer.rb` neutralise l'envoi d'emails.  
`OIDC_SECURITY_ASSUME_EMAIL_IS_VERIFIED=true` : Mastodon fait confiance à Keycloak pour la vérification d'email.

**Pourquoi** : dans un contexte intranet/formation, l'envoi d'email n'est pas nécessaire et évite une surface d'attaque SMTP.

## 6. Single Logout (SLO)

Le logout Mastodon appelle l'endpoint Keycloak `end_session` avec `id_token_hint` :

```
GET /realms/reseau/protocol/openid-connect/logout
    ?id_token_hint=<JWT>
    &post_logout_redirect_uri=https://mastodon.reseau.local:8443/
```

Cela invalide la session Keycloak côté serveur — une simple suppression de cookie côté client ne suffirait pas.

## 7. Volumes persistants

- `openldap_data` / `openldap_config` : les utilisateurs LDAP survivent aux redémarrages
- `keycloak_data` : les UUIDs Keycloak restent stables → pas de conflit d'identité Mastodon

## Limites connues

- CA auto-signé : non reconnu par les navigateurs sans import manuel
- Keycloak en mode `start-dev` avec H2 (base de données embarquée) — **ne pas utiliser en production**
- Pas de rate-limiting sur les tentatives de connexion
- Secrets en clair dans `.env.production` (acceptable pour un lab, pas pour la prod)
