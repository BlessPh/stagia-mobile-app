# API d’authentification mobile STAGIA

Cette documentation couvre l’authentification de l’application mobile. Le compte étudiant est créé et activé depuis l’application Web, puis utilisé par le mobile.

## URL de base

```text
http://<hote>/stagia/api/v1
```

Exemple sous Wamp depuis un téléphone connecté au même réseau :

```text
http://192.168.1.20/stagia/api/v1
```

`localhost` sur le téléphone désigne le téléphone lui-même, pas le PC qui exécute Wamp. En production, utiliser HTTPS.

Pour un test Android en HTTP, la configuration de développement Android doit autoriser temporairement le trafic en clair (`android:usesCleartextTraffic="true"` ou une `network-security-config`). Wamp et le pare-feu Windows doivent aussi autoriser l’accès depuis le réseau local. Ne conserver aucune de ces exceptions HTTP en production.

Dans STAGIA, `APP_BASE_URL` doit normalement valoir `/stagia` lorsque le projet est installé dans `C:\wamp64\www\stagia`.

Toutes les réponses suivent cette enveloppe :

```json
{
  "success": true,
  "message": "Message lisible",
  "data": {}
}
```

En cas d’erreur, `success` vaut `false`. Pour certaines réponses sans données, `data` est un tableau vide `[]`.

## En-têtes

Pour les requêtes JSON :

```http
Content-Type: application/json
Accept: application/json
```

Pour les routes protégées :

```http
Authorization: Bearer <access_token>
```

## Durée et stockage des jetons

- L’`access_token` expire après 3 600 secondes, soit 1 heure.
- Le `refresh_token` expire après 2 592 000 secondes, soit 30 jours.
- Un renouvellement remplace **les deux jetons**. L’ancien access token et l’ancien refresh token deviennent immédiatement invalides.
- Conserver les jetons dans le stockage sécurisé du téléphone, jamais dans un stockage applicatif en clair.
- Le mobile doit sérialiser les demandes de renouvellement : une seule requête `/refresh-token` à la fois, puis rejouer les requêtes qui attendaient.

## 1. Connexion

### `POST /login`

Authentifie un compte déjà créé et activé sur le Web.

Payload :

```json
{
  "identifiant": "STG-ETU-00000030",
  "password": "MotDePasse!2026",
  "device_name": "Samsung Galaxy A54"
}
```

`identifiant` accepte :

- l’identifiant du compte ;
- l’adresse e-mail ;
- le code STAGIA ;
- un nom complet uniquement s’il correspond à un seul compte.

`device_name` est facultatif et vaut `mobile` par défaut.

Réponse `200` :

```json
{
  "success": true,
  "message": "Connexion réussie.",
  "data": {
    "access_token": "<64 caractères hexadécimaux>",
    "refresh_token": "<96 caractères hexadécimaux>",
    "token_type": "Bearer",
    "expires_in": 3600,
    "refresh_expires_in": 2592000,
    "user": {
      "id": 55,
      "identifiant": "etu.mbimbu",
      "nom": "MBIMBU",
      "postnom": "GEMIMA",
      "prenom": "Gemima",
      "email": "etudiant@example.com",
      "actif": true,
      "statut_compte": "ACTIF",
      "role": {
        "code": "STAGIAIRE",
        "nom": "Stagiaire"
      },
      "roles": ["STAGIAIRE"]
    },
    "student": {
      "id": 30,
      "stagia_code": "STG-ETU-00000030",
      "nom": "MBIMBU",
      "postnom": "GEMIMA",
      "prenom": "Gemima",
      "statut": "ACTIF"
    }
  }
}
```

Erreurs principales :

- `401` : identifiant ou mot de passe incorrect ;
- `403` : compte désactivé, suspendu, non activé ou sans rôle actif ;
- `404` : utilisateur devenu introuvable ;
- `422` : champs obligatoires absents ou nom correspondant à plusieurs comptes ;
- `500` : erreur interne.

## 2. Utilisateur courant

### `GET /me`

Retourne l’identité correspondant à l’access token.

```http
Authorization: Bearer <access_token>
```

Réponse `200` :

```json
{
  "success": true,
  "message": "Utilisateur authentifié.",
  "data": {
    "user": {
      "id": 55,
      "identifiant": "etu.mbimbu",
      "nom": "MBIMBU",
      "postnom": "GEMIMA",
      "prenom": "Gemima",
      "email": "etudiant@example.com",
      "actif": true,
      "statut_compte": "ACTIF",
      "role": { "code": "STAGIAIRE", "nom": "Stagiaire" },
      "roles": ["STAGIAIRE"]
    },
    "student": {
      "id": 30,
      "stagia_code": "STG-ETU-00000030",
      "nom": "MBIMBU",
      "postnom": "GEMIMA",
      "prenom": "Gemima",
      "statut": "ACTIF"
    }
  }
}
```

Erreurs principales :

- `401` : token absent, invalide, expiré ou compte désactivé ;
- `403` : le compte ne possède plus d’accès actif ;
- `404` : utilisateur introuvable ;
- `500` : erreur interne.

Le mobile peut appeler `/me` au démarrage pour vérifier une session déjà stockée.

## 3. Renouvellement des jetons

### `POST /refresh-token`

Cette route est publique : elle utilise le refresh token dans le corps et non l’access token.

```json
{
  "refresh_token": "<refresh token courant>"
}
```

Réponse `200` :

```json
{
  "success": true,
  "message": "Token renouvelé.",
  "data": {
    "access_token": "<nouvel access token>",
    "refresh_token": "<nouveau refresh token>",
    "token_type": "Bearer",
    "expires_in": 3600,
    "refresh_expires_in": 2592000
  }
}
```

Remplacer atomiquement les deux jetons stockés avant de rejouer une requête ayant reçu `401`.

Erreurs principales :

- `401` : refresh token invalide ou expiré, compte désactivé ;
- `403` : plus aucun rôle actif ;
- `422` : refresh token absent ;
- `500` : erreur interne.

Après `401` sur `/refresh-token`, supprimer les jetons locaux et afficher l’écran de connexion.

## 4. Déconnexion

### `POST /logout`

Révoque uniquement la session mobile correspondant à l’access token envoyé.

```http
Authorization: Bearer <access_token>
```

Le corps peut être vide. Éviter d’envoyer `Content-Type: application/json` avec un corps JSON invalide.

Réponse `200` :

```json
{
  "success": true,
  "message": "Déconnexion réussie.",
  "data": []
}
```

Après la réponse, supprimer localement l’access token et le refresh token, même si le serveur répond avec une erreur réseau.

Erreurs principales :

- `401` : access token absent, invalide ou expiré ;
- `403` : accès du compte révoqué ;
- `500` : erreur interne.

## 5. Demande de récupération du mot de passe

### `POST /forgot-password`

Payload avec l’identifiant ou l’e-mail :

```json
{
  "identifiant": "etudiant@example.com"
}
```

La clé `email` peut être utilisée à la place de `identifiant`.

Réponse `202` :

```json
{
  "success": true,
  "message": "Si un compte actif correspond à ces informations, un e-mail de réinitialisation sera envoyé.",
  "data": []
}
```

Cette même réponse est renvoyée lorsque le compte n’existe pas, est inactif ou a dépassé la limite, afin d’empêcher l’énumération des comptes.

Limitation actuelle : au maximum 3 demandes enregistrées sur 15 minutes pour un utilisateur. Le lien expire après 60 minutes et invalide les anciens liens non utilisés du même compte.

Erreurs principales :

- `422` : aucun identifiant ni e-mail fourni ;
- `500` : erreur interne.

Le serveur doit définir `MOBILE_PASSWORD_RESET_URL`. L’e-mail ouvre cette URL en lui ajoutant `?token=<token>`.

## 6. Réinitialisation du mot de passe

### `POST /reset-password`

Payload :

```json
{
  "token": "<token hexadécimal de 64 caractères reçu par lien profond>",
  "password": "NouveauMotDePasse!2026",
  "password_confirmation": "NouveauMotDePasse!2026"
}
```

Politique du mot de passe :

- au moins 8 caractères ;
- au moins une majuscule ;
- au moins une minuscule ;
- au moins un chiffre ;
- au moins un caractère spécial.

Réponse `200` :

```json
{
  "success": true,
  "message": "Mot de passe réinitialisé. Vous pouvez maintenant vous connecter.",
  "data": []
}
```

Après une réinitialisation réussie :

- le token de récupération est consommé ;
- les autres tokens de récupération du compte sont invalidés ;
- toutes les sessions mobiles du compte sont révoquées ;
- l’application doit retourner à l’écran de connexion.

Erreurs principales :

- `422` : token invalide/expiré, confirmation différente ou mot de passe trop faible ;
- `500` : erreur interne.

## Gestion recommandée côté mobile

```text
Connexion
  → stocker access_token + refresh_token
  → appeler /me
  → utiliser Authorization: Bearer access_token

Route protégée répond 401
  → verrouiller le renouvellement
  → appeler /refresh-token une seule fois
  → remplacer les deux jetons
  → rejouer la requête initiale une seule fois

/refresh-token répond 401 ou 403
  → supprimer les jetons
  → retourner à la connexion
```

Ne pas lancer plusieurs renouvellements simultanément : comme le refresh token est rotatif, seul le premier réussirait.

## Préparation du serveur de test

Avant les tests, appliquer :

- `2026_09_25_000009_api_refresh_tokens.sql` ;
- `2026_09_25_000010_password_reset_tokens.sql`.

Pour la récupération du mot de passe, configurer également les variables `SMTP_*` et `MOBILE_PASSWORD_RESET_URL`.

Le fichier OpenAPI associé est `authentification-mobile.openapi.json`.
