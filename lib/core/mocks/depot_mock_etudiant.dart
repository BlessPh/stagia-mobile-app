import 'package:flutter/foundation.dart';

// Stockage temporaire en mémoire pendant l'indisponibilité du backend.
// Les données sont conservées jusqu'à la fermeture complète de l'application.
abstract final class DepotMockEtudiant {
  static final ValueNotifier<int> changements = ValueNotifier<int>(0);
  static bool _campagnesConsultees = false;
  static final List<Map<String, dynamic>> _candidatures = [
    {
      'uuid': 'app-candidature-001',
      'statut': 'SOUMISE',
      'motivation': 'Je souhaite perfectionner ma pratique clinique.',
      'motif_refus': null,
      'submitted_at': '2026-09-15 08:30:00',
      'responded_at': null,
      'campaign_code': 'CAM-STAGIA-001',
      'campaign_title': 'Campagne de stages professionnels 2026',
      'campaign_start': '2026-10-01',
      'campaign_end': '2027-01-31',
      'hospital_code': 'ENT-001',
      'hospital_name': 'Cliniques Universitaires de Kinshasa',
      'ville': 'Lemba',
      'province': 'Kinshasa',
      'reservation_uuid': 'STG-RES-84920',
      'reservation_status': 'RESERVEE_TEMPORAIREMENT',
      'expires_at': '2026-09-19 18:30:00',
      'confirmed_at': null,
      'admitted': false,
      'assignment_uuid': null,
      'assignment_status': null,
      'completion_status': null,
      'taux_presence': null,
      'note_finale': null,
      'workflow_status': 'RESERVATION_TEMPORAIRE',
    },
  ];
  static final List<Map<String, dynamic>> _reservations = [
    {
      'uuid': 'STG-RES-84920',
      'statut': 'RESERVEE_TEMPORAIREMENT',
      'expires_at': '2026-09-19 18:30:00',
      'confirmed_at': null,
      'application_uuid': 'app-candidature-001',
      'application_status': 'SOUMISE',
      'campaign_code': 'CAM-STAGIA-001',
      'campaign_title': 'Campagne de stages professionnels 2026',
      'campaign_start': '2026-10-01',
      'campaign_end': '2027-01-31',
      'hospital_code': 'ENT-001',
      'hospital_name': 'Cliniques Universitaires de Kinshasa',
      'ville': 'Lemba',
      'province': 'Kinshasa',
      'frais_requis': false,
      'montant_frais': null,
      'devise': null,
      'admitted': false,
      'assignment_uuid': null,
      'assignment_status': null,
      'completion_status': null,
      'expired': false,
      'workflow_status': 'EN_ATTENTE_VALIDATION',
    },
  ];

  static final List<Map<String, dynamic>> _journal = [
    {
      'uuid': 'journal-001',
      'date': '2026-09-15',
      'created_at': '2026-09-15 14:00:00',
      'status': 'VALIDE',
      'statut': 'VALIDE',
      'learning': 'Observation et aide opératoire sur cure de hernie inguinale',
      'summary':
          'Participation au lavage chirurgical, habillage stérile et aide opératoire lors d’une cure selon Lichtenstein.',
      'difficulties': 'Maintenir l’exposition du champ opératoire sans gêner le chirurgien.',
      'duration': '4',
      'objectives': 'Maîtriser les repères anatomiques de la région inguinale et les temps de l’intervention.',
      'skills': 'Asepsie chirurgicale stricte, tenue des écarteurs de Farabeuf, hémostase.',
      'results': 'Intervention réussie, patient transféré en SSPI sans complication.',
      'campaign': {'code': 'CAM-STAGIA-001', 'title': 'Campagne de stages professionnels 2026'},
      'hospital': {'code': 'ENT-001', 'name': 'Cliniques Universitaires de Kinshasa'},
      'unit': {'code': 'CHIR-01', 'name': 'Service de Chirurgie Générale'},
      'activities': [
        {
          'activity': 'Aide opératoire en hernie inguinale',
          'category': 'CHIRURGIE',
          'involvement_level': 'OBSERVE_ET_AIDE',
          'quantity': 1,
          'observation': 'Validé par Dr. Jean Mukendi.',
        },
      ],
    },
    {
      'uuid': 'journal-002',
      'date': '2026-09-18',
      'created_at': '2026-09-18 11:30:00',
      'status': 'BROUILLON',
      'statut': 'BROUILLON',
      'learning': 'Visite médicale et pansements post-opératoires en salle commune',
      'summary':
          'Évaluation de l’état général de 6 opérés, réfection des pansements chirurgicaux et ablation de deux drains de Redon.',
      'difficulties': 'Désinfection minutieuse d’une plaie exsudative sous anxiété du patient.',
      'duration': '3',
      'objectives': 'Surveiller la cicatrisation et repérer d’éventuels signes d’infection nosocomiale.',
      'skills': 'Asepsie cutanée, retrait de drains aspiratifs, relation soignant-patient.',
      'results': 'Toutes les plaies propres, constantes stables pour l’ensemble des patients.',
      'campaign': {'code': 'CAM-STAGIA-001', 'title': 'Campagne de stages professionnels 2026'},
      'hospital': {'code': 'ENT-001', 'name': 'Cliniques Universitaires de Kinshasa'},
      'unit': {'code': 'CHIR-01', 'name': 'Service de Chirurgie Générale'},
      'activities': [
        {
          'activity': 'Réfection de pansements et ablation de drains',
          'category': 'SOINS',
          'involvement_level': 'REALISE',
          'quantity': 6,
          'observation': 'Sous la supervision de l’interne de garde.',
        },
      ],
    },
  ];

  static List<Map<String, dynamic>> get candidatures =>
      _candidatures.map(Map<String, dynamic>.from).toList();

  static List<Map<String, dynamic>> get reservations =>
      _reservations.map(Map<String, dynamic>.from).toList();

  static List<Map<String, dynamic>> get journal =>
      _journal.map(Map<String, dynamic>.from).toList();

  static bool get campagnesConsultees => _campagnesConsultees;

  static void marquerCampagnesConsultees() {
    if (_campagnesConsultees) return;
    _campagnesConsultees = true;
    changements.value++;
  }

  static List<Map<String, dynamic>> get documents => _candidatures
      .where((candidature) => candidature['document_name'] != null)
      .map(
        (candidature) => <String, dynamic>{
          'uuid': 'document-${candidature['uuid']}',
          'reference': candidature['document_name'],
          'type_document': _extensionDocument(candidature['document_name']),
          'status': 'DISPONIBLE',
          'local_path': candidature['document_path'],
        },
      )
      .toList();

  static bool candidatureEnvoyeePour(String cleOption) =>
      cleOption.isNotEmpty &&
      _candidatures.any(
        (candidature) =>
            candidature['option_key'] == cleOption ||
            (candidature['campaign_id'] != null &&
                candidature['hospital_code'] != null &&
                '${candidature['campaign_id']}::${candidature['hospital_code']}' == cleOption),
      );

  static Map<String, dynamic> ajouterReservation({
    required int campaignId,
    required int academicEnrollmentId,
    required int participationId,
    String? motivation,
    String? cleOption,
    String? campagneTitre,
    String? etablissementNom,
    String? localisation,
  }) {
    final now = DateTime.now();
    final expiration = now.add(const Duration(minutes: 30));
    final expirationStr =
        '${expiration.year.toString().padLeft(4, '0')}-${expiration.month.toString().padLeft(2, '0')}-${expiration.day.toString().padLeft(2, '0')} ${expiration.hour.toString().padLeft(2, '0')}:${expiration.minute.toString().padLeft(2, '0')}:${expiration.second.toString().padLeft(2, '0')}';
    final submittedAtStr =
        '${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')} ${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}';
    final resUuid = 'STG-RES-${now.millisecondsSinceEpoch % 100000}';
    final appUuid = 'app-${now.millisecondsSinceEpoch}';
    final campCode = 'CAM-STAGIA-${campaignId.toString().padLeft(3, '0')}';
    final hospCode = 'ENT-${participationId.toString().padLeft(3, '0')}';

    final candidature = <String, dynamic>{
      'uuid': appUuid,
      'campaign_id': campaignId.toString(),
      'option_key': cleOption ?? '$campaignId::$participationId',
      'statut': 'SOUMISE',
      'submitted_at': submittedAtStr,
      'responded_at': null,
      'campaign_code': campCode,
      'campaign_title':
          campagneTitre ?? 'Campagne de stages professionnels 2026',
      'campaign_start': '2026-10-01',
      'campaign_end': '2027-01-31',
      'hospital_code': hospCode,
      'hospital_name': etablissementNom ?? 'Établissement $participationId',
      'ville': localisation ?? 'Kinshasa',
      'province': 'Kinshasa',
      'reservation_uuid': resUuid,
      'reservation_status': 'RESERVEE_TEMPORAIREMENT',
      'expires_at': expirationStr,
      'confirmed_at': null,
      'admitted': false,
      'assignment_uuid': null,
      'assignment_status': null,
      'completion_status': null,
      'taux_presence': null,
      'note_finale': null,
      'motivation': motivation ?? '',
      'workflow_status': 'RESERVATION_TEMPORAIRE',
    };

    final reservation = <String, dynamic>{
      'uuid': resUuid,
      'statut': 'RESERVEE_TEMPORAIREMENT',
      'expires_at': expirationStr,
      'confirmed_at': null,
      'application_uuid': appUuid,
      'application_status': 'SOUMISE',
      'campaign_code': campCode,
      'campaign_title': candidature['campaign_title'],
      'campaign_start': '2026-10-01',
      'campaign_end': '2027-01-31',
      'hospital_code': hospCode,
      'hospital_name': candidature['hospital_name'],
      'ville': candidature['ville'],
      'province': 'Kinshasa',
      'frais_requis': false,
      'montant_frais': null,
      'devise': null,
      'admitted': false,
      'assignment_uuid': null,
      'assignment_status': null,
      'completion_status': null,
      'expired': false,
      'workflow_status': 'EN_ATTENTE_VALIDATION',
    };

    _candidatures.insert(0, candidature);
    _reservations.insert(0, reservation);
    changements.value++;

    return {
      'success': true,
      'message': 'Réservation créée avec succès.',
      'data': {
        'application_uuid': appUuid,
        'reservation_uuid': resUuid,
        'reservation_status': 'RESERVEE_TEMPORAIREMENT',
        'expires_at': expirationStr,
        'reservation_duration_minutes': 30,
        'hospital': {
          'id': participationId,
          'code': hospCode,
          'name': candidature['hospital_name'],
        },
        'fees': {
          'required': false,
          'amount': null,
          'currency': null,
        },
        'frais_requis': false,
        'montant_frais': null,
        'devise': null,
        'places_remaining': 4,
      },
    };
  }

  static Map<String, dynamic> ajouterCandidature({
    required String cleOption,
    required String campagneId,
    required String campagne,
    required String etablissement,
    required String localisation,
    required String motivation,
    String? document,
    String? cheminDocument,
  }) {
    final now = DateTime.now();
    final dateStr =
        '${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')} ${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}';
    final appUuid = 'candidature-locale-${now.millisecondsSinceEpoch}';
    final resUuid = 'STG-RES-${now.millisecondsSinceEpoch % 100000}';
    final expiration = now.add(const Duration(minutes: 30));
    final expirationStr =
        '${expiration.year.toString().padLeft(4, '0')}-${expiration.month.toString().padLeft(2, '0')}-${expiration.day.toString().padLeft(2, '0')} ${expiration.hour.toString().padLeft(2, '0')}:${expiration.minute.toString().padLeft(2, '0')}:${expiration.second.toString().padLeft(2, '0')}';

    final candidature = <String, dynamic>{
      'uuid': appUuid,
      'campaign_id': campagneId,
      'option_key': cleOption,
      'statut': 'SOUMISE',
      'submitted_at': dateStr,
      'responded_at': null,
      'campaign_code': 'CAM-STAGIA-001',
      'campaign_title': campagne,
      'campaign_start': '2026-10-01',
      'campaign_end': '2027-01-31',
      'hospital_code': 'ENT-001',
      'hospital_name': etablissement,
      'ville': localisation,
      'province': 'Kinshasa',
      'reservation_uuid': resUuid,
      'reservation_status': 'RESERVEE_TEMPORAIREMENT',
      'expires_at': expirationStr,
      'confirmed_at': null,
      'admitted': false,
      'assignment_uuid': null,
      'assignment_status': null,
      'completion_status': null,
      'taux_presence': null,
      'note_finale': null,
      'motivation': motivation,
      'workflow_status': 'RESERVATION_TEMPORAIRE',
      'document_name': document,
      'document_path': cheminDocument,
    };
    _candidatures.insert(0, candidature);
    changements.value++;
    return Map<String, dynamic>.from(candidature);
  }

  static void ajouterActivite({
    required String titre,
    required String description,
    required String difficulte,
    required String date,
    required String categorie,
    required String duree,
    required String service,
    required String objectifs,
    required String competences,
    required String resultats,
  }) {
    _journal.insert(0, <String, dynamic>{
      'uuid': 'journal-local-${DateTime.now().millisecondsSinceEpoch}',
      'date': date,
      'created_at': DateTime.now().toIso8601String(),
      'status': 'BROUILLON',
      'summary': description,
      'learning': titre,
      'difficulties': difficulte,
      'duration': duree,
      'objectives': objectifs,
      'skills': competences,
      'results': resultats,
      'campaign': {'title': 'Stage professionnel 2026-2027'},
      'hospital': {'name': 'Cliniques Universitaires de Kinshasa'},
      'unit': {'name': service},
      'activities': [
        {'category': categorie, 'involvement_level': 'REALISE', 'quantity': 1},
      ],
    });
  }

  static void modifierActivite(
    String uuid, {
    required String titre,
    required String description,
    required String difficulte,
    required String date,
    required String categorie,
    required String duree,
    required String service,
    required String objectifs,
    required String competences,
    required String resultats,
  }) {
    final index = _journal.indexWhere((element) => element['uuid'] == uuid);
    if (index < 0 || _journal[index]['status'] != 'BROUILLON') return;
    _journal[index] = {
      ..._journal[index],
      'date': date,
      'summary': description,
      'learning': titre,
      'difficulties': difficulte,
      'duration': duree,
      'objectives': objectifs,
      'skills': competences,
      'results': resultats,
      'unit': {'name': service},
      'activities': [
        {'category': categorie, 'involvement_level': 'REALISE', 'quantity': 1},
      ],
    };
  }

  static void supprimerActivite(String uuid) {
    _journal.removeWhere(
      (element) => element['uuid'] == uuid && element['status'] == 'BROUILLON',
    );
  }

  static void soumettreActivite(String uuid) {
    final index = _journal.indexWhere((element) => element['uuid'] == uuid);
    if (index >= 0 && _journal[index]['status'] == 'BROUILLON') {
      _journal[index]['status'] = 'SOUMIS';
    }
  }

  // --- Tâche 8 : Communication, Notifications, Messagerie, Calendrier ---
  static final List<Map<String, dynamic>> _notifications = [
    {
      'sequence': 1,
      'id': '01JQ0G8K9M5H2T7B4P6S3N1R81',
      'event_type': 'stage.assignment.updated',
      'type': 'internship',
      'subject': 'Affectation de stage confirmée',
      'description':
          'Vous avez été affecté au service de Chirurgie Viscérale à l’Hôpital Général Provincial.',
      'priority': 'haute',
      'read_at': null,
      'archived_at': null,
      'created_at': DateTime.now()
          .subtract(const Duration(minutes: 15))
          .toIso8601String(),
      'action': {
        'type': 'internship_assignment',
        'target_id': '01JQ0ASSIGNMENT00000000001',
        'label': 'Voir mon affectation',
        'title': 'Chirurgie Viscérale',
        'metadata': {'service': 'Chirurgie'},
      },
    },
    {
      'sequence': 2,
      'id': '01JQ0G8K9M5H2T7B4P6S3N1R82',
      'event_type': 'message.created',
      'type': 'message',
      'subject': 'Nouveau message d’encadrement',
      'description':
          'Dr. Patrick Mwamba vous a envoyé les observations cliniques concernant votre patiente de la chambre 204.',
      'priority': 'normale',
      'read_at': null,
      'archived_at': null,
      'created_at': DateTime.now()
          .subtract(const Duration(hours: 2, minutes: 10))
          .toIso8601String(),
      'action': {
        'type': 'conversation',
        'target_id': '01JQ0CONVERSATION000000001',
        'label': 'Ouvrir la discussion',
        'title': 'Dr. Patrick Mwamba',
        'metadata': {'contact_name': 'Dr. Patrick Mwamba'},
      },
    },
    {
      'sequence': 3,
      'id': '01JQ0G8K9M5H2T7B4P6S3N1R83',
      'event_type': 'campaign.opened',
      'type': 'internship',
      'subject': 'Campagne de stages ouverte',
      'description':
          'La campagne officielle des stages hospitaliers pour votre promotion est désormais accessible.',
      'priority': 'normale',
      'read_at': null,
      'archived_at': null,
      'created_at': DateTime.now()
          .subtract(const Duration(hours: 5, minutes: 45))
          .toIso8601String(),
      'action': {
        'type': 'campaign',
        'target_id': '01JQ0CAMPAIGN0000000000001',
        'label': 'Explorer les hôpitaux',
        'title': 'Campagne 2026',
        'metadata': {},
      },
    },
    {
      'sequence': 4,
      'id': '01JQ0G8K9M5H2T7B4P6S3N1R84',
      'event_type': 'logbook.entry.validated',
      'type': 'logbook',
      'subject': 'Rapport de stage validé',
      'description':
          'Votre rapport hebdomadaire d’activités cliniques a été évalué et validé avec mention "Très bien".',
      'priority': 'basse',
      'read_at': DateTime.now()
          .subtract(const Duration(hours: 12))
          .toIso8601String(),
      'archived_at': null,
      'created_at': DateTime.now()
          .subtract(const Duration(days: 1, hours: 3))
          .toIso8601String(),
      'action': {
        'type': 'logbook',
        'target_id': '01JQ0LOGBOOK00000000000001',
        'label': 'Consulter le rapport',
        'title': 'Journal clinique',
        'metadata': {},
      },
    },
    {
      'sequence': 5,
      'id': '01JQ0G8K9M5H2T7B4P6S3N1R85',
      'event_type': 'calendar.reminder',
      'type': 'urgent',
      'subject': 'Rappel de garde clinique',
      'description':
          'Votre tour de garde au service des Urgences commence demain à 08h00. Veuillez vous présenter auprès du chef de garde.',
      'priority': 'urgente',
      'read_at': null,
      'archived_at': null,
      'created_at':
          DateTime.now().subtract(const Duration(days: 2)).toIso8601String(),
      'action': {
        'type': 'calendar_event',
        'target_id': '01JQ0CALENDAR0000000000001',
        'label': 'Voir les consignes',
        'title': 'Garde Urgences',
        'metadata': {},
      },
    },
  ];

  static List<Map<String, dynamic>> get notifications =>
      _notifications.where((n) => n['archived_at'] == null).toList();

  static Map<String, dynamic> get notificationCounts {
    final unreadNotifs =
        _notifications.where((n) => n['read_at'] == null && n['archived_at'] == null).length;
    final unreadMsgs = _conversations.fold<int>(
        0, (acc, c) => acc + (int.tryParse(c['unread_count']?.toString() ?? '0') ?? 0));
    final unreadComms =
        _communications.where((c) => c['read_at'] == null).length;
    return {
      'notifications': unreadNotifs,
      'messages': unreadMsgs,
      'communications': unreadComms,
      'total': unreadNotifs + unreadMsgs + unreadComms,
    };
  }

  static void marquerNotificationLue(String uuid) {
    final idx = _notifications.indexWhere((n) => n['id'] == uuid);
    if (idx >= 0) {
      _notifications[idx]['read_at'] = DateTime.now().toIso8601String();
    }
  }

  static void archiverNotification(String uuid) {
    final idx = _notifications.indexWhere((n) => n['id'] == uuid);
    if (idx >= 0) {
      _notifications[idx]['archived_at'] = DateTime.now().toIso8601String();
    }
  }

  static final List<Map<String, dynamic>> _contacts = [
    {
      'id': 101,
      'identifiant': 'DR-MWAMBA-01',
      'display_name': 'Dr. Patrick Mwamba',
      'email': 'patrick.mwamba@hopital-general.cd',
      'organisation': 'Hôpital Général Provincial',
      'organisation_id': 1,
      'is_student': false,
    },
    {
      'id': 102,
      'identifiant': 'DR-LUKUSA-02',
      'display_name': 'Dr. Sarah Lukusa',
      'email': 'sarah.lukusa@univ-cliniques.cd',
      'organisation': 'Cliniques Universitaires',
      'organisation_id': 2,
      'is_student': false,
    },
    {
      'id': 103,
      'identifiant': 'INF-LUCIE-03',
      'display_name': 'Inf. Major Lucie',
      'email': 'lucie.inf@hopital-general.cd',
      'organisation': 'Hôpital Général Provincial',
      'organisation_id': 1,
      'is_student': false,
    },
    {
      'id': 201,
      'identifiant': 'ADMIN-DECANAT-01',
      'display_name': 'Décanat Médecine - Bureau des Stages',
      'email': 'stages@fac-medecine.cd',
      'organisation': 'Faculté de Médecine',
      'organisation_id': 99,
      'is_student': false,
    },
  ];

  static List<Map<String, dynamic>> get contacts => List.unmodifiable(_contacts);

  static final List<Map<String, dynamic>> _conversations = [
    {
      'uuid': '01JQ0CONVERSATION000000001',
      'objet': 'Dr. Patrick Mwamba',
      'type_conversation': 'privee',
      'statut': 'active',
      'cree_le': DateTime.now().subtract(const Duration(days: 5)).toIso8601String(),
      'participant_count': 2,
      'last_message': 'Bien reçu ! Bon travail pour cette garde.',
      'last_activity_at': DateTime.now().subtract(const Duration(minutes: 8)).toIso8601String(),
      'unread_count': 2,
      'draft': null,
      'role_ou_service': 'Chirurgien Chef · Hôpital Général',
      'est_en_ligne': true,
      'est_epingle': true,
      'dernier_message_est_mien': false,
    },
    {
      'uuid': '01JQ0CONVERSATION000000002',
      'objet': 'Équipe Garde Urgences A',
      'type_conversation': 'groupe',
      'statut': 'active',
      'cree_le': DateTime.now().subtract(const Duration(days: 10)).toIso8601String(),
      'participant_count': 7,
      'last_message': 'Relève effectuée pour le box 3, cas stabilisé.',
      'last_activity_at': DateTime.now().subtract(const Duration(minutes: 34)).toIso8601String(),
      'unread_count': 4,
      'draft': null,
      'role_ou_service': '5 stagiaires · 2 superviseurs',
      'est_en_ligne': false,
      'est_epingle': false,
      'dernier_message_est_mien': false,
    },
    {
      'uuid': '01JQ0CONVERSATION000000003',
      'objet': 'Diffusion Décanat Santé',
      'type_conversation': 'institutionnelle',
      'statut': 'active',
      'cree_le': DateTime.now().subtract(const Duration(days: 20)).toIso8601String(),
      'participant_count': 120,
      'last_message': 'Note de service : Validation semestrielle des stages cliniques.',
      'last_activity_at': DateTime.now().subtract(const Duration(hours: 3)).toIso8601String(),
      'unread_count': 1,
      'draft': null,
      'role_ou_service': 'Canal Officiel de Diffusion',
      'est_en_ligne': false,
      'est_epingle': true,
      'dernier_message_est_mien': false,
    },
    {
      'uuid': '01JQ0CONVERSATION000000004',
      'objet': 'Dr. Sarah Lukusa',
      'type_conversation': 'privee',
      'statut': 'active',
      'cree_le': DateTime.now().subtract(const Duration(days: 12)).toIso8601String(),
      'participant_count': 2,
      'last_message': 'Merci pour le compte-rendu, validation transmise.',
      'last_activity_at': DateTime.now().subtract(const Duration(hours: 6)).toIso8601String(),
      'unread_count': 0,
      'draft': null,
      'role_ou_service': 'Pédiatre Superviseur · Cliniques Univ.',
      'est_en_ligne': false,
      'est_epingle': false,
      'dernier_message_est_mien': true,
    },
  ];

  static List<Map<String, dynamic>> get conversations => _conversations;

  static final Map<String, List<Map<String, dynamic>>> _messagesParConversation = {
    '01JQ0CONVERSATION000000001': [
      {
        'id': 1,
        'uuid': '01JQ0MSG000000000000000001',
        'contenu':
            'Bonjour Alfred, as-tu pu vérifier la radio thoracique post-opératoire de la patiente du lit 14 ?',
        'cree_le': DateTime.now()
            .subtract(const Duration(hours: 2, minutes: 20))
            .toIso8601String(),
        'modifie_le': null,
        'statut': 'envoye',
        'author': 'Dr. Patrick Mwamba',
        'author_user_id': 101,
        'is_mine': false,
        'read_by_count': 1,
        'attachments': [],
      },
      {
        'id': 2,
        'uuid': '01JQ0MSG000000000000000002',
        'contenu':
            'Bonjour Docteur ! Oui, je viens de passer dans le service. L’épanchement s’est bien résorbé, aucune complication visible.',
        'cree_le': DateTime.now()
            .subtract(const Duration(hours: 2, minutes: 12))
            .toIso8601String(),
        'modifie_le': null,
        'statut': 'envoye',
        'author': 'Alfred KALONJI',
        'author_user_id': 999,
        'is_mine': true,
        'read_by_count': 1,
        'attachments': [],
      },
      {
        'id': 3,
        'uuid': '01JQ0MSG000000000000000003',
        'contenu': 'Bien reçu ! Bon travail pour cette garde.',
        'cree_le': DateTime.now()
            .subtract(const Duration(minutes: 8))
            .toIso8601String(),
        'modifie_le': null,
        'statut': 'envoye',
        'author': 'Dr. Patrick Mwamba',
        'author_user_id': 101,
        'is_mine': false,
        'read_by_count': 0,
        'attachments': [],
      },
    ],
  };

  static List<Map<String, dynamic>> messagesDeConversation(String convUuid) {
    return _messagesParConversation[convUuid] ??
        [
          {
            'id': 1,
            'uuid': '01JQ0MSG000000000000000099',
            'contenu': 'Bienvenue dans la conversation.',
            'cree_le': DateTime.now().subtract(const Duration(minutes: 10)).toIso8601String(),
            'statut': 'envoye',
            'author': 'Système',
            'author_user_id': 1,
            'is_mine': false,
            'read_by_count': 1,
            'attachments': [],
          }
        ];
  }

  static void ajouterMessage({
    required String conversationUuid,
    required String contenu,
    String? nomFichier,
    int? tailleBytes,
  }) {
    final liste = _messagesParConversation.putIfAbsent(
        conversationUuid, () => <Map<String, dynamic>>[]);
    final nouveauId = liste.length + 1;
    final attachments = <Map<String, dynamic>>[];
    if (nomFichier != null) {
      attachments.add({
        'uuid': '01JQ0FILE${DateTime.now().millisecondsSinceEpoch}',
        'name': nomFichier,
        'mime_type': 'application/pdf',
        'size': tailleBytes ?? 150000,
        'view_endpoint': '/attachments/view',
        'download_endpoint': '/attachments/download',
        'requires_bearer': true,
      });
    }

    final nouveau = {
      'id': nouveauId,
      'uuid': '01JQ0MSG${DateTime.now().millisecondsSinceEpoch}',
      'contenu': contenu,
      'cree_le': DateTime.now().toIso8601String(),
      'modifie_le': null,
      'statut': 'envoye',
      'author': 'Alfred KALONJI',
      'author_user_id': 999,
      'is_mine': true,
      'read_by_count': 0,
      'attachments': attachments,
    };
    liste.add(nouveau);

    // Mettre à jour la conversation
    final idxConv = _conversations.indexWhere((c) => c['uuid'] == conversationUuid);
    if (idxConv >= 0) {
      _conversations[idxConv]['last_message'] = contenu.isNotEmpty ? contenu : nomFichier;
      _conversations[idxConv]['last_activity_at'] = DateTime.now().toIso8601String();
      _conversations[idxConv]['dernier_message_est_mien'] = true;
    }
  }

  static final List<Map<String, dynamic>> _communications = [
    {
      'uuid': '01JQ0COMM000000000000000001',
      'reference': 'DEC-2026-N038',
      'type': 'circulaire',
      'subject': 'Protocole sanitaire et calendrier des évaluations cliniques',
      'content':
          'Chers étudiants stagiaires,\n\nVeuillez noter que les évaluations cliniques débuteront le 25 du mois courant. Assurez-vous d\'avoir complété votre carnet de stage et validé toutes vos présences.\n\nLe Décanat.',
      'priority': 'haute',
      'acknowledgement_required': true,
      'acknowledgement_due_at': DateTime.now().add(const Duration(days: 7)).toIso8601String(),
      'published_at': DateTime.now().subtract(const Duration(days: 3)).toIso8601String(),
      'sender': 'Décanat Médecine - Bureau Académique',
      'read_at': null,
      'acknowledged_at': null,
    },
    {
      'uuid': '01JQ0COMM000000000000000002',
      'reference': 'HOP-2026-N012',
      'type': 'note_service',
      'subject': 'Port obligatoire des équipements de protection individuelle',
      'content':
          'Rappel à tous les étudiants affectés au bloc opératoire et aux urgences : le port du masque et des gants stériles est rigoureusement contrôlé.',
      'priority': 'urgente',
      'acknowledgement_required': false,
      'acknowledgement_due_at': null,
      'published_at': DateTime.now().subtract(const Duration(days: 1)).toIso8601String(),
      'sender': 'Direction Médicale Hôpital Général',
      'read_at': DateTime.now().subtract(const Duration(hours: 4)).toIso8601String(),
      'acknowledged_at': null,
    },
  ];

  static List<Map<String, dynamic>> get communications => _communications;

  static void marquerCommunicationLue(String uuid) {
    final idx = _communications.indexWhere((c) => c['uuid'] == uuid);
    if (idx >= 0) {
      _communications[idx]['read_at'] = DateTime.now().toIso8601String();
      if (_communications[idx]['acknowledgement_required'] == true) {
        _communications[idx]['acknowledged_at'] = DateTime.now().toIso8601String();
      }
    }
  }

  static final List<Map<String, dynamic>> _calendrier = [
    {
      'uuid': '01JQ0CAL000000000000000001',
      'title': 'Effectuer une lectomie',
      'description':
          'Consignes de stérilisation, préparation du champ opératoire et assistance directe sous la supervision de Ngoy Jean.',
      'type': 'reunion',
      'starts_at': DateTime(2026, 9, 16, 10, 0).toIso8601String(),
      'ends_at': DateTime(2026, 9, 16, 10, 30).toIso8601String(),
      'location': 'Bloc opératoire B, Aile Chirurgicale',
      'external_url': null,
      'status': 'confirme',
      'creator_user_id': 101,
      'response_status': 'accepte',
      'responded_at': DateTime(2026, 9, 15, 8, 0).toIso8601String(),
      'meeting_provider': null,
      'meeting_code': null,
      'service': 'Chirurgie',
      'departement': 'Soins intensifs',
      'superviseur': 'Ngoy Jean',
      'note_rappel':
          'Vérifier le dossier médical préopératoire, s\'assurer du bilan d\'hémostase.',
    },
    {
      'uuid': '01JQ0CAL000000000000000002',
      'title': 'Visite des patients post-opératoires',
      'description':
          'Contrôle des pansements, relevé des constantes vitales et vérification des drainages.',
      'type': 'visite',
      'starts_at': DateTime(2026, 9, 16, 14, 0).toIso8601String(),
      'ends_at': DateTime(2026, 9, 16, 15, 30).toIso8601String(),
      'location': 'Aile Ouest - Chambres 201-210',
      'external_url': null,
      'status': 'planifie',
      'creator_user_id': 101,
      'response_status': 'accepte',
      'responded_at': DateTime(2026, 9, 15, 9, 0).toIso8601String(),
      'meeting_provider': null,
      'meeting_code': null,
      'service': 'Chirurgie',
      'departement': 'Soins intensifs',
      'superviseur': 'Ngoy Jean',
      'note_rappel': 'Consigner les constantes sur la fiche de transmission.',
    },
    {
      'uuid': '01JQ0CAL000000000000000003',
      'title': 'Cours de Mathématiques et Statistiques Cliniques',
      'description':
          'Introduction aux modèles statistiques appliqués aux études épidémiologiques hospitalières.',
      'type': 'autre',
      'starts_at': DateTime(2026, 9, 10, 9, 0).toIso8601String(),
      'ends_at': DateTime(2026, 9, 10, 10, 30).toIso8601String(),
      'location': 'Salle B204, Bâtiment Principal',
      'external_url': null,
      'status': 'confirme',
      'creator_user_id': 201,
      'response_status': 'accepte',
      'responded_at': DateTime(2026, 9, 8, 12, 0).toIso8601String(),
      'meeting_provider': null,
      'meeting_code': null,
      'service': 'Académique',
      'departement': 'Bâtiment Principal',
      'superviseur': 'Prof. Mukendi',
      'note_rappel': 'Apporter le polycopié de cours imprimé.',
    },
    {
      'uuid': '01JQ0CAL000000000000000004',
      'title': 'Évaluation formative clinique',
      'description': 'Évaluation de mi-parcours sur les gestes d\'urgence.',
      'type': 'evaluation',
      'starts_at': DateTime(2026, 9, 25, 14, 0).toIso8601String(),
      'ends_at': DateTime(2026, 9, 25, 16, 30).toIso8601String(),
      'location': 'Salle de simulation',
      'external_url': null,
      'status': 'planifie',
      'creator_user_id': 101,
      'response_status': 'invite',
      'responded_at': null,
      'meeting_provider': null,
      'meeting_code': null,
      'service': 'Chirurgie',
      'departement': 'Soins intensifs',
      'superviseur': 'Ngoy Jean',
      'note_rappel': 'Réviser les gestes de réanimation cardio-pulmonaire.',
    },
  ];

  static List<Map<String, dynamic>> get calendrier => _calendrier;

  static void repondreInvitationCalendrier(String uuid, String reponse) {
    final idx = _calendrier.indexWhere((e) => e['uuid'] == uuid);
    if (idx >= 0) {
      _calendrier[idx]['response_status'] = reponse;
      _calendrier[idx]['responded_at'] = DateTime.now().toIso8601String();
    }
  }

  static void ajouterEvenementCalendrier(Map<String, dynamic> evt) {
    _calendrier.add(evt);
  }
}

String _extensionDocument(Object? nom) {
  final valeur = nom?.toString() ?? '';
  final morceaux = valeur.split('.');
  return morceaux.length > 1 ? morceaux.last.toUpperCase() : 'DOCUMENT';
}

