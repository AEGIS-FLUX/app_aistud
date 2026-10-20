# Sécurité

## Versions supportées

Le projet est en développement actif. Seule la branche `main` est supportée.

## Signaler une vulnérabilité

**Ne pas ouvrir d'issue publique.**

Utiliser GitHub Security Advisories :

1. Aller dans l'onglet **Security** du dépôt.
2. Cliquer sur **Report a vulnerability**.
3. Décrire la faille, l'impact, les étapes de reproduction et une correction suggérée si possible.

## Engagement

- Accusé de réception sous 72 h ouvrées.
- Analyse et réponse sous 7 jours ouvrés.
- Divulgation coordonnée après correction.
- Pas de récompense financière garantie : le projet fonctionne à budget zéro.
- Safe harbor pour les recherches de bonne foi, dans le cadre autorisé.

## Règles pour AEGIS-FLUX

- Ne scanner que des cibles dont vous êtes propriétaire ou pour lesquelles vous avez une autorisation écrite.
- Ne pas publier de rapport contenant des données sensibles.
- Ne pas utiliser le projet pour attaquer, surcharger ou extorquer un tiers.
- Les scans Docker doivent rester isolés et limités aux cibles autorisées.

## Secrets

Aucune clé Groq, token GitHub, clé MetaMask ou secret de production ne doit être commité.
Utiliser les variables d'environnement et les secrets GitHub/Render.
