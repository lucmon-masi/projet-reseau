# Analyse critique — Mastodon comme outil de tutorat à l'HELHa

## Ce que Mastodon fait bien

### Points positifs
- **Familiarité** : interface proche des réseaux sociaux connus (Twitter/X) → adoption rapide
- **Posts publics/privés** : un tuteur peut partager des ressources en public et des retours en privé
- **Mentions et threads** : permet des échanges contextualisés autour d'un post
- **Administration centralisée** : rôles admin/modérateur/utilisateur bien séparés
- **Open source et auto-hébergé** : données sous contrôle de l'institution, pas de dépendance cloud
- **Custom fields** : les tuteurs peuvent afficher leur matière et disponibilités sur leur profil

## Ce que Mastodon fait mal pour le tutorat

### Manques structurels
| Besoin tutorat | Mastodon | Alternative adaptée |
|----------------|----------|---------------------|
| Forum par matière | ❌ (pas de canaux/groupes) | Discourse, Moodle Forum |
| Suivi de progression | ❌ | Moodle, Google Classroom |
| Partage de fichiers | ❌ (images/vidéos seulement) | Nextcloud, Moodle |
| Planification de sessions | ❌ | Calendrier intégré absent |
| Quiz / exercices | ❌ | H5P, Moodle Quiz |
| Notifications structurées | ⚠️ (par personne, pas par sujet) | Forum avec catégories |

### Problèmes pratiques
- **Découvrabilité** : on suit des *personnes*, pas des *matières* — difficile de trouver les ressources sur un sujet donné
- **Fil chronologique** : les posts importants se noient rapidement, pas d'épinglage global
- **Pas de groupes** : impossible de créer un espace "Mathématiques - L1" séparé d'un espace "Informatique - L2"
- **Courbe d'apprentissage** : le concept de "federated timeline" et de visibilité est peu intuitif pour des étudiants

## Conclusion

Mastodon est un **réseau social fédéré**, pas un **LMS** (Learning Management System).  
Il peut servir de **couche sociale complémentaire** — espace d'échange informel entre étudiants et tuteurs — mais ne remplace pas un outil dédié au tutorat.

### Ce projet démontre

1. **La faisabilité technique** d'une intégration SSO (LDAP + Keycloak + Mastodon) dans un environnement académique
2. **La valeur de l'authentification centralisée** : un compte unique, des rôles gérés par l'institution
3. **Les limites de Mastodon** pour un usage pédagogique structuré

### Recommandation

Pour un tutorat efficace à l'HELHa :
- **Mastodon** → espace social, annonces informelles, échanges rapides
- **Moodle** (déjà utilisé) → devoirs, quiz, ressources structurées, suivi
- **SSO unifié** (Keycloak) → un seul login pour les deux plateformes

L'architecture LDAP + Keycloak développée dans ce projet est **réutilisable** et pourrait connecter n'importe quelle application compatible OIDC (Moodle, Nextcloud, Gitea...) avec le même annuaire d'utilisateurs.
