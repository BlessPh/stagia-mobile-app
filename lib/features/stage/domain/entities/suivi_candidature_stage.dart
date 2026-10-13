import 'campagne_stage.dart';

class SuiviCandidatureStage {
  const SuiviCandidatureStage({
    required this.campagne,
    required this.statut,
    required this.libelleStatut,
    required this.message,
    required this.nomHopital,
    required this.estTermine,
    this.reservationUuid,
    this.reservationStatus,
    this.applicationStatus,
    this.canCancel = false,
    this.cancelEndpoint,
    this.placementExists = false,
    this.placementStatus,
    this.admissionExists = false,
    this.admissionUuid,
    this.admissionStatus,
    this.assignmentExists = false,
    this.assignmentUuid,
    this.assignmentStatus,
    this.workflowMessage,
  });

  final CampagneStage campagne;
  final String statut;
  final String libelleStatut;
  final String message;
  final String nomHopital;
  final bool estTermine;
  final String? reservationUuid;
  final String? reservationStatus;
  final String? applicationStatus;
  final bool canCancel;
  final String? cancelEndpoint;
  final bool placementExists;
  final String? placementStatus;
  final bool admissionExists;
  final String? admissionUuid;
  final String? admissionStatus;
  final bool assignmentExists;
  final String? assignmentUuid;
  final String? assignmentStatus;
  final String? workflowMessage;

  factory SuiviCandidatureStage.depuisAdmission(Map<String, dynamic> json) {
    final campagneApi = _map(json['campaign']);
    final hopital = _map(json['hospital']);
    final reservation = _map(json['reservation']);
    final statut = json['workflow_status']?.toString().toUpperCase() ?? '';
    final debut = campagneApi['start_date']?.toString() ?? '';
    final fin = campagneApi['end_date']?.toString() ?? '';
    final code = (campagneApi['code'] ?? json['campaign_code'])?.toString() ?? '';
    final nomHopital = (hopital['name'] ?? json['hospital_name'])?.toString() ?? '';
    final messageApi = (json['workflow_message'] ?? _map(json['workflow'])['message'])?.toString().trim() ?? '';
    final actions = _map(json['actions']);
    final cancelAction = _map(actions['cancel']);

    final placement = _map(json['placement']);
    final admission = _map(json['admission']);
    final assignment = _map(json['assignment']);

    return SuiviCandidatureStage(
      campagne: CampagneStage(
        id: code,
        code: code,
        titre: (campagneApi['title'] ?? json['campaign_title'])?.toString() ?? 'Candidature de stage',
        sousTitre: nomHopital,
        dateDebut: debut,
        dateFin: fin,
        periodeTexte: debut.isNotEmpty && fin.isNotEmpty
            ? '$debut - $fin'
            : 'Dates à confirmer',
        indemnite: '',
        modalite: '',
        statut: libellePour(statut),
        nombreHopitaux: nomHopital.isEmpty ? 0 : 1,
        estEligible: true,
        messageEligibilite: messageApi,
        consignes: const [],
        criteresEligibilite: const [],
        hopitaux: const [],
      ),
      statut: statut,
      libelleStatut: libellePour(statut),
      message: messageApi.isNotEmpty
          ? messageApi
          : 'Votre candidature est en cours de traitement.',
      nomHopital: nomHopital,
      estTermine: statutsTermines.contains(statut),
      reservationUuid: (reservation['uuid'] ?? json['reservation_uuid'])?.toString(),
      reservationStatus: (reservation['status'] ?? json['reservation_status'])?.toString(),
      applicationStatus: json['application_status']?.toString(),
      canCancel: cancelAction['allowed'] == true,
      cancelEndpoint: cancelAction['endpoint']?.toString(),
      placementExists: placement['exists'] == true,
      placementStatus: placement['status']?.toString(),
      admissionExists: admission['exists'] == true,
      admissionUuid: admission['uuid']?.toString() ?? json['admission_uuid']?.toString(),
      admissionStatus: admission['status']?.toString(),
      assignmentExists: assignment['exists'] == true,
      assignmentUuid: assignment['uuid']?.toString() ?? json['assignment_uuid']?.toString(),
      assignmentStatus: assignment['status']?.toString(),
      workflowMessage: messageApi,
    );
  }

  factory SuiviCandidatureStage.depuisCandidature(
    Map<String, dynamic> json,
    CampagneStage campagne,
  ) {
    final statut =
        (json['workflow_status'] ??
                _map(json['workflow'])['status'] ??
                json['statut'] ??
                json['application_status'] ??
                json['status'])
            ?.toString()
            .toUpperCase() ??
        '';
    final nomHopital =
        (json['hospital_name'] ??
                _map(json['hospital'])['name'] ??
                json['entreprise'])
            ?.toString() ??
        '';
    final message = (json['workflow_message'] ??
            _map(json['workflow'])['message'])
        ?.toString()
        .trim() ??
        '';
    final libelle = libellePour(statut);
    final resUuid = (json['reservation_uuid'] ??
            _map(json['reservation'])['uuid'] ??
            json['uuid'])
        ?.toString();
    final resStatus = (json['reservation_status'] ??
            _map(json['reservation'])['status'])
        ?.toString();
    final appStatus = (json['application_status'] ??
            _map(json['application'])['status'] ??
            json['statut'])
        ?.toString();
    final actions = _map(json['actions']);
    final cancelAction = _map(actions['cancel']);
    final placement = _map(json['placement']);
    final admission = _map(json['admission']);
    final assignment = _map(json['assignment']);

    return SuiviCandidatureStage(
      campagne: campagne.avecStatut(libelle),
      statut: statut,
      libelleStatut: libelle,
      message: message.isNotEmpty
          ? message
          : 'Votre candidature a bien été enregistrée.',
      nomHopital: nomHopital,
      estTermine: statutsTermines.contains(statut),
      reservationUuid: resUuid,
      reservationStatus: resStatus,
      applicationStatus: appStatus,
      canCancel: cancelAction['allowed'] == true ||
          (resStatus == 'RESERVEE_TEMPORAIREMENT' &&
              statut == 'DECISION_UNIVERSITAIRE_EN_ATTENTE'),
      cancelEndpoint: cancelAction['endpoint']?.toString(),
      placementExists: placement['exists'] == true || json['placement'] != null,
      placementStatus: placement['status']?.toString(),
      admissionExists: admission['exists'] == true || json['admission_uuid'] != null,
      admissionUuid: admission['uuid']?.toString() ?? json['admission_uuid']?.toString(),
      admissionStatus: admission['status']?.toString(),
      assignmentExists: assignment['exists'] == true || json['assignment_uuid'] != null,
      assignmentUuid: assignment['uuid']?.toString() ?? json['assignment_uuid']?.toString(),
      assignmentStatus: assignment['status']?.toString() ?? json['assignment_status']?.toString(),
      workflowMessage: message,
    );
  }

  bool concerne(CampagneStage autre) {
    final codeSuivi = campagne.code.trim().toUpperCase();
    final codeAutre = autre.code.trim().toUpperCase();
    if (codeSuivi.isNotEmpty && codeAutre.isNotEmpty) {
      return codeSuivi == codeAutre;
    }
    return campagne.titre.trim().toLowerCase() ==
            autre.titre.trim().toLowerCase() &&
        campagne.dateDebut == autre.dateDebut &&
        campagne.dateFin == autre.dateFin;
  }

  SuiviCandidatureStage avecCampagne(CampagneStage campagneComplete) {
    return SuiviCandidatureStage(
      campagne: campagneComplete.avecStatut(libelleStatut),
      statut: statut,
      libelleStatut: libelleStatut,
      message: message,
      nomHopital: nomHopital,
      estTermine: estTermine,
      reservationUuid: reservationUuid,
      reservationStatus: reservationStatus,
      applicationStatus: applicationStatus,
      canCancel: canCancel,
      cancelEndpoint: cancelEndpoint,
      placementExists: placementExists,
      placementStatus: placementStatus,
      admissionExists: admissionExists,
      admissionUuid: admissionUuid,
      admissionStatus: admissionStatus,
      assignmentExists: assignmentExists,
      assignmentUuid: assignmentUuid,
      assignmentStatus: assignmentStatus,
      workflowMessage: workflowMessage,
    );
  }

  int get progression {
    return switch (statut) {
      'DECISION_UNIVERSITAIRE_EN_ATTENTE' => 1,
      'EN_ATTENTE_PAIEMENT' => 2,
      'PLACEMENT_UNIVERSITAIRE_EN_ATTENTE' => 3,
      'ADMISSION_HOSPITALIERE_EN_ATTENTE' => 4,
      'AFFECTATION_EN_ATTENTE' || 'STAGE_PLANIFIE' => 5,
      'STAGE_EN_COURS' || 'STAGE_TERMINE' || 'STAGE_VALIDE' => 6,
      _ => 1,
    };
  }

  static const statutsTermines = {
    'STAGE_VALIDE',
    'CANDIDATURE_REFUSEE',
    'ANNULEE',
    'RESERVATION_EXPIREE',
  };

  static String libellePour(String statut) => switch (statut) {
    'DECISION_UNIVERSITAIRE_EN_ATTENTE' => 'Décision en attente',
    'EN_ATTENTE_PAIEMENT' => 'Paiement requis',
    'PLACEMENT_UNIVERSITAIRE_EN_ATTENTE' => 'Placement en attente',
    'ADMISSION_HOSPITALIERE_EN_ATTENTE' => 'Admission en attente',
    'AFFECTATION_EN_ATTENTE' => 'En attente d’affectation',
    'STAGE_PLANIFIE' => 'Stage planifié',
    'STAGE_EN_COURS' => 'Stage en cours',
    'STAGE_TERMINE' => 'Stage terminé',
    'STAGE_VALIDE' => 'Stage validé',
    'CANDIDATURE_REFUSEE' => 'Candidature refusée',
    'ANNULEE' => 'Candidature annulée',
    'RESERVATION_EXPIREE' => 'Réservation expirée',
    'ACCEPTEE' => 'Candidature acceptée',
    'REFUSEE' => 'Candidature refusée',
    _ => statut.isEmpty ? 'Candidature envoyée' : statut.replaceAll('_', ' '),
  };

  static Map<String, dynamic> _map(Object? value) => value is Map
      ? Map<String, dynamic>.from(value)
      : const <String, dynamic>{};
}
