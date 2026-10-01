# API mobile — suivi du stage et dossier académique STAGIA

Cette documentation couvre :

- la tâche 6 : stage affecté, rotations, pointage, journal, tâches, feedbacks et évaluations ;
- la tâche 7 : profil, rattachements, parcours, notes, conventions, certificats et documents personnels.

## URL de base et authentification

```text
http://<hote>/stagia/api/v1
```

Toutes les routes exigent un étudiant authentifié :

```http
Authorization: Bearer <access_token>
Accept: application/json
```

Les réponses JSON utilisent l'enveloppe :

```json
{
  "success": true,
  "message": "Message lisible",
  "data": {}
}
```

Erreurs communes : `401` token invalide/expiré, `403` profil non étudiant ou inactif, `405` méthode incorrecte et `500` erreur interne.

# Partie A — Suivi et exécution du stage

## 1. Stages affectés, groupes et rotations

### `GET /student/stages`

Retourne les affectations non annulées provenant du workflow canonique, avec :

- campagne, hôpital, promotion et unité initiale ;
- groupe éventuel ;
- admission et affectation ;
- toutes les rotations ;
- encadreur principal de chaque rotation ;
- statistiques de clôture ;
- droits d'exécution du jour.

Réponse simplifiée :

```json
{
  "success": true,
  "message": "",
  "data": {
    "student": { "id": 30, "stagia_code": "STG-ETU-00000030" },
    "items": [
      {
        "assignment_id": 12,
        "assignment_uuid": "11111111-1111-4111-8111-111111111111",
        "assignment_status": "ACTIVE",
        "date_debut": "2026-09-01",
        "date_fin": "2026-11-30",
        "campaign_code": "CAM-000017",
        "campaign_title": "Stage médical D4",
        "stage_type_code": "MEDICAL_D4",
        "hospital_code": "HGT",
        "hospital_name": "Hôpital Général de Test",
        "group_uuid": "22222222-2222-4222-8222-222222222222",
        "group_code": "GRP-D4-01",
        "group_name": "Groupe D4 1",
        "rotations": [
          {
            "rotation_id": 31,
            "rotation_uuid": "33333333-3333-4333-8333-333333333333",
            "sequence_no": 1,
            "date_debut": "2026-09-01",
            "date_fin": "2026-09-30",
            "statut": "ACTIVE",
            "unit_code": "URG",
            "unit_name": "Urgences",
            "supervisor_name": "Jean Encadreur",
            "supervisor_function": "Médecin encadreur"
          }
        ],
        "execution_access": {
          "date": "2026-09-26",
          "current_rotation": {},
          "next_rotation": null,
          "can_logbook": true,
          "can_attendance": true,
          "can_evaluation": true,
          "reason": null,
          "unlock_date": null
        },
        "workflow_status": "EN_COURS"
      }
    ],
    "summary": { "total": 1, "planned": 0, "active": 1, "completed": 0, "validated": 0 }
  }
}
```

Valeurs principales de `workflow_status` : `PLANIFIE`, `EN_COURS`, `TERMINE`, `VALIDE`.

## 2. Contexte d'exécution et de pointage

### `GET /student/attendance/context`

Paramètre facultatif : `assignment_uuid`.

La même implémentation est aussi accessible par `GET /student/execution-context`.

```json
{
  "success": true,
  "message": "",
  "data": {
    "execution": {
      "date": "2026-09-26",
      "current_rotation": {
        "rotation_id": 31,
        "sequence_no": 1,
        "date_debut": "2026-09-01",
        "date_fin": "2026-09-30",
        "statut": "ACTIVE",
        "unit_code": "URG",
        "unit_name": "Urgences",
        "supervisor_name": "Jean Encadreur"
      },
      "next_rotation": null,
      "can_logbook": true,
      "can_attendance": true,
      "can_evaluation": true,
      "reason": null,
      "unlock_date": null
    },
    "punch": {
      "date": "2026-09-26",
      "student_id": 30,
      "stagia_code": "STG-ETU-00000030",
      "assignment_id": 12,
      "rotation": {},
      "attendance": null,
      "can_punch": true,
      "next_action": "ARRIVEE",
      "next_rotation": null,
      "reason": null
    }
  }
}
```

`next_action` vaut `ARRIVEE`, `DEPART`, `TERMINE` ou `null`. Le mobile doit respecter `can_punch`, `can_attendance` et `reason`.

## 3. Pointer l'arrivée ou le départ

### `POST /student/attendance/arrival`

### `POST /student/attendance/departure`

Aucun corps n'est requis. La date et l'heure proviennent du serveur. Une rotation active appartenant à l'étudiant est obligatoire.

```json
{
  "success": true,
  "message": "Arrivée pointée à 08:04.",
  "data": {
    "punch": {
      "date": "2026-09-26",
      "attendance": {
        "uuid": "44444444-4444-4444-8444-444444444444",
        "date_presence": "2026-09-26",
        "heure_arrivee": "08:04:00",
        "heure_depart": null,
        "statut": "PRESENT",
        "source": "MOBILE"
      },
      "can_punch": true,
      "next_action": "DEPART"
    }
  }
}
```

Erreur `422` si aucune rotation n'est active, si l'arrivée est déjà enregistrée, si le départ précède l'arrivée ou si le pointage est terminé.

## 4. Historique des présences

### `GET /student/attendance?assignment_uuid={uuid}`

`assignment_uuid` est facultatif.

La réponse contient `items` et :

```json
{
  "stats": {
    "total": 20,
    "present": 15,
    "late": 2,
    "absent": 1,
    "justified": 1,
    "guard": 1,
    "effective_presence": 18,
    "attendance_rate": 90
  }
}
```

Chaque présence contient `uuid`, `date`, `status`, `arrival_time`, `departure_time`, `source`, `observation`, puis les objets `rotation`, `assignment`, `campaign`, `hospital` et `unit`.

## 5. Journal de stage

### `GET /student/logbook?assignment_uuid={uuid}`

Liste les journées du journal. Chaque élément retourne :

- `uuid`, `date`, `status` ;
- `summary`, `learning`, `difficulties`, `observation` ;
- `submitted_at`, `validated_at`, `validator_comment` ;
- `editable`, `can_submit` ;
- `activities` et `activities_count` ;
- rotation, affectation, campagne, hôpital et unité.

Les statistiques sont `total`, `draft`, `submitted`, `validated`, `rejected` et `activities`.

### `POST /student/logbook`

Crée le brouillon du jour ou modifie un brouillon/rejet existant.

```json
{
  "assignment_uuid": "11111111-1111-4111-8111-111111111111",
  "uuid": null,
  "date": "2026-09-26",
  "summary": "Accueil et examen de trois patients.",
  "learning": "Interprétation clinique initiale.",
  "difficulties": "Gestion du temps.",
  "observation": "Journée supervisée.",
  "activities": [
    {
      "category": "PARTICIPATION",
      "activity": "Consultation",
      "description": "Consultation supervisée",
      "involvement_level": "REALISE_SUPERVISE",
      "quantity": 3,
      "observation": ""
    }
  ]
}
```

Pour modifier un journal, envoyer son `uuid`. Pour créer, omettre `uuid` ou envoyer une chaîne vide.

Catégories : `OBSERVATION`, `PARTICIPATION`, `REALISATION`, `GARDE`, `CONSULTATION`, `AUTRE`.

Niveaux : chaîne vide, `OBSERVE`, `ASSISTE`, `REALISE_SUPERVISE`, `REALISE_AUTONOME`.

Réponse :

```json
{
  "success": true,
  "message": "Journal enregistré en brouillon.",
  "data": {
    "uuid": "55555555-5555-4555-8555-555555555555",
    "status": "BROUILLON",
    "date": "2026-09-26",
    "activities_count": 1
  }
}
```

La création est limitée à aujourd'hui, à la période du stage et à une rotation active. Une journée déjà soumise/validée n'est plus modifiable. Les conflits métier répondent `409`; les champs invalides répondent `422`.

### `POST /student/logbook/{uuid}/submit`

Le corps peut être vide. Un résumé et au moins une activité sont obligatoires.

```json
{
  "success": true,
  "message": "Journal soumis pour validation.",
  "data": {
    "uuid": "55555555-5555-4555-8555-555555555555",
    "status": "SOUMIS",
    "activities_count": 1,
    "assignment_uuid": "11111111-1111-4111-8111-111111111111"
  }
}
```

La soumission est idempotente : un journal déjà `SOUMIS` ou `VALIDE` renvoie `200`.

## 6. Tâches du stage

### `GET /student/tasks`

Filtres facultatifs : `assignment_uuid` et `status`.

Retourne `items`, les statistiques `a_faire`, `en_cours`, `terminees`, `a_revoir`, `validees`, `annulees`, et `progress` en pourcentage.

Statuts : `A_FAIRE`, `EN_COURS`, `TERMINEE`, `A_REVOIR`, `VALIDEE`, `ANNULEE`.

### `POST /student/tasks/{uuid}/start`

```json
{ "comment": "Je commence cette tâche." }
```

Transition autorisée : `A_FAIRE` ou `A_REVOIR` vers `EN_COURS`.

### `POST /student/tasks/{uuid}/comment`

```json
{ "comment": "Compte rendu intermédiaire." }
```

Le commentaire est obligatoire. Une tâche validée ou annulée est verrouillée.

### `POST /student/tasks/{uuid}/complete`

```json
{ "comment": "Travail terminé et transmis." }
```

Transition autorisée : `EN_COURS` vers `TERMINEE`.

Réponse commune :

```json
{
  "success": true,
  "message": "Tâche démarrée.",
  "data": {
    "task": {
      "uuid": "66666666-6666-4666-8666-666666666666",
      "status": "EN_COURS"
    }
  }
}
```

Une rotation active est obligatoire et la tâche doit appartenir à cette rotation.

## 7. Feedbacks visibles

### `GET /student/feedbacks?type={type}`

Types : `OBSERVATION`, `ENCOURAGEMENT`, `A_AMELIORER`, `AVERTISSEMENT`.

Seuls les feedbacks `PUBLIE`, actifs et visibles par l'étudiant sont retournés. Leur première consultation renseigne `student_seen_at`.

La réponse contient `items` et les statistiques `total`, `encouragements`, `a_ameliorer`, `avertissements`.

## 8. Évaluations visibles

### `GET /student/evaluations?assignment_uuid={uuid}`

Seules les évaluations `VALIDEE` et `FINALISEE` sont exposées.

Chaque évaluation contient :

- `uuid`, `type`, `status`, `note`, `appreciation` ;
- `strengths`, `improvement_areas` ;
- dates de validation/finalisation ;
- scores par compétence (`code`, `nom`, `categorie`, `note`, `note_max`, `poids`, `commentaire`) ;
- rotation, affectation, campagne, hôpital et unité.

La réponse fournit aussi `stats` et `final_evaluation`.

# Partie B — Dossier académique et documentaire

## 9. Profil étudiant

### `GET /student/profile`

Retourne `student` et `current_academic`. Le chemin physique de la photo n'est jamais exposé ; seul `photo_available` est retourné.

## 10. Rattachements universitaires

### `GET /student/enrollments`

Retourne tous les rattachements avec université, matricule, statut et `academic_path_count`.

## 11. Parcours académique

### `GET /student/academic-path?enrollment_id={id}`

`enrollment_id` est obligatoire. La route vérifie qu'il appartient à l'étudiant Bearer.

Réponse : `enrollment`, `current`, `items`, `total`. Chaque parcours contient année académique, promotion, filière/programme, département et faculté.

Erreurs : `422` identifiant absent, `404` rattachement inexistant ou appartenant à un autre compte.

## 12. Notes académiques

### `GET /student/notes?academic_enrollment_id={id}`

Le filtre est facultatif ; sans filtre, le parcours courant/récent est sélectionné.

La réponse contient :

- `academics` : parcours disponibles ;
- `academic` : parcours sélectionné ;
- `subjects` : matières actives ;
- `notes` : évaluations et note normalisée sur 20 ;
- `stats` : moyenne pondérée, nombres de notes, matières et types d'évaluation.

`result` vaut `REUSSI`, `ECHEC` ou `null`.

## 13. Attestations et certificats de stage

### `GET /student/documents`

Retourne les attestations/certificats avec `available`, les informations du stage, puis :

```json
{
  "file_endpoint": "/stagia/api/v1/student/certificates/{uuid}/file",
  "download_endpoint": "/stagia/api/v1/student/certificates/{uuid}/file?download=1",
  "requires_bearer": true,
  "verification_url": "/stagia/verification-attestation.php?token={uuid}"
}
```

`verification_url` est une page publique de vérification. Les fichiers privés exigent toujours le Bearer token.

### `GET /student/certificates/{uuid}/file`

- sans `download=1` : affichage intégré (`inline`) ;
- avec `?download=1` : téléchargement (`attachment`) ;
- réponse binaire `application/pdf` ou, pour le fallback existant, `text/html`.

La route vérifie le propriétaire, le statut `GENERE` et une clôture `VALIDE`.

## 14. Conventions

### `GET /student/conventions`

Liste uniquement les conventions `SIGNEE` ou `ARCHIVEE` possédant un document.

### `GET /student/conventions/{uuid}/file`

Retourne un PDF en mode `inline`, ou `attachment` avec `?download=1`. La convention doit appartenir au compte Bearer.

## 15. Autres documents académiques

### `GET /student/academic-documents`

Liste les documents institutionnels actifs hors conventions, avec `view_endpoint`, `download_endpoint` et `requires_bearer`.

### `GET /student/academic-documents/{id}/file`

Retourne le type MIME enregistré. L'identifiant numérique et l'appartenance au compte sont vérifiés.

## 16. Documents personnels

### `GET /student/personal-documents`

Retourne `items` et `total`. Chaque document contient son UUID, titre, catégorie, nom original, type MIME, extension, taille et endpoints Bearer.

### `POST /student/personal-documents`

Cette route utilise obligatoirement `multipart/form-data`, pas JSON.

| Champ | Type | Obligatoire |
|---|---|---|
| `title` ou `titre` | texte, maximum 180 caractères | oui |
| `category` ou `categorie` | enum | non, défaut `AUTRE` |
| `document` | fichier | oui |

Catégories : `IDENTITE`, `ACADEMIQUE`, `STAGE`, `ADMINISTRATIF`, `AUTRE`.

Formats : PDF, JPG/JPEG, PNG, DOC et DOCX. Taille maximale : 8 Mo. Le serveur contrôle la signature réelle du fichier.

Réponse `201` :

```json
{
  "success": true,
  "message": "Document ajouté avec succès.",
  "data": {
    "document": {
      "id": 15,
      "uuid": "77777777-7777-4777-8777-777777777777",
      "titre": "Carte d'étudiant",
      "categorie": "IDENTITE",
      "nom_original": "carte.pdf",
      "mime_type": "application/pdf",
      "extension": "pdf",
      "taille": 128000,
      "view_endpoint": "/stagia/api/v1/student/personal-documents/77777777-7777-4777-8777-777777777777/file",
      "download_endpoint": "/stagia/api/v1/student/personal-documents/77777777-7777-4777-8777-777777777777/file?download=1",
      "requires_bearer": true
    }
  }
}
```

### `GET /student/personal-documents/{uuid}/file`

Retourne le fichier en mode `inline` ou `attachment` avec `?download=1`.

### `DELETE /student/personal-documents/{uuid}`

`POST` est également accepté pour compatibilité. La suppression est définitive : ligne en base et fichier physique.

```json
{
  "success": true,
  "message": "Document supprimé avec succès.",
  "data": []
}
```

## Téléchargements dans l'application mobile

Les valeurs `file_endpoint`, `view_endpoint` et `download_endpoint` ne sont pas des liens publics. Le client HTTP mobile doit envoyer :

```http
Authorization: Bearer <access_token>
```

Éviter d'ouvrir directement ces URLs dans un navigateur externe ou un composant qui ne transmet pas les en-têtes. Télécharger les octets avec le client HTTP authentifié, puis ouvrir le fichier local temporaire.

Pour les réponses binaires, ne pas tenter de décoder l'enveloppe JSON lorsque le statut est `200`. En revanche, les erreurs `4xx/5xx` sont renvoyées en JSON.

## Ordre d'intégration recommandé

```text
/student/stages
  → choisir assignment_uuid
  → /student/attendance/context
  → pointage, journal, tâches, feedbacks et évaluations

/student/profile
  → /student/enrollments
  → /student/academic-path
  → /student/notes
  → documents, conventions et certificats
  → documents personnels
```

Le fichier OpenAPI associé est `suivi-stage-dossier-academique-mobile.openapi.json`.
