# Contrat API — Flutter ↔ Rust ↔ Groq ↔ Workers MCP

Version : 0.1.0 — Octobre 2026  
Statut : figé pour implémentation. Toute modification passe par une PR sur ce fichier.

## 0. Règles générales

- **Base URL** : définie par la variable d'environnement `API_BASE_URL` côté Flutter. Aucune URL en dur.
- **Transport** : HTTPS uniquement en production, HTTP local en développement.
- **Format** : JSON UTF-8, `Content-Type: application/json`.
- **Auth** : `Authorization: Bearer <token>` sur toutes les routes `/v1/*` sauf `/health`.
- **Clé Groq** : jamais exposée à Flutter. Seul le backend Rust la détient via variable d'environnement `GROQ_API_KEY`.
- **Asynchrone** : les scans et générations sont des jobs. Le client reçoit un `job_id` puis fait du polling.

## 1. Enveloppe d'erreur unique

Toute réponse d'erreur (HTTP 4xx/5xx) respecte ce format :

```json
{
  "error": {
    "code": "INSUFFICIENT_CREDITS",
    "message": "Quota journalier atteint.",
    "retry_after": 3600
  }
}
```

Codes normalisés :

| Code | HTTP | Sens |
|---|---|---|
| `UNAUTHORIZED` | 401 | Token absent ou invalide |
| `FORBIDDEN` | 403 | Tier insuffisant pour cette action |
| `INSUFFICIENT_CREDITS` | 402 | Quota journalier épuisé (Standard) |
| `INVALID_TARGET` | 400 | Cible de scan invalide |
| `MISSING_AUTHORIZATION` | 400 | Champ `authorization` absent ou vide |
| `JOB_NOT_FOUND` | 404 | `job_id` inconnu ou expiré |
| `RATE_LIMITED` | 429 | Trop de requêtes par minute |
| `INTERNAL` | 500 | Erreur serveur, à signaler |

## 2. Endpoints REST

### 2.1 `GET /health`

Public, sans auth. Utilisé par Render pour le healthcheck.

**200 :**
```json
{ "status": "ok", "version": "0.1.0", "timestamp": "2026-10-19T12:00:00Z" }
```

### 2.2 `GET /v1/me`

Renvoie l'identité et le quota de l'utilisateur authentifié. Appelé au démarrage de Flutter.

**200 :**
```json
{
  "user_id": "gh:12345678",
  "tier": "standard",
  "credits_remaining": 5,
  "credits_reset_at": "2026-10-20T00:00:00Z"
}
```

`tier` ∈ `standard` | `premium` | `collaborator`.  
`credits_remaining` = `null` pour `premium` et `collaborator` (illimité).

### 2.3 `POST /v1/aegis/scan`

Soumet un scan AEGIS-FLUX. **Consomme 1 crédit** (sauf premium/collaborator).

**Requête :**
```json
{
  "target": "example.com",
  "authorization": "Je certifie être propriétaire ou disposer d'une autorisation écrite.",
  "scanners": ["nmap", "nuclei"],
  "repo_url": null
}
```

- `target` : domaine, IP ou URL. Rejeté si vide, localhost, ou IP privée (RFC1918) en production.
- `authorization` : obligatoire, non vide. Journalisé.
- `scanners` : sous-ensemble de `["nmap","nuclei","gitleaks"]`. `gitleaks` exige `repo_url`.
- `repo_url` : requis uniquement si `gitleaks` est demandé.

**202 :**
```json
{ "job_id": "a1b2c3d4-...", "status": "queued", "estimated_seconds": 180 }
```

### 2.4 `GET /v1/aegis/scan/{job_id}`

Polling toutes les 3 secondes côté Flutter.

**200 (en cours) :**
```json
{ "job_id": "a1b2c3d4-...", "status": "running", "progress": 45, "report_markdown": null, "error": null }
```

**200 (terminé) :**
```json
{ "job_id": "a1b2c3d4-...", "status": "done", "progress": 100, "report_markdown": "# Rapport AEGIS-FLUX\n...", "error": null }
```

`status` ∈ `queued` | `running` | `done` | `failed`.  
`report_markdown` : rempli uniquement si `status == "done"`, format HackerOne.

### 2.5 `POST /v1/fluttercraft/generate`

Soumet une génération FLUTTERCRAFT GENUI. **Consomme 1 crédit** (sauf premium/collaborator).

**Requête :**
```json
{
  "prompt": "Écran de login avec validation email et bouton vert fluo.",
  "mode": "scaffold",
  "context": null
}
```

- `mode` ∈ `scaffold` (nouveau code) | `patch` (correction d'un fichier existant).
- `context` : contenu Dart à patcher, requis si `mode == "patch"`.

**202 :**
```json
{ "job_id": "e5f6g7h8-...", "status": "queued", "estimated_seconds": 20 }
```

### 2.6 `GET /v1/fluttercraft/generate/{job_id}`

**200 (terminé) :**
```json
{
  "job_id": "e5f6g7h8-...",
  "status": "done",
  "code_dart": "import 'package:flutter/material.dart';\n...",
  "tokens_used": 1840,
  "error": null
}
```

## 3. Contrat MCP interne (Rust ↔ Workers Docker)

Ce contrat n'est **jamais** exposé à Flutter. Il relie le backend Rust aux conteneurs Docker qui exécutent Nmap, Nuclei et Gitleaks.

- **Transport** : JSON-RPC 2.0, une ligne JSON par message, sur stdin/stdout du conteneur.
- **Protocole** : Model Context Protocol (MCP), version stable.

**Appel d'outil (Rust → Worker) :**
```json
{"jsonrpc":"2.0","id":"1","method":"tools/call","params":{"name":"nmap_scan","arguments":{"target":"example.com","flags":"-sV -T3"}}}
```

**Réponse (Worker → Rust) :**
```json
{"jsonrpc":"2.0","id":"1","result":{"content":[{"type":"text","text":"<sortie nmap brute>"}]}}
```

**Erreur (Worker → Rust) :**
```json
{"jsonrpc":"2.0","id":"1","error":{"code":-32000,"message":"Target non autorisée"}}
```

Noms d'outils réservés :

| Outil | Arguments | Sortie attendue |
|---|---|---|
| `nmap_scan` | `target`, `flags` | texte brut nmap |
| `nuclei_scan` | `target`, `templates` | JSONL nuclei |
| `gitleaks_scan` | `repo_url` | JSON gitleaks |

**Règle de sécurité :** le worker rejette toute cible non conforme à `target_policy` (pas de localhost, pas d'IP privée, pas de `.internal`). Le rejet se fait **dans le worker**, pas seulement côté Rust.

## 4. Flux Groq (Rust ↔ Groq API)

- Appel direct HTTP depuis Rust vers `https://api.groq.com/openai/v1/chat/completions`.
- Clé lue depuis `GROQ_API_KEY`, jamais loggée, jamais renvoyée au client.
- Le prompt système et le modèle sont définis côté Rust, pas côté Flutter.
- En cas d'échec Groq : le job passe en `failed` avec `error.code = "INTERNAL"` et le crédit **n'est pas consommé**.

## 5. Règles de consommation de crédits

- 1 job (`scan` ou `generate`) = 1 crédit, prélevé **à la soumission**.
- Si le job échoue avant exécution (validation, auth), le crédit est **remboursé**.
- Si le job échoue pendant l'exécution, le crédit est **remboursé**.
- `premium` et `collaborator` : pas de décompte, `credits_remaining = null`.
- Reset quotidien à `00:00 UTC`.

## 6. Hors périmètre de ce contrat (v0.2+)

- Paiement (Stripe/MetaMask on-chain) : contrat séparé.
- Streaming SSE des générations : contrat séparé.
- Webhooks HackerOne : contrat séparé.