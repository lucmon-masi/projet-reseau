# Visibilité des posts Mastodon — cas d'usage tutorat

## Niveaux de visibilité natifs

| Niveau | Icône | Qui peut voir | Cas d'usage tutorat |
|--------|-------|---------------|---------------------|
| **Public** | 🌐 | Tout le monde (y compris non-connectés) | Annonces générales, ressources ouvertes |
| **Non-listé** *(unlisted)* | 🔓 | Tout le monde, mais absent du fil public | Questions/réponses entre membres sans polluer le fil |
| **Abonnés** *(followers-only)* | 🔒 | Uniquement les abonnés | Échanges privés entre tuteur et ses étudiants |
| **Mention** *(direct)* | ✉️ | Uniquement les personnes mentionnées | Équivalent message privé — retour individuel sur un travail |

## Recommandations par rôle

### Enseignant (Admin)
- **Public** : consignes de cours, dates importantes
- **Non-listé** : corrections générales, commentaires de classe

### Tuteur (Moderator)
- **Abonnés** : sessions de tutorat, disponibilités hebdo
- **Mention** : retour personnalisé sur le travail d'un étudiant

### Étudiant (User)
- **Abonnés** : questions au tuteur (seuls ses abonnés voient)
- **Mention** : question directe et privée au tuteur ou prof

## Workflow typique

```
Étudiant → poste une question en @mention du tuteur (direct/privé)
Tuteur   → répond en @mention (seul l'étudiant voit)
          → ou répond en "non-listé" si la réponse profite à tous
Prof     → poste en "public" les ressources de cours
```

## Limites pour le tutorat

- Pas de threads structurés (comme un forum)
- Pas de visibilité par groupe/matière nativement
- La distinction unlisted/followers-only est peu intuitive pour des débutants
- Pas de notifications "fil de discussion" : on suit une personne, pas un sujet
