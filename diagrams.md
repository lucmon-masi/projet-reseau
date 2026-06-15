# Diagrammes — Projet Réseau (LDAP + Keycloak + Mastodon)

---

## 1. Stack technologique

```mermaid
graph TB
    subgraph Client["🖥️ Client (navigateur)"]
        Browser["Firefox / Chrome<br/>HTTPS :8443"]
    end

    subgraph Docker["🐳 Docker Compose — réseau 172.33.0.0/16"]
        Nginx["Nginx :8443<br/>Reverse proxy TLS<br/>172.33.0.10"]

        subgraph IAM["Gestion des identités"]
            LDAP["OpenLDAP :389<br/>osixia/openldap:1.5.0<br/>172.33.0.2<br/>─────────────<br/>ou=people (users)<br/>ou=groups (roles)"]
            KC["Keycloak 24.0.5<br/>quay.io/keycloak:24.0.5<br/>172.33.0.3<br/>─────────────<br/>Realm: reseau<br/>Client OIDC: mastodon<br/>LDAP Federation"]
        end

        subgraph Mastodon["Mastodon 4.3.3"]
            Web["mastodon_web :3000<br/>Rails / Puma<br/>172.33.0.6"]
            Sidekiq["mastodon_sidekiq<br/>Jobs asynchrones<br/>172.33.0.7"]
            Streaming["mastodon_streaming :4000<br/>Node.js WebSocket<br/>172.33.0.8"]
        end

        subgraph Data["Persistance"]
            PG["PostgreSQL 16<br/>172.33.0.4"]
            Redis["Redis 7<br/>172.33.0.5"]
            KCVol[("keycloak_data<br/>H2 Database")]
        end
    end

    Browser -->|"HTTPS"| Nginx
    Nginx -->|"mastodon.reseau.local"| Web
    Nginx -->|"keycloak.reseau.local"| KC
    Nginx -->|"/api/v1/streaming"| Streaming
    KC -->|"LDAP :389"| LDAP
    Web --> PG
    Web --> Redis
    Sidekiq --> PG
    Sidekiq --> Redis
    KC --- KCVol
```

---

## 2. Use Case

```mermaid
flowchart LR
    A["👤 Acteur LDAP<br/>(alice / bob / charlie)"]

    subgraph UC["Cas d'utilisation"]
        U1["Se connecter<br/>via SSO Keycloak"]
        U2["Naviguer sur Mastodon<br/>(rôle automatique)"]
        U3["Publier un statut"]
        U4["Modérer du contenu"]
        U5["Administrer Mastodon"]
        U6["Se déconnecter<br/>(Single Logout)"]
        U7["Créer un utilisateur<br/>(admin LDAP)"]
    end

    subgraph Roles["Rôles Mastodon"]
        R1["👨‍🎓 student → User"]
        R2["👨‍🏫 tutor → Modérateur"]
        R3["🧑‍💼 teacher → Admin"]
    end

    A --> U1
    U1 --> U2
    U2 --> U3
    U2 --> U6

    R1 --> U3
    R2 --> U3
    R2 --> U4
    R3 --> U3
    R3 --> U4
    R3 --> U5

    U7 -->|"python3 create-user.py"| A
```

---

## 3. Séquence — Connexion SSO

```mermaid
sequenceDiagram
    actor User as Utilisateur
    participant Browser as Navigateur
    participant Nginx as Nginx :8443
    participant Mastodon as Mastodon (Rails)
    participant Keycloak as Keycloak
    participant LDAP as OpenLDAP

    User->>Browser: Ouvre mastodon.reseau.local:8443
    Browser->>Nginx: GET / (HTTPS)
    Nginx->>Mastodon: GET / (HTTP interne)
    Mastodon-->>Browser: Page login + bouton "Se connecter avec Keycloak"

    User->>Browser: Clique "Se connecter avec Keycloak"
    Browser->>Nginx: GET /auth/auth/openid_connect
    Nginx->>Mastodon: GET /auth/auth/openid_connect
    Mastodon-->>Browser: Redirect → Keycloak /auth (code OIDC)

    Browser->>Nginx: GET keycloak.reseau.local:8443/realms/reseau/...
    Nginx->>Keycloak: GET /realms/reseau/protocol/openid-connect/auth
    Keycloak-->>Browser: Page login Keycloak

    User->>Browser: Saisit uid + password
    Browser->>Nginx: POST /realms/reseau/protocol/openid-connect/auth
    Nginx->>Keycloak: POST credentials

    Keycloak->>LDAP: Bind + Search uid=alice
    LDAP-->>Keycloak: Entrée inetOrgPerson
    Keycloak->>LDAP: Search memberUid=alice in ou=groups
    LDAP-->>Keycloak: cn=teacher (groupe)

    Keycloak-->>Browser: Redirect → Mastodon /auth/callback?code=...

    Browser->>Nginx: GET /auth/auth/openid_connect/callback?code=...
    Nginx->>Mastodon: GET /auth/auth/openid_connect/callback

    Mastodon->>Nginx: POST keycloak.reseau.local:8443 /token
    Nginx->>Keycloak: POST /token (échange code → tokens)
    Keycloak-->>Mastodon: access_token + id_token + roles=["teacher"]

    Note over Mastodon: OidcRoleSync#openid_connect<br/>Sauvegarde id_token en session<br/>Mappe teacher → Admin (role_id)
    Mastodon->>Mastodon: user.update_column(:role_id, Admin.id)

    Mastodon-->>Browser: Session Mastodon créée, redirect /
    Browser-->>User: Interface Mastodon (badge Admin)
```

---

## 4. Séquence — Déconnexion (Single Logout)

```mermaid
sequenceDiagram
    actor User as Utilisateur
    participant Browser as Navigateur
    participant Nginx as Nginx :8443
    participant Mastodon as Mastodon (Rails)
    participant Keycloak as Keycloak

    User->>Browser: Clique "Se déconnecter"
    Browser->>Nginx: DELETE /auth/sign_out
    Nginx->>Mastodon: DELETE /auth/sign_out

    Note over Mastodon: OidcSingleLogout#destroy<br/>Récupère id_token depuis session<br/>AVANT reset_session

    Mastodon->>Mastodon: @oidc_id_token = session[:oidc_id_token]
    Mastodon->>Mastodon: Devise reset_session (session vidée)
    Mastodon->>Mastodon: after_sign_out_path_for()<br/>Construit URL logout Keycloak

    Mastodon-->>Browser: Redirect → Keycloak /logout?id_token_hint=...&post_logout_redirect_uri=...

    Browser->>Nginx: GET keycloak.reseau.local:8443/realms/reseau/.../logout
    Nginx->>Keycloak: GET /logout?id_token_hint=<token>
    Keycloak->>Keycloak: Invalide session SSO
    Keycloak-->>Browser: Redirect → mastodon.reseau.local:8443/

    Browser-->>User: Page d'accueil Mastodon (déconnecté)
```

---

## 5. Mapping des rôles LDAP → Keycloak → Mastodon

```mermaid
flowchart LR
    subgraph LDAP["OpenLDAP"]
        G1["cn=teacher<br/>posixGroup<br/>memberUid: alice"]
        G2["cn=tutor<br/>posixGroup<br/>memberUid: bob"]
        G3["cn=student<br/>posixGroup<br/>memberUid: charlie, diana"]
    end

    subgraph KC["Keycloak — Realm reseau"]
        R1["Realm Role: teacher"]
        R2["Realm Role: tutor"]
        R3["Realm Role: student"]
        TK["id_token / access_token<br/>claim: roles=[teacher]"]
    end

    subgraph Mastodon["Mastodon"]
        M1["UserRole: Admin"]
        M2["UserRole: Moderator"]
        M3["UserRole: User"]
        CB["OidcRoleSync<br/>(initializer Ruby)"]
    end

    G1 -->|"role-ldap-mapper"| R1
    G2 -->|"role-ldap-mapper"| R2
    G3 -->|"role-ldap-mapper"| R3

    R1 -->|"protocol mapper<br/>oidc-usermodel-realm-role"| TK
    R2 --> TK
    R3 --> TK

    TK -->|"auth.extra.raw_info['roles']"| CB
    CB -->|"teacher"| M1
    CB -->|"tutor"| M2
    CB -->|"student"| M3
```

---

## 6. Architecture réseau Docker

```mermaid
graph TB
    Host["🖥️ Machine hôte<br/>127.0.0.1"]

    subgraph Net["Réseau Docker bridge — 172.33.0.0/16"]
        direction TB
        N["nginx<br/>172.33.0.10<br/>:8443"]
        KC["keycloak<br/>172.33.0.3<br/>:8080"]
        LDAP["openldap<br/>172.33.0.2<br/>:389"]
        WEB["mastodon_web<br/>172.33.0.6<br/>:3000"]
        SID["mastodon_sidekiq<br/>172.33.0.7"]
        STR["mastodon_streaming<br/>172.33.0.8<br/>:4000"]
        DB["mastodon_db<br/>172.33.0.4<br/>:5432"]
        RED["mastodon_redis<br/>172.33.0.5<br/>:6379"]
    end

    Host -->|"port 8443"| N
    Host -->|"port 9080 (admin)"| KC
    N --> WEB
    N --> KC
    N --> STR
    KC --> LDAP
    WEB --> DB
    WEB --> RED
    SID --> DB
    SID --> RED
    WEB -->|"OIDC token exchange<br/>via extra_hosts"| N
```

---

## 7. Flux de création d'un utilisateur

```mermaid
flowchart TD
    A["Admin lance<br/>python3 scripts/create-user.py"] --> B["Saisit prénom, nom,<br/>email, password, rôle"]
    B --> C["Génère uid<br/>3 lettres prénom + 3 lettres nom<br/>ex: lucmon"]
    C --> D["ldapadd → uid=lucmon,ou=people"]
    D --> E["ldapmodify → ajoute memberUid<br/>dans cn=teacher/tutor/student"]
    E --> F["make sync-ldap<br/>→ Keycloak REST API"]
    F --> G["Keycloak importe l'user<br/>depuis LDAP"]
    G --> H["✓ L'utilisateur peut se connecter<br/>sur Mastodon via SSO"]
```
