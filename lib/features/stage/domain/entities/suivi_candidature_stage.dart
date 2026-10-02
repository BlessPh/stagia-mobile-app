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
  });

  final CampagneStage campagne;
  final String statut;
  final String libelleStatut;
  final String message;
  final String nomHopital;
  final bool estTermine;
  final String? reservationUuid;

  factory SuiviCandidatureStage.depuisAdmission(Map<String, dynamic> json) {
    final campagneApi = _map(json['campaign']);
    final hopital = _map(json['hospital']);
    final reservation = _map(json['reservation']);
    final statut = json['workflow_status']?.toString().toUpperCase() ?? '';
    final debut = campagneApi['start_date']?.toString() ?? '';
    final fin = campagneApi['end_date']?.toString() ?? '';
    final code = campagneApi['code']?.toString() ?? '';
    final nomHopital = hopital['name']?.toString() ?? '';
    final messageApi = json['workflow_message']?.toString().trim() ?? '';

    return SuiviCandidatureStage(
      campagne: CampagneStage(
        id: code,
        code: code,
        titre: campagneApi['title']?.toString() ?? 'Candidature de stage',
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
      reservationUuid: reservation['uuid']?.toString(),
    );
  }

  factory SuiviCandidatureStage.depuisCandidature(
    Map<String, dynamic> json,
    CampagneStage campagne,
  ) {
    final statut =
        (json['workflow_status'] ?? json['statut'] ?? json['status'])
            ?.toString()
            .toUpperCase() ??
        '';
    final nomHopital =
        (json['hospital_name'] ?? json['entreprise'])?.toString() ?? '';
    final message = json['workflow_message']?.toString().trim() ?? '';
    final libelle = libellePour(statut);

    return SuiviCandidatureStage(
      campagne: campagne.avecStatut(libelle),
      statut: statut,
      libelleStatut: libelle,
      message: message.isNotEmpty
          ? message
          : 'Votre candidature a bien été enregistrée.',
      nomHopital: nomHopital,
      estTermine: statutsTermines.contains(statut),
      reservationUuid: (json['reservation_uuid'] ?? json['uuid'])?.toString(),
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
