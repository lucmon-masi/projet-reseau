# Custom Fields Mastodon — Profils tuteurs

## Qu'est-ce que c'est ?

Les "champs de profil" (metadata fields) sont des paires clé/valeur affichées sur le profil Mastodon.  
Natif dans Mastodon, configurable par chaque utilisateur dans ses paramètres.

## Configuration par l'utilisateur

Chaque utilisateur peut ajouter jusqu'à **4 champs** dans :  
`Préférences → Profil → Champs supplémentaires du profil`

### Champs recommandés pour les tuteurs

| Libellé | Exemple de valeur |
|---------|-------------------|
| Matière(s) | Mathématiques, Physique |
| Disponibilités | Lun-Mer 14h-16h |
| Promotion | L1 Sciences |
| Contact | alice@henallux.be |

## Vérification du logout global

### Comment tester

1. Se connecter avec `lucmon` (teacher/admin)
2. Ouvrir un onglet privé → se connecter avec `alice` (student)  
3. Sur l'onglet lucmon → cliquer "Déconnexion" dans Mastodon
4. Aller sur `https://keycloak.reseau.local:8443` → vérifier que la session lucmon est bien terminée
5. Cliquer "Keycloak SSO" depuis Mastodon → Keycloak doit demander les credentials (pas de session active)

### Ce qui se passe en coulisses

```
Mastodon logout
    → OidcSingleLogout#destroy capture session[:oidc_id_token]
    → after_sign_out_path_for redirige vers :
      https://keycloak.reseau.local:8443/realms/reseau/protocol/openid-connect/logout
        ?id_token_hint=<JWT>&post_logout_redirect_uri=https://mastodon.reseau.local:8443/
    → Keycloak invalide la session côté serveur
    → Redirection vers Mastodon (page d'accueil, déconnecté)
```

### Fallback sans id_token

Si `session[:oidc_id_token]` est absent (expiration de session), le logout utilise `client_id=mastodon` à la place, ce qui est accepté par Keycloak comme alternative valide.
