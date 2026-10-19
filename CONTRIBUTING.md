# Contribuer à PROJECT AEGIS-FLUX & FLUTTERCRAFT GENUI

Merci de contribuer. Ce dépôt est sous licence **AGPLv3**.  
En soumettant une contribution, vous acceptez que votre contribution soit distribuée sous la même licence AGPLv3.

## 1. Accès Collaborateur gratuit

Le business plan prévoit un **Accès Collaborateur à 0 €** pour les étudiants et chercheurs qui soumettent une **Pull Request validée et mergée**.

Conditions cumulatives :

- La PR est mergée dans `main`.
- La PR corrige un problème réel ou ajoute une fonctionnalité utile, testée et documentée.
- Chaque commit contient un sign-off DCO : `git commit -s`.
- La PR respecte [SECURITY.md](SECURITY.md).
- La PR ne contient aucun secret, clé API, token, donnée personnelle ou exploit public.
- Un mainteneur ajoute ensuite le compte GitHub à la liste d'accès Collaborateur.
- L'accès est nominatif, non transférable, et peut être révoqué en cas d'abus.
- Aucun document d'identité n'est demandé. L'affiliation étudiant/chercheur est déclarative.

## 2. DCO — Developer Certificate of Origin

Nous n'utilisons **pas de CLA payant**. Nous utilisons le **DCO 1.1**.

Chaque commit doit être signé :

```bash
git commit -s -m "fix: correction du parseur MCP"
```

Le sign-off ajoute automatiquement à la fin du message de commit :

```text
Signed-off-by: Prénom Nom <email@exemple.com>
```

En signant, vous certifiez que vous avez le droit de soumettre la contribution sous AGPLv3.

## 3. Processus de Pull Request

1. Ouvrir une issue ou choisir une issue existante.
2. Créer une branche : `feat/...`, `fix/...`, `docs/...`, `security/...`.
3. Écrire des commits clairs et signés.
4. Ajouter ou mettre à jour les tests et la documentation.
5. Ouvrir la PR avec le template fourni.
6. Attendre la revue d'un mainteneur.

## 4. Règles techniques minimales

- Flutter : `flutter analyze` et `flutter test` doivent passer.
- Rust : `cargo fmt --check`, `cargo clippy -- -D warnings`, `cargo test` doivent passer.
- Aucun secret dans le dépôt.
- Pas de dépendance payante ou propriétaire obligatoire.
- Les appels LLM passent par le backend Rust, jamais directement depuis Flutter avec une clé exposée.
- Les scans AEGIS-FLUX ne doivent être lancés que sur des cibles autorisées.

## 5. Sécurité

Ne jamais ouvrir d'issue publique pour une faille.  
Lire [SECURITY.md](SECURITY.md) et utiliser le canal privé GitHub Security Advisories.

## 6. Code de conduite

- Pas d'insulte, de harcèlement, de doxxing.
- Pas de demande de scan contre une cible sans autorisation écrite.
- Pas de publication d'exploit avant correction.

## 7. Licence

Toute contribution est sous **AGPLv3**.  
Le code est ouvert ; **le service hébergé officiel (backend Rust, clé Groq, infra AEGIS-FLUX, marque) reste opéré exclusivement par le mainteneur**.  
Aucune contribution ne peut être intégrée si elle impose une licence incompatible.
