# API mobile — candidatures, réservations et paiements STAGIA

Cette documentation couvre les tâches 4 et 5 : workflow canonique de candidature, choix D4, réservations, décisions universitaires, paiements, placements et admissions.

## URL de base et authentification

```text
http://<hote>/stagia/api/v1
```

Toutes les routes de ce document exigent :

```http
Authorization: Bearer <access_token>
Accept: application/json
```

Pour les requêtes avec un corps JSON :

```http
Content-Type: application/json
```

Toutes les réponses JSON utilisent l'enveloppe suivante :

```json
{
  "success": true,
  "message": "Message lisible",
  "data": {}
}
```

Erreurs communes :

- `401` : access token absent, invalide ou expiré ;
- `403` : compte sans rôle `STAGIAIRE` ou profil étudiant inactif ;
- `405` : mauvaise méthode HTTP ;
- `422` : payload invalide ;
- `500` : erreur interne.

## Workflow canonique

```text
Candidature SOUMISE
  → Réservation RESERVEE_TEMPORAIREMENT
  → Décision universitaire
      → REFUSEE / ANNULEE
      → ACCEPTEE
          → stage gratuit : réservation CONFIRMEE
          → stage payant : EN_ATTENTE_PAIEMENT → CONFIRMEE
  → Placement universitaire CONFIRME
  → Admission hospitalière ATTENDU / ADMIS / EN_COURS
  → Affectation PLANIFIEE / ACTIVE / TERMINEE
```

Une admission ne doit jamais apparaître avant un placement universitaire confirmé. Le mobile ne prend ni la décision universitaire, ni la décision d'admission hospitalière.

## D4 et autres types de stage

Le champ `mode` est présent dans les réponses :

```json
{
  "is_d4": true,
  "self_reservation_allowed": true,
  "reservation_mode": "STUDENT_D4_CHOICE"
}
```

- `MEDICAL_D4` : l'étudiant choisit un hôpital et peut appeler `POST /student/reservations`.
- Autres types : `reservation_mode` vaut `UNIVERSITY_MANAGED`; le mobile affiche la campagne, mais ne crée pas de réservation autonome.

## Statut transversal `workflow_status`

| Valeur | Signification mobile |
|---|---|
| `DECISION_UNIVERSITAIRE_EN_ATTENTE` | Candidature soumise et place temporairement retenue. |
| `CANDIDATURE_REFUSEE` | Refus de l'université. |
| `RESERVATION_EXPIREE` | La durée de réservation temporaire est dépassée. |
| `EN_ATTENTE_PAIEMENT` | Décision favorable, paiement requis. |
| `PLACEMENT_UNIVERSITAIRE_EN_ATTENTE` | Réservation confirmée, l'université doit effectuer le placement. |
| `ADMISSION_HOSPITALIERE_EN_ATTENTE` | Placement confirmé, décision de l'hôpital attendue. |
| `AFFECTATION_EN_ATTENTE` | Étudiant admis, unité/affectation attendue. |
| `STAGE_PLANIFIE` | Affectation créée, stage non commencé. |
| `STAGE_EN_COURS` | Admission ou affectation active. |
| `STAGE_TERMINE` | Affectation terminée. |
| `STAGE_VALIDE` | Clôture académique validée. |
| `ANNULEE` | Candidature ou réservation annulée. |

Le mobile doit privilégier `workflow_status` pour l'affichage global et conserver les statuts techniques pour les actions autorisées.

## 1. Consulter les options de stage

### `GET /student/stage-options`

Retourne les campagnes auxquelles l'étudiant est éligible. Les réservations temporaires expirées sont régularisées avant le calcul des disponibilités.

Réponse `200` simplifiée :

```json
{
  "success": true,
  "message": "",
  "data": {
    "campaigns": [
      {
        "campaign_id": 17,
        "academic_enrollment_id": 33,
        "code": "CAM-000017",
        "title": "Stage médical D4 2026",
        "start_date": "2026-11-10",
        "end_date": "2027-01-14",
        "stage_type": { "code": "MEDICAL_D4", "label": "Stage médical D4" },
        "mode": {
          "is_d4": true,
          "self_reservation_allowed": true,
          "reservation_mode": "STUDENT_D4_CHOICE"
        },
        "promotion": { "code": "PRO-0006", "name": "Médecine générale", "level": "D4" },
        "program": "Médecine générale",
        "hospitals": [
          {
            "participation_id": 42,
            "hospital": {
              "code": "HGT",
              "name": "Hôpital Général de Test",
              "city": "Kinshasa",
              "province": "Kinshasa"
            },
            "capacity": 20,
            "used_places": 7,
            "available_places": 13,
            "available": true,
            "fees_required": true,
            "amount": 50000,
            "currency": "CDF",
            "conditions": "Conditions de l'hôpital"
          }
        ],
        "hospitals_count": 1,
        "available_hospitals": 1
      }
    ],
    "university_managed_campaigns": [],
    "stats": {
      "campaigns": 1,
      "university_managed_campaigns": 0,
      "hospitals": 1,
      "available_hospitals": 1,
      "available_places": 13
    }
  }
}
```

Pour réserver, reprendre sans modification les trois identifiants retournés : `campaign_id`, `academic_enrollment_id` et `participation_id`.

## 2. Soumettre une candidature D4 et réserver

### `POST /student/reservations`

Payload :

```json
{
  "campaign_id": 17,
  "academic_enrollment_id": 33,
  "participation_id": 42,
  "motivation": "Je souhaite effectuer ce stage dans cet hôpital."
}
```

`motivation` est facultatif et limité à 1 000 caractères.

Réponse `201` lors de la création :

```json
{
  "success": true,
  "message": "Candidature soumise. La place est réservée temporairement dans l’attente de la décision universitaire.",
  "data": {
    "created": true,
    "application_id": 81,
    "application_uuid": "11111111-1111-4111-8111-111111111111",
    "application_status": "SOUMISE",
    "reservation_id": 64,
    "reservation_uuid": "22222222-2222-4222-8222-222222222222",
    "reservation_status": "RESERVEE_TEMPORAIREMENT",
    "expires_at": "2026-09-26 15:30:00",
    "reservation_duration_minutes": 30,
    "hospital": { "code": "HGT", "name": "Hôpital Général de Test" },
    "fees": { "required": true, "amount": 50000, "currency": "CDF" },
    "places_remaining": 12
  }
}
```

Si la même réservation est déjà active, la route est idempotente et répond `200` avec `created: false` et les mêmes UUID.

Erreurs spécifiques :

- `409` : campagne non éligible/fermée, offre hospitalière invalide, capacité épuisée ou autre réservation active ;
- `422` : identifiants absents/invalides ou motivation trop longue.

## 3. Lister les candidatures

### `GET /student/applications`

Réponse `200` :

```json
{
  "success": true,
  "message": "",
  "data": {
    "items": [
      {
        "uuid": "11111111-1111-4111-8111-111111111111",
        "statut": "ACCEPTEE",
        "application_status": "ACCEPTEE",
        "motivation": "...",
        "motif_refus": null,
        "submitted_at": "2026-09-26 15:00:00",
        "responded_at": "2026-09-26 16:00:00",
        "campaign_code": "CAM-000017",
        "campaign_title": "Stage médical D4 2026",
        "campaign_start": "2026-11-10",
        "campaign_end": "2027-01-14",
        "hospital_code": "HGT",
        "hospital_name": "Hôpital Général de Test",
        "ville": "Kinshasa",
        "province": "Kinshasa",
        "reservation_uuid": "22222222-2222-4222-8222-222222222222",
        "reservation_status": "EN_ATTENTE_PAIEMENT",
        "placement_uuid": null,
        "placement_status": null,
        "admission_uuid": null,
        "admission_status": null,
        "assignment_uuid": null,
        "assignment_status": null,
        "completion_status": null,
        "taux_presence": null,
        "note_finale": null,
        "stage_type": { "code": "MEDICAL_D4", "label": "Stage médical D4" },
        "mode": {
          "is_d4": true,
          "self_reservation_allowed": true,
          "reservation_mode": "STUDENT_D4_CHOICE"
        },
        "workflow_status": "EN_ATTENTE_PAIEMENT"
      }
    ],
    "total": 1
  }
}
```

## 4. Lister les réservations

### `GET /student/reservations`

La route retourne notamment :

- `can_confirm`, actuellement toujours `false` : la confirmation est pilotée par la décision et le paiement ;
- `confirmation_managed_by`: `PAYMENT` ou `UNIVERSITY` ;
- `can_cancel` calculé côté serveur ;
- `workflow_status` pour l'écran mobile.

Réponse `200` simplifiée :

```json
{
  "success": true,
  "message": "",
  "data": {
    "items": [
      {
        "uuid": "22222222-2222-4222-8222-222222222222",
        "statut": "EN_ATTENTE_PAIEMENT",
        "expires_at": null,
        "application_uuid": "11111111-1111-4111-8111-111111111111",
        "application_status": "ACCEPTEE",
        "frais_requis": true,
        "montant_frais": 50000,
        "devise": "CDF",
        "expired": false,
        "can_confirm": false,
        "confirmation_managed_by": "PAYMENT",
        "can_cancel": true,
        "workflow_status": "EN_ATTENTE_PAIEMENT"
      }
    ],
    "stats": {
      "total": 1,
      "temporary": 0,
      "waiting_payment": 1,
      "confirmed": 0,
      "expired": 0,
      "cancelled": 0
    }
  }
}
```

## 5. Vérifier une confirmation

### `POST /student/reservations/{uuid}/confirm`

Le corps est vide. Cette route ne confirme pas une réservation temporaire et ne valide pas un paiement. Elle répond avec succès uniquement lorsque la réservation est déjà `CONFIRMEE`.

Réponse `200` :

```json
{
  "success": true,
  "message": "Réservation déjà confirmée.",
  "data": {
    "confirmed": true,
    "idempotent": true,
    "reservation_uuid": "22222222-2222-4222-8222-222222222222",
    "reservation_status": "CONFIRMEE",
    "next_step": "UNIVERSITY_PLACEMENT"
  }
}
```

`next_step` vaut `UNIVERSITY_PLACEMENT` ou `HOSPITAL_ADMISSION`.

Erreurs spécifiques :

- `404` : réservation inexistante ou appartenant à un autre étudiant ;
- `409` : décision universitaire en attente, paiement requis, réservation expirée ou annulée.

## 6. Annuler une réservation

### `POST /student/reservations/{uuid}/cancel`

Le corps est vide.

Réponse `200` :

```json
{
  "success": true,
  "message": "Réservation annulée.",
  "data": {
    "cancelled": true,
    "idempotent": false,
    "reservation_uuid": "22222222-2222-4222-8222-222222222222",
    "reservation_status": "ANNULEE"
  }
}
```

Un second appel répond également `200` avec `idempotent: true`.

L'annulation mobile est refusée (`409`) lorsqu'un placement/admission existe ou lorsqu'un paiement validé exige d'abord un remboursement. Les paiements encore `INITIE`/`EN_ATTENTE` et la facture ouverte sont annulés avec la réservation.

## 7. Consulter les paiements

### `GET /student/payments`

Seules les candidatures acceptées sont retournées.

Réponse `200` simplifiée :

```json
{
  "success": true,
  "message": "",
  "data": {
    "items": [
      {
        "application_uuid": "11111111-1111-4111-8111-111111111111",
        "reservation_uuid": "22222222-2222-4222-8222-222222222222",
        "reservation_status": "EN_ATTENTE_PAIEMENT",
        "campaign": { "code": "CAM-000017", "title": "Stage médical D4 2026" },
        "hospital": { "code": "HGT", "name": "Hôpital Général de Test" },
        "payment_required": true,
        "payment_allowed": true,
        "payment_status": "NOT_STARTED",
        "amount_required": 50000,
        "amount_validated": 0,
        "amount_remaining": 50000,
        "currency": "CDF",
        "invoice": {
          "uuid": "33333333-3333-4333-8333-333333333333",
          "reference": "INV-STG-2026-001",
          "status": "EMISE",
          "issued_at": "2026-09-26 16:00:00",
          "due_at": "2026-09-27 16:00:00",
          "paid_at": null
        },
        "payments": []
      }
    ],
    "stats": { "total": 1, "payable": 1, "paid": 0, "pending": 0, "failed": 0, "free": 0 },
    "channels": {
      "MPESA": "M-Pesa",
      "ORANGE_MONEY": "Orange Money",
      "AIRTEL_MONEY": "Airtel Money",
      "AFRIMONEY": "Afrimoney",
      "BANQUE": "Banque",
      "CARTE": "Carte bancaire"
    }
  }
}
```

Valeurs de `payment_status` : `NOT_REQUIRED`, `NOT_STARTED`, `PENDING`, `FAILED`, `PARTIAL`, `PAID`.

Le bouton de paiement doit être affiché uniquement si `payment_allowed` vaut `true`.

## 8. Initier un paiement

### `POST /student/payments/initiate`

Payload recommandé :

```json
{
  "reservation_uuid": "22222222-2222-4222-8222-222222222222",
  "channel": "MPESA",
  "phone_number": "+243810000000",
  "idempotency_key": "pay-22222222-attempt-1"
}
```

La facture peut aussi être désignée par `invoice_uuid` ou `invoice_id`. Le champ `canal` est accepté comme alias de `channel`.

La clé d'idempotence est obligatoire, limitée à 100 caractères, et peut être envoyée dans le corps ou dans l'en-tête :

```http
Idempotency-Key: pay-22222222-attempt-1
```

Pour `MPESA`, `ORANGE_MONEY`, `AIRTEL_MONEY` et `AFRIMONEY`, `phone_number` est obligatoire. Il est facultatif pour `BANQUE` et `CARTE`.

Réponse `201` lors d'une nouvelle tentative :

```json
{
  "success": true,
  "message": "Paiement initié. En attente de confirmation de l’opérateur.",
  "data": {
    "payment": {
      "created": true,
      "idempotent": false,
      "uuid": "44444444-4444-4444-8444-444444444444",
      "reference": "PAY-STG-20260926170000-A1B2C3D4",
      "transaction_reference": null,
      "amount": 50000,
      "currency": "CDF",
      "channel": "MPESA",
      "operator": "M-Pesa",
      "status": "EN_ATTENTE",
      "phone_number": "+243810000000",
      "initiated_at": "2026-09-26 17:00:00",
      "paid_at": null,
      "validated_at": null
    },
    "reservation_uuid": "22222222-2222-4222-8222-222222222222"
  }
}
```

Une répétition avec la même clé ou lorsqu'une tentative est déjà en attente répond `200`, avec `created: false` et `idempotent: true`.

Erreurs spécifiques :

- `404` : facture/réservation introuvable ou appartenant à un autre étudiant ;
- `409` : candidature non acceptée, réservation pas encore autorisée à payer, stage gratuit, facture fermée ;
- `422` : facture/réservation, canal, téléphone ou clé d'idempotence invalide.

## 9. Synchroniser l'état du paiement

### `POST /student/payments/sync`

```json
{
  "reservation_uuid": "22222222-2222-4222-8222-222222222222"
}
```

Cette route ne crée aucune transaction. Elle recalcule l'état depuis les paiements enregistrés et confirme la réservation si le montant validé couvre la facture. Pour un stage gratuit accepté, elle confirme directement la réservation avec `payment_status: NOT_REQUIRED`.

Réponse `200` pour un paiement validé :

```json
{
  "success": true,
  "message": "Paiement confirmé. La réservation attend le placement universitaire.",
  "data": {
    "reservation_uuid": "22222222-2222-4222-8222-222222222222",
    "reservation_status": "CONFIRMEE",
    "payment_status": "PAID",
    "invoice_status": "PAYEE",
    "amount_required": 50000,
    "amount_validated": 50000,
    "amount_remaining": 0,
    "currency": "CDF",
    "placement_pending": true
  }
}
```

Autres résultats possibles : `NOT_REQUIRED`, `PARTIAL`, `PENDING`, `FAILED`, `NOT_STARTED`, `NOT_CONFIRMED`.

Une réponse HTTP `200` ne signifie donc pas toujours que le paiement est réussi : vérifier obligatoirement `data.payment_status`.

## 10. Consulter placements et admissions

### `GET /student/admissions`

Filtre facultatif :

```text
GET /student/admissions?reservation_uuid=22222222-2222-4222-8222-222222222222
```

Réponse `200` simplifiée :

```json
{
  "success": true,
  "message": "",
  "data": {
    "items": [
      {
        "reservation": {
          "uuid": "22222222-2222-4222-8222-222222222222",
          "status": "CONFIRMEE",
          "expires_at": null,
          "confirmed_at": "2026-09-26 18:00:00"
        },
        "application": { "uuid": "11111111-1111-4111-8111-111111111111", "status": "ACCEPTEE" },
        "placement": {
          "exists": true,
          "uuid": "55555555-5555-4555-8555-555555555555",
          "status": "CONFIRME",
          "confirmed_at": "2026-09-27 09:00:00"
        },
        "admission": {
          "exists": true,
          "uuid": "66666666-6666-4666-8666-666666666666",
          "status": "ATTENDU",
          "admitted_at": null,
          "observation": null
        },
        "assignment": {
          "exists": false,
          "uuid": null,
          "status": null,
          "start_date": null,
          "end_date": null,
          "assigned_at": null,
          "ended_at": null,
          "observation": null,
          "unit": { "code": null, "name": null }
        },
        "workflow_status": "ADMISSION_HOSPITALIERE_EN_ATTENTE"
      }
    ],
    "stats": {
      "total": 1,
      "waiting_decision": 0,
      "waiting_payment": 0,
      "waiting_placement": 0,
      "waiting_admission": 1,
      "admitted": 0,
      "assigned": 0,
      "completed": 0,
      "refused": 0,
      "expired": 0
    }
  }
}
```

## Enchaînement recommandé côté mobile

```text
GET /student/stage-options
  → afficher campaigns pour le choix D4
  → afficher university_managed_campaigns en lecture seule

POST /student/reservations
  → conserver application_uuid et reservation_uuid
  → attendre la décision universitaire

GET /student/applications ou /student/reservations
  → REFUSEE : afficher le motif
  → RESERVEE_TEMPORAIREMENT : décision en attente
  → EN_ATTENTE_PAIEMENT : ouvrir l'écran de paiement
  → CONFIRMEE : attendre le placement

GET /student/payments
  → payment_allowed=true : proposer les canaux
  → POST /student/payments/initiate avec une clé stable
  → POST /student/payments/sync jusqu'à un état terminal

GET /student/admissions
  → suivre placement, admission et affectation
```

Ne pas lancer simultanément plusieurs initiations pour une même facture. Conserver la même `idempotency_key` lors d'une reprise réseau de la même tentative, et générer une nouvelle clé uniquement pour une nouvelle tentative après échec confirmé.

## Préparation de la base de test

Appliquer la migration suivante avant de tester l'idempotence des paiements :

```text
database/migrations/2026_09_25_000011_stage_payment_idempotency.sql
```

Le fichier OpenAPI associé est `candidatures-reservations-paiements-mobile.openapi.json`.
