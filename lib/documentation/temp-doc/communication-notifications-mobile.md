# API mobile — communication, calendrier et notifications STAGIA

Cette documentation couvre la tâche 8 pour l'application étudiante :

- notifications privées et compteurs ;
- actions de notification et navigation vers la ressource concernée ;
- conversations privées et groupes dont l'étudiant est membre ;
- communications officielles destinées à l'étudiant ou à son rôle `STAGIAIRE` ;
- calendrier et invitations ;
- préférences de notification ;
- appareils push et flux temps réel SSE.

## URL de base et authentification

```text
http://<hote>/stagia/api/v1
```

Toutes les routes exigent un Bearer token appartenant à un étudiant actif :

```http
Authorization: Bearer <access_token>
Accept: application/json
```

Réponse JSON habituelle :

```json
{
  "success": true,
  "message": "Message lisible",
  "data": {}
}
```

Erreurs communes :

- `400` corps JSON invalide ;
- `401` token absent, invalide ou expiré ;
- `403` compte non étudiant, profil inactif ou ressource hors périmètre ;
- `404` ressource inexistante ou non visible par l'étudiant ;
- `405` méthode HTTP incorrecte ;
- `422` données invalides ;
- `500` erreur interne.

## Règles de visibilité

L'API n'utilise jamais la session PHP du Web.

- Une notification est visible seulement si `notifications.utilisateur_id` correspond au compte Bearer.
- Une conversation est visible seulement si l'étudiant est un participant actif.
- Une pièce jointe est accessible seulement à un participant de la conversation correspondante.
- Un événement est visible seulement si l'étudiant est dans `participants_evenements`.
- Une communication officielle est visible si l'étudiant est destinataire direct ou si son rôle actif est ciblé. Les diffusions générales créées par le Web restent visibles lorsqu'elles ont été matérialisées en destinataires individuels.

# Partie A — Notifications

## 1. Lister les notifications

### `GET /student/notifications`

Paramètres facultatifs :

| Paramètre | Description |
|---|---|
| `limit` | Nombre d'éléments, 30 par défaut et 100 maximum |
| `before_id` | Curseur numérique retourné dans `next_before_id` |
| `unread` | `true` pour limiter aux notifications non lues |
| `type` | Type d'événement serveur exact |

```json
{
  "success": true,
  "message": "",
  "data": {
    "items": [
      {
        "sequence": 184,
        "id": "01JQ0G8K9M5H2T7B4P6S3N1R8C",
        "event_type": "stage.assignment.updated",
        "type": "internship",
        "subject": "Votre affectation a été modifiée",
        "description": "Service : Chirurgie — du 2026-10-01 au 2026-12-31",
        "priority": "normale",
        "read_at": null,
        "archived_at": null,
        "created_at": "2026-09-27 10:30:00.000000",
        "action": {
          "type": "internship_assignment",
          "target_id": "11111111-1111-4111-8111-111111111111",
          "label": "Voir mon affectation",
          "title": "Chirurgie",
          "metadata": { "status": "PLANIFIEE" }
        }
      }
    ],
    "next_before_id": 184,
    "counts": { "notifications": 3, "messages": 2, "total": 3 }
  }
}
```

`id` est l'identifiant public de la notification. `sequence` sert uniquement à la pagination. Le mobile ne doit jamais construire une route Flutter à partir d'une URL Web : il utilise `action.type` et `action.target_id`.

### Catégories de rendu

Le champ `type` est une catégorie stable utilisable par Flutter :

- `internship` ;
- `message` ;
- `logbook` ;
- `urgent` ;
- `academic`.

Le champ `event_type` conserve l'événement métier détaillé.

## 2. Actions de notification

Structure commune :

```json
{
  "type": "conversation",
  "target_id": "01JQ0CONVERSATIONUUID000001",
  "label": "Ouvrir la discussion",
  "title": "Encadrement clinique",
  "metadata": {
    "message_id": "01JQ0MESSAGEUUID0000000001"
  }
}
```

Actions actuellement produites ou reconnues :

| `action.type` | `target_id` | Destination mobile attendue |
|---|---|---|
| `internship_assignment` | UUID d'affectation | Page « Mon stage » ou détail de l'affectation |
| `conversation` | ULID de conversation | Discussion correspondante |
| `official_communication` | ULID de communication | Détail de la communication officielle |
| `calendar_event` | ULID d'événement | Événement du calendrier |
| `campaign` | UUID de campagne | Détail de campagne |
| `logbook` | UUID de journal | Journal concerné |
| `task` | UUID de tâche | Détail de tâche |
| `payment` | UUID de paiement | Détail ou état du paiement |
| `academic_document` | Identifiant du document | Visualisation du document |
| `generic` | éventuellement `null` | Écran générique défini par `metadata` |

Si la cible a disparu ou n'est plus autorisée, le mobile doit afficher un message puis revenir à la liste correspondante. Le serveur revérifie toujours l'appartenance lors du chargement de la cible.

## 3. Compteurs

### `GET /student/notifications/counts`

```json
{
  "success": true,
  "message": "",
  "data": {
    "notifications": 3,
    "messages": 2,
    "total": 3
  }
}
```

`total` utilise le maximum des deux compteurs, car un nouveau message crée aussi une notification et ne doit pas être compté deux fois.

## 4. Marquer comme lue ou archiver

### `POST /student/notifications/{uuid}/read`

### `POST /student/notifications/{uuid}/archive`

Aucun corps n'est requis. Ces opérations ne peuvent modifier qu'une notification appartenant au compte Bearer.

```json
{
  "success": true,
  "message": "Notification marquée comme lue.",
  "data": {
    "counts": { "notifications": 2, "messages": 2, "total": 2 }
  }
}
```

# Partie B — Temps réel et push

## 5. Flux SSE

### `GET /student/notifications/stream`

En-têtes :

```http
Authorization: Bearer <access_token>
Accept: text/event-stream
```

Le flux dure environ 25 secondes, envoie un `keep-alive` toutes les deux secondes et demande une reconnexion automatique. Le serveur propose `retry: 3000`.

Événements :

- `ready` : connexion établie et compteurs initiaux ;
- `notification` : nouvelle notification avec son action complète ;
- `message` : nouveau message dans une conversation autorisée ;
- `communication` : nouvelle communication officielle visible ;
- `calendar` : nouvelle invitation ;
- `counts` : compteurs recalculés ;
- `error` : flux momentanément indisponible.

Exemple :

```text
id: 184.926.51.73
event: notification
data: {"id":"01J...","type":"message","action":{"type":"conversation","target_id":"01J..."}}
```

Pour reprendre le flux, transmettre le dernier identifiant reçu dans `Last-Event-ID` ou dans `?cursor=184.926.51.73`.

Sur Android, utiliser un client SSE capable d'envoyer l'en-tête Bearer. Le `EventSource` Web standard ne permet pas toujours de définir cet en-tête.

## 6. Enregistrer un appareil push

### `POST /student/notifications/devices`

```json
{
  "platform": "android",
  "token": "jeton-fcm-ou-equivalent-d-au-moins-20-caracteres",
  "device_name": "Samsung A54",
  "app_version": "1.0.0+1"
}
```

Plateformes : `android`, `ios`, `web`.

```json
{
  "success": true,
  "message": "Appareil enregistré.",
  "data": {
    "uuid": "01JQ0DEVICE0000000000000000",
    "platform": "android"
  }
}
```

L'enregistrement est rejouable : renvoyer le même jeton réactive et actualise l'appareil.

### `GET /student/notifications/devices`

Liste les appareils du compte sans exposer leurs jetons.

### `DELETE /student/notifications/devices/{uuid}`

Désactive l'appareil. À appeler lors de la déconnexion si le jeton ne doit plus recevoir de push pour ce compte.

Payload transmis au fournisseur push :

```json
{
  "destination": "jeton-appareil",
  "notification_id": "01JQ0G8K9M5H2T7B4P6S3N1R8C",
  "event_id": "01JQ0G8K9M5H2T7B4P6S3N1R8C",
  "type": "stage.assignment.updated",
  "titre": "Votre affectation a été modifiée",
  "contenu": "Service : Chirurgie — du 2026-10-01 au 2026-12-31",
  "action_type": "internship_assignment",
  "target_id": "11111111-1111-4111-8111-111111111111",
  "action": {
    "type": "internship_assignment",
    "target_id": "11111111-1111-4111-8111-111111111111",
    "label": "Voir mon affectation"
  },
  "schema_version": "1"
}
```

Le push est seulement un signal : après un clic, le mobile recharge la notification ou la ressource avec le Bearer token.

# Partie C — Préférences

## 7. Consulter les préférences

### `GET /student/notifications/preferences`

```json
{
  "success": true,
  "message": "",
  "data": {
    "items": [
      { "type": "*", "channel": "email", "active": true },
      { "type": "nouveau_message", "channel": "push", "active": true }
    ],
    "defaults": { "email": true, "sms": true, "push": true },
    "internal_notifications": true
  }
}
```

Les notifications internes restent actives. Les préférences concernent les canaux externes.

## 8. Modifier les préférences

### `PATCH /student/notifications/preferences`

`PUT` est aussi accepté.

```json
{
  "type": "*",
  "channels": {
    "email": true,
    "sms": false,
    "push": true
  }
}
```

`type: "*"` définit le comportement global. Un type précis, par exemple `nouveau_message`, surcharge la préférence globale.

# Partie D — Messagerie

## 9. Annuaire autorisé

### `GET /student/communication/contacts`

Retourne uniquement les comptes que l'étudiant peut contacter selon son université, ses établissements d'accueil et les partenaires de stage.

## 10. Conversations

### `GET /student/conversations`

Paramètres : `limit` et `offset`.

Chaque élément contient notamment :

- `uuid`, `objet`, `type_conversation` et `statut` ;
- `participant_count` ;
- `last_message` et `last_activity_at` ;
- `unread_count` ;
- le brouillon éventuel.

### `POST /student/conversations`

```json
{
  "subject": "Suivi de ma rotation",
  "recipient_user_ids": [42, 51]
}
```

Un seul destinataire crée une conversation `privee`. Plusieurs destinataires créent une conversation `groupe`. Tous les destinataires sont revérifiés côté serveur.

## 11. Messages

### `GET /student/conversations/{uuid}/messages`

Paramètres :

- `after_id` : retourner seulement les messages dont la séquence est supérieure ;
- `limit` : 50 par défaut, 100 maximum.

La réponse contient la conversation, ses participants, les messages et les pièces jointes. Les endpoints de fichiers indiquent `requires_bearer: true`.

### `POST /student/conversations/{uuid}/messages`

JSON sans fichier :

```json
{ "content": "Bien reçu, merci." }
```

Avec fichier, envoyer `multipart/form-data` :

- `content` facultatif si un fichier est fourni ;
- `attachment` : PDF, Office, texte, CSV, JPEG, PNG ou WebP ;
- taille maximale : 10 Mo.

### `POST /student/conversations/{uuid}/messages/read`

```json
{ "message_uuid": "01JQ0MESSAGEUUID0000000001" }
```

Le pointeur de lecture utilise `GREATEST` et ne peut pas reculer.

## 12. Brouillons

### `PUT /student/conversations/{uuid}/draft`

```json
{ "content": "Texte du brouillon" }
```

### `DELETE /student/conversations/{uuid}/draft`

Supprime uniquement le brouillon de l'étudiant connecté.

## 13. Pièces jointes

### `GET /student/conversations/{conversationUuid}/messages/{messageUuid}/attachments/{fileUuid}`

Ajouter `?download=1` pour forcer le téléchargement. Sans ce paramètre, les images, textes et PDF compatibles sont rendus en ligne.

# Partie E — Communications officielles

## 14. Lister les communications

### `GET /student/communications`

Paramètres : `limit` et `offset`.

Retourne uniquement les communications publiées visibles par l'étudiant, avec : type, référence, objet, contenu, priorité, émetteur, accusé requis, lecture et accusé de réception.

## 15. Lecture et accusé

### `POST /student/communications/{uuid}/read`

Marque la communication comme lue. Si un accusé de réception est requis, il est enregistré dans la même opération. Une communication ciblée par rôle est matérialisée comme destinataire direct lors de la première lecture.

# Partie F — Calendrier

## 16. Lister les événements

### `GET /student/calendar`

Paramètres ISO 8601 facultatifs : `from` et `to`. Sans `from`, l'API conserve les événements terminés depuis moins de 30 jours.

Seuls les événements auxquels l'étudiant participe sont retournés. Les événements annulés sont exclus.

## 17. Créer un événement

### `POST /student/calendar`

```json
{
  "title": "Révision du dossier clinique",
  "description": "Préparer les observations",
  "type": "reunion",
  "starts_at": "2026-10-04T09:00:00+02:00",
  "ends_at": "2026-10-04T10:00:00+02:00",
  "location": "Salle 3",
  "participant_user_ids": [42, 51]
}
```

Types acceptés : `reunion`, `convocation`, `visite`, `evaluation`, `echeance`, `autre`.

## 18. Répondre à une invitation

### `POST /student/calendar/{uuid}/response`

```json
{ "response": "accepte" }
```

Valeurs : `accepte`, `refuse`, `incertain`.

# Intégration Flutter

Le modèle Flutter existant utilise `actionLabel` et `CibleNotification`. Le mapping recommandé est :

```text
action.label       → actionLabel
action.target_id   → cible.identifiant
action.title       → cible.titre
action.metadata    → cible.donneesSupplementaires
```

Les codes `internship_assignment`, `conversation`, `campaign` et `logbook` correspondent aux cibles déjà prévues. Le mobile devra ajouter ou mapper `official_communication`, `calendar_event`, `task`, `payment` et `academic_document` vers les pages correspondantes.

La page Flutter actuelle utilise encore une source mockée. La source distante, le parseur JSON, le client SSE et le fournisseur push devront être branchés côté mobile.

## Migration requise

Avant de tester l'enregistrement des appareils :

```text
database/migrations/2026_09_27_000012_mobile_communication.sql
```

Elle crée `mobile_notification_devices`. Les autres tables proviennent des migrations de communication déjà existantes.
