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
}

String _extensionDocument(Object? nom) {
  final valeur = nom?.toString() ?? '';
  final morceaux = valeur.split('.');
  return morceaux.length > 1 ? morceaux.last.toUpperCase() : 'DOCUMENT';
}
