# Messagerie et notifications — base fonctionnelle et contrat back-end

## 1. But et périmètre

Ce document décrit la base portée par l’application mobile pour les modules **Messagerie** et **Notifications**, puis la traduit en contrat attendu du back-end. L’analyse repose sur les entités, mocks, pages et widgets Flutter existants.

À ce jour, les deux modules sont entièrement mockés : données et mutations vivent dans les `StatefulWidget` et sont perdues à la réouverture. Il n’existe encore ni source distante, repository, persistance locale, upload réel, push ni temps réel.

Le contrat cible conserve les conventions de l’API étudiante :

- `Authorization: Bearer <token>` ;
- enveloppe `{ success, message, data }` ;
- JSON en `snake_case` ;
- routes sous `/student/*.php` ;
- erreurs HTTP explicites.

Sources analysées : `features/messagerie/`, `features/notifications/`, `core/network/` et `documentation_api/openapi-etudiant.yaml`.

```text
features/<module>/
├── data/datasources/      # mocks actuels
├── domain/entities/       # objets consommés par l’UI
└── presentation/
    ├── pages/             # état et orchestration locale
    └── widgets/           # rendu spécialisé
```

## 2. Messagerie : comportement attendu par l’UI

### 2.1 Liste des discussions

L’écran attend :

- un compteur global de messages non lus ;
- une recherche sur nom, rôle/service et dernier message ;
- les vues toutes, général, diffusions, encadreurs et groupes ;
- avatar, nom, rôle/service, présence, épinglage, date, dernier message, statut du dernier envoi et compteur non lu ;
- l’ouverture d’une discussion, qui marque ses messages reçus comme lus ;
- un annuaire pour démarrer une nouvelle discussion.

Le serveur doit renvoyer un ordre stable : épinglées d’abord, puis date du dernier message décroissante.

### 2.2 Chat

L’écran prend en charge : chargement initial, pagination vers l’historique, texte, vocal, document, image, réponse citée, nom de l’expéditeur dans les groupes, statuts envoyé/distribué/lu, présence et téléchargement.

L’appel vocal est seulement un bouton UI. Autres règles :

- `est_mien` est calculé depuis l’utilisateur authentifié ;
- une réponse référence un message par ID, sans imbrication récursive complète ;
- `image` existe dans le domaine, bien que le mock caméra/galerie crée encore un `document` ;
- une diffusion expose `can_send` selon les droits.

### 2.3 Valeurs de référence

| Flutter | Valeur API |
|---|---|
| catégories `general`, `diffusion`, `encadreurs`, `groupes` | `general`, `broadcast`, `supervisor`, `group` |
| types `texte`, `vocal`, `document`, `image` | `text`, `voice`, `document`, `image` |
| statuts `envoye`, `distribue`, `lu` | `sent`, `delivered`, `read` |
| forme de discussion | `direct`, `group`, `broadcast` |
| présence | `online`, `offline`, `unknown` |

### 2.4 Objet discussion

```json
{
  "id": "disc_mwamba",
  "kind": "direct",
  "category": "supervisor",
  "title": "Dr. Patrick Mwamba",
  "subtitle": "Chirurgien Chef · Hôpital Général",
  "avatar_url": null,
  "is_pinned": true,
  "can_send": true,
  "presence": "online",
  "unread_count": 2,
  "last_message": {
    "id": "msg_01J...",
    "type": "text",
    "preview": "Bien reçu ! Bon travail pour cette garde.",
    "sent_at": "2026-09-21T09:52:00Z",
    "is_mine": false,
    "status": "read"
  }
}
```

Tous ces champs servent au rendu. `last_message` peut être `null`. Son `status` est utile surtout si `is_mine = true`.

### 2.5 Objet message

```json
{
  "id": "msg_01J...",
  "conversation_id": "disc_mwamba",
  "client_id": "01J8LOCAL...",
  "type": "document",
  "text": "Voici la fiche actualisée.",
  "sent_at": "2026-09-21T10:00:32Z",
  "sender": {
    "id": "usr_42",
    "display_name": "Alfred Masiala",
    "avatar_url": null
  },
  "is_mine": true,
  "status": "sent",
  "reply_to": {
    "id": "msg_01JPREVIOUS",
    "sender_name": "Dr. Patrick Mwamba",
    "type": "text",
    "preview": "As-tu vérifié la radio ?"
  },
  "attachment": {
    "id": "media_01J...",
    "file_name": "Fiche_Suivi.pdf",
    "mime_type": "application/pdf",
    "size_bytes": 1258291,
    "duration_seconds": null,
    "width": null,
    "height": null,
    "download_url": "https://...",
    "thumbnail_url": null
  }
}
```

Contraintes :

- `text` est requis et non vide pour `text` ;
- `attachment` est requis pour `voice`, `document`, `image` ;
- `duration_seconds` est requis pour `voice` ;
- le serveur valide `mime_type`, `size_bytes`, `file_name` ;
- le message cité appartient à la même discussion ;
- `client_id`, généré côté mobile, rend l’envoi idempotent ;
- `sent_at` est en ISO 8601 UTC.

### 2.6 Endpoints de messagerie

#### `GET /student/conversations.php`

Paramètres : `category?`, `search?`, `cursor?`, `limit?` (20 par défaut, 50 maximum).

```json
{
  "success": true,
  "message": "Discussions récupérées.",
  "data": {
    "items": [],
    "unread_messages_count": 7,
    "next_cursor": null,
    "has_more": false
  }
}
```

#### `GET /student/conversation-messages.php`

Paramètres : `conversation_id` requis, `before?`, `limit?` (30 par défaut, 100 maximum). `items` est ordonné du plus ancien au plus récent. `next_cursor` désigne le lot plus ancien suivant.

```json
{
  "success": true,
  "message": "Messages récupérés.",
  "data": {
    "conversation": {},
    "items": [],
    "next_cursor": "older_cursor",
    "has_more": true
  }
}
```

#### `POST /student/messages.php`

```json
{
  "conversation_id": "disc_mwamba",
  "client_id": "01J8LOCAL...",
  "type": "text",
  "text": "Bien noté, Docteur.",
  "reply_to_message_id": "msg_01JPREVIOUS",
  "attachment_id": null
}
```

Réponses : `201` créé ; `200` si `client_id` est déjà traité ; `403` si l’écriture est interdite ; `404` si la ressource est inaccessible ; `409` si la référence est incompatible ; `422` si le contenu est invalide.

#### `POST /student/message-attachments.php`

Upload `multipart/form-data` avant l’envoi : `file`, `conversation_id`, `kind` (`voice`, `document`, `image`, `internship_form`) et `duration_seconds` pour un vocal. La réponse `201` contient l’objet `attachment` canonique.

Les limites de taille/MIME doivent être documentées. Les URL de médias médicaux sont protégées ou signées et de courte durée.

#### `PATCH /student/conversations-read.php`

```json
{
  "conversation_id": "disc_mwamba",
  "last_read_message_id": "msg_01J..."
}
```

La réponse contient `conversation_id`, `last_read_message_id`, `unread_count`, le compteur global `unread_messages_count` et `read_at`. L’opération est idempotente et ne fait jamais reculer le pointeur de lecture.

#### Annuaire et création

- `GET /student/messaging-directory.php?search=&cursor=&limit=` : personnes autorisées, avec `user_id`, `display_name`, `role_or_service`, `avatar_url`, `existing_conversation_id?`.
- `POST /student/conversations.php` avec `{ "participant_user_id": "usr_42" }` : renvoie l’existante (`200`) ou crée la discussion (`201`).

### 2.7 Temps réel

WebSocket, SSE ou polling incrémental transitoire doit couvrir :

| Événement | Données principales |
|---|---|
| `message.created` | message complet et résumé de discussion |
| `message.delivered` | `message_id`, `delivered_at` |
| `message.read` | discussion, dernier message lu, `read_at` |
| `conversation.updated` | dernier message, compteurs, épinglage |
| `presence.updated` | utilisateur, présence, `last_seen_at` |

Chaque événement porte `event_id` et `occurred_at`. La progression est monotone : `sent → delivered → read`. Une reconnexion reprend depuis un curseur ou resynchronise les données.

## 3. Notifications : comportement attendu par l’UI

L’écran attend : compteur non lu, filtres toutes/non lues/stages/messages, sujet, description, date relative, style selon le type, action, lecture au toucher et « Tout lire ». L’ordre est `created_at` décroissant.

### 3.1 Types et actions

| Flutter | API |
|---|---|
| `stage` | `internship` |
| `journal` | `logbook` |
| `message` | `message` |
| `urgence` | `urgent` |
| `academique` | `academic` |

| `action.type` | Cible mobile |
|---|---|
| `internship_assignment` | affectation/campagne |
| `conversation` | chat, via `target_id` |
| `campaign` | campagne/hôpitaux |
| `logbook` | journal/tâches |
| `generic` | comportement défini par `metadata` |

Le serveur n’envoie jamais une route Flutter, un `IconData` ou une couleur : il fournit des codes métier, le mobile mappe le rendu.

### 3.2 Objet notification

```json
{
  "id": "notif_01J...",
  "type": "message",
  "subject": "Nouveau message d’encadrement",
  "description": "Dr. Patrick Mwamba vous a envoyé des observations.",
  "created_at": "2026-09-21T08:00:00Z",
  "read_at": null,
  "action": {
    "type": "conversation",
    "target_id": "disc_mwamba",
    "label": "Ouvrir la discussion",
    "title": "Dr. Patrick Mwamba",
    "metadata": {}
  }
}
```

Tous les champs sont requis, sauf `action.title`. `target_id` peut être `null` pour `generic`. Le booléen Flutter `lue` correspond à `read_at != null` ; la date permet synchronisation multi-appareils et audit.

### 3.3 Endpoints de notifications

#### `GET /student/notifications.php`

Paramètres : `filter?` (`all`, `unread`, `internship`, `message`), `cursor?`, `limit?`.

```json
{
  "success": true,
  "message": "Notifications récupérées.",
  "data": {
    "items": [],
    "unread_count": 3,
    "next_cursor": null,
    "has_more": false
  }
}
```

`unread_count` est global et indépendant du filtre.

#### Mutations de lecture

- `PATCH /student/notification-read.php`, corps `{ "notification_id": "notif_01J..." }` : renvoie `notification_id`, `read_at`, `unread_count`.
- `PATCH /student/notifications-read-all.php`, corps vide accepté : renvoie `updated_count`, `read_at`, `unread_count: 0`.

Les deux opérations sont idempotentes.

### 3.4 Push

```json
{
  "notification_id": "notif_01J...",
  "type": "message",
  "action_type": "conversation",
  "target_id": "disc_mwamba",
  "event_id": "evt_01J...",
  "schema_version": "1"
}
```

Le push est un signal, pas la source de vérité : à l’ouverture, le mobile recharge la notification ou la cible. Événement de message et notification partagent une clé de corrélation pour éviter les doublons.

## 4. Conventions transversales

### Réponses

```json
{
  "success": false,
  "message": "Le contenu est invalide.",
  "data": {
    "code": "VALIDATION_ERROR",
    "details": {},
    "request_id": "req_01J..."
  }
}
```

Le client actuel lit `message` et `data`. `code` et `request_id` doivent être stables.

### Identifiants, dates et pagination

- identifiants opaques stables, idéalement UUID/ULID ;
- dates ISO 8601 UTC avec `Z` ;
- temps relatif calculé par Flutter ;
- curseurs opaques pour les listes rapides ;
- tri déterministe avec l’ID comme second critère.

L’OpenAPI existant documente encore `YYYY-MM-DD HH:mm:ss` sans fuseau. Pour ces modules temps réel, UTC est recommandé. Sinon, un fuseau unique doit être documenté.

### Sécurité et cohérence

- vérifier l’appartenance à chaque discussion/notification ;
- protéger ou signer les téléchargements ;
- ne pas journaliser contenu, fichier ou jeton ;
- définir conservation, suppression, modération et audit des contenus médicaux ;
- contrôler fréquence, taille, MIME, antivirus et quotas ;
- calculer les compteurs côté serveur ;
- rendre lectures et créations avec `client_id` idempotentes ;
- diffuser un événement seulement après persistance.

Codes attendus : `200`, `201`, `400`, `401`, `403`, `404`, `409`, `413`, `415`, `422`, `429`, `500`.

### Ce qui reste côté mobile

- icônes, couleurs et initiales d’avatar ;
- format de taille depuis `size_bytes` ;
- heures relatives et séparateurs de date ;
- forme/alignement des bulles et icônes de statut ;
- navigation Flutter concrète et labels localisés génériques.

## 5. Écarts à traiter côté mobile

1. Ajouter modèles JSON, sources distantes et repositories.
2. Remplacer les mutations locales de `nbNonLus`/`lue` par appels API optimistes avec rollback.
3. Gérer chargement, erreur, nouvelle tentative et pagination.
4. Implémenter `ClientApi.envoyerFichier`, actuellement `UPLOAD_NON_IMPLEMENTE`.
5. Brancher capture/sélection d’image et enregistrement/lecture audio réels.
6. Produire `image` pour caméra/galerie au lieu de `document`.
7. Synchroniser les compteurs de l’accueil et le temps réel.
8. Résoudre les vraies cibles de notification au lieu des pages de secours.
9. Désactiver la saisie si `can_send = false`.
10. Ajouter les états locaux d’échec d’envoi/upload, absents aujourd’hui.

## 6. Décisions à figer avec le back-end

- WebSocket, SSE ou polling transitoire ;
- fournisseur push et enregistrement des appareils ;
- rôles pouvant initier/écrire dans direct, groupe et diffusion ;
- limites de médias et durée des URL signées ;
- conservation, suppression et modération ;
- statut `failed` et stratégie de renvoi ;
- avenir de l’appel vocal ;
- destinations exactes `logbook`, `internship_assignment`, `generic` ;
- migration des dates historiques vers UTC.

## 7. Critères d’acceptation

- données et lectures survivent à la fermeture ;
- filtres/recherche reproduisent l’UI ;
- compteurs cohérents entre écrans et appareils ;
- pagination sans doublon ni saut ;
- aucun double envoi après timeout ;
- réponses citées stables ;
- progression `sent → delivered → read` ;
- médias protégés et métadonnées fiables ;
- chaque notification ouvre la bonne cible ;
- événements push/temps réel dédupliqués ;
- erreurs conformes à l’enveloppe commune.

## Résumé pour l’équipe back-end

La messagerie est structurée autour de `conversation → message → attachment/read receipt`. Les notifications suivent `notification → action métier`. `conversation_id` relie les deux modules. Le serveur porte droits, persistance, compteurs, accusés, pagination et synchronisation ; Flutter porte rendu, localisation et navigation concrète.
