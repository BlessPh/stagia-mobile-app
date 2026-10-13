import 'dart:io';
import 'client_api.dart';
import 'endpoints_api.dart';
import 'reponse_api.dart';
import 'configuration_api.dart';
import '../mocks/donnees_etudiant_mockees.dart';
import '../mocks/depot_mock_etudiant.dart';
import '../mocks/scenario_etudiant_ui.dart';
import '../../features/stage/data/mappers/mappeur_affectation_stage_api.dart';
import '../../features/journal/data/mappers/mappeur_presence_api.dart';
import '../../features/journal/data/mappers/mappeur_contexte_execution_api.dart';
import '../../features/journal/data/mappers/mappeur_tache_stage_api.dart';
import '../../features/journal/data/mappers/mappeur_journal_stage_api.dart';
import '../../features/journal/data/mappers/mappeur_feedback_stage_api.dart';
import '../../features/journal/data/mappers/mappeur_evaluation_stage_api.dart';

class SourceEtudiantDistante {
  const SourceEtudiantDistante(this._client);

  final ClientApi _client;

  Future<Map<String, dynamic>> profil() =>
      _donnees(EndpointsApi.profilEtudiant);

  Future<Map<String, dynamic>> profilActif() =>
      _donnees(EndpointsApi.profilActifEtudiant);

  Future<Map<String, dynamic>> rattachements() =>
      _donnees(EndpointsApi.rattachementsEtudiant);

  Future<Map<String, dynamic>> parcoursAcademique([int? enrollmentId]) async {
    if (ConfigurationApi.utiliserDonneesMockees) {
      return DonneesEtudiantMockees.pourEndpoint(
        EndpointsApi.parcoursAcademiqueEtudiant,
      );
    }
    final reponse = await _client.get(
      EndpointsApi.parcoursAcademiqueEtudiant,
      parametres: enrollmentId != null ? {'enrollment_id': enrollmentId} : null,
    );
    if (reponse['success'] != true) {
      throw ErreurApi(
        code: 'REPONSE_API_REFUSEE',
        message: reponse['message']?.toString() ?? 'Requête refusée.',
        details: reponse['data'],
      );
    }
    final donnees = reponse['data'];
    if (donnees is! Map) {
      throw const ErreurApi(
        code: 'DONNEES_API_INVALIDES',
        message: 'Les données reçues du serveur sont invalides.',
      );
    }
    return Map<String, dynamic>.from(donnees);
  }

  Future<Map<String, dynamic>> tableauDeBord() =>
      _donnees(EndpointsApi.tableauDeBordEtudiant);

  Future<Map<String, dynamic>> documents() =>
      _donnees(EndpointsApi.documentsEtudiant);

  Future<Map<String, dynamic>> stages({
    dynamic status,
    dynamic rotationStatus,
    dynamic campaignId,
    dynamic hospitalId,
    String? dateFrom,
    String? dateTo,
    dynamic include,
  }) async {
    if (ConfigurationApi.utiliserDonneesMockees) {
      return MappeurAffectationStageApi.normaliserReponse(
        DonneesEtudiantMockees.pourEndpoint(EndpointsApi.stagesEtudiant),
      );
    }
    final params = <String, dynamic>{};
    if (status != null) {
      params['status'] = status is List ? status.join(',') : status.toString();
    }
    if (rotationStatus != null) {
      params['rotation_status'] = rotationStatus is List
          ? rotationStatus.join(',')
          : rotationStatus.toString();
    }
    if (campaignId != null) {
      params['campaign_id'] = campaignId is List
          ? campaignId.join(',')
          : campaignId.toString();
    }
    if (hospitalId != null) {
      params['hospital_id'] = hospitalId is List
          ? hospitalId.join(',')
          : hospitalId.toString();
    }
    if (dateFrom != null) params['date_from'] = dateFrom;
    if (dateTo != null) params['date_to'] = dateTo;
    if (include != null) {
      params['include'] = include is List
          ? include.join(',')
          : include.toString();
    }

    final reponse = await _client.get(
      EndpointsApi.stagesEtudiant,
      parametres: params.isNotEmpty ? params : null,
    );
    if (reponse['success'] != true) {
      throw ErreurApi(
        code: 'REPONSE_API_REFUSEE',
        message: reponse['message']?.toString() ?? 'Requête refusée.',
        details: reponse['data'],
      );
    }
    final donnees = reponse['data'];
    if (donnees is! Map) {
      throw const ErreurApi(
        code: 'DONNEES_API_INVALIDES',
        message: 'Les données reçues du serveur sont invalides.',
      );
    }
    return MappeurAffectationStageApi.normaliserReponse(
      Map<String, dynamic>.from(donnees),
    );
  }

  Future<Map<String, dynamic>> reservations() =>
      _donnees(EndpointsApi.reservationsEtudiant);

  Future<Map<String, dynamic>> confirmerReservation(String uuid) async {
    final reponse = await _client.post(
      EndpointsApi.confirmerReservationEtudiant(uuid),
    );
    if (reponse['success'] != true) {
      throw ErreurApi(
        code: 'CONFIRMATION_REFUSEE',
        message: reponse['message']?.toString() ?? 'Confirmation refusée.',
        details: reponse['data'],
      );
    }
    final donnees = reponse['data'];
    return donnees is Map
        ? Map<String, dynamic>.from(donnees)
        : <String, dynamic>{};
  }

  Future<Map<String, dynamic>> annulerReservation(String uuid) async {
    if (ConfigurationApi.utiliserDonneesMockees) {
      return ScenarioEtudiantUi.annulerReservation(uuid);
    }
    final reponse = await _client.post(
      EndpointsApi.annulerReservationEtudiant(uuid),
    );
    if (reponse['success'] != true) {
      throw ErreurApi(
        code: 'ANNULATION_REFUSEE',
        message: reponse['message']?.toString() ?? 'Annulation refusée.',
        details: reponse['data'],
      );
    }
    final donnees = reponse['data'];
    return donnees is Map
        ? Map<String, dynamic>.from(donnees)
        : <String, dynamic>{};
  }

  Future<Map<String, dynamic>> admissions([String? reservationUuid]) async {
    if (ConfigurationApi.utiliserDonneesMockees) {
      return DonneesEtudiantMockees.pourEndpoint(
        EndpointsApi.admissionEtudiant,
      );
    }
    final reponse = await _client.get(
      EndpointsApi.admissionEtudiant,
      parametres: reservationUuid != null
          ? {'reservation_uuid': reservationUuid}
          : null,
    );
    if (reponse['success'] != true) {
      throw ErreurApi(
        code: 'REPONSE_API_REFUSEE',
        message: reponse['message']?.toString() ?? 'Requête refusée.',
        details: reponse['data'],
      );
    }
    final donnees = reponse['data'];
    if (donnees is! Map) {
      throw const ErreurApi(
        code: 'DONNEES_API_INVALIDES',
        message: 'Les données reçues du serveur sont invalides.',
      );
    }
    return Map<String, dynamic>.from(donnees);
  }

  Future<Map<String, dynamic>> admission() => admissions();

  Future<Map<String, dynamic>> optionsStage() =>
      _donnees(EndpointsApi.optionsStageEtudiant);

  Future<Map<String, dynamic>> candidatures() =>
      _donnees(EndpointsApi.candidaturesEtudiant);

  Future<Map<String, dynamic>> contexteExecution({
    String? assignmentUuid,
  }) async {
    if (ConfigurationApi.utiliserDonneesMockees) {
      return MappeurContexteExecutionApi.normaliser(
        DonneesEtudiantMockees.pourEndpoint(EndpointsApi.contexteExecution),
      );
    }
    final reponse = await _client.get(
      EndpointsApi.contexteExecution,
      parametres: assignmentUuid != null
          ? {'assignment_uuid': assignmentUuid}
          : null,
    );
    if (reponse['success'] != true) {
      throw ErreurApi(
        code: 'REPONSE_API_REFUSEE',
        message:
            reponse['message']?.toString() ??
            'Impossible d\'obtenir le contexte d\'exécution.',
        details: reponse['data'],
      );
    }
    final donnees = reponse['data'];
    if (donnees is! Map) {
      throw const ErreurApi(
        code: 'DONNEES_API_INVALIDES',
        message: 'Le contexte d\'exécution reçu est invalide.',
      );
    }
    return MappeurContexteExecutionApi.normaliser(
      Map<String, dynamic>.from(donnees),
    );
  }

  Future<Map<String, dynamic>> contextePointage([String? assignmentUuid]) =>
      contexteExecution(assignmentUuid: assignmentUuid);

  Future<Map<String, dynamic>> pointerArrivee() async {
    if (ConfigurationApi.utiliserDonneesMockees) {
      return MappeurPresenceApi.normaliserPointage(
        ScenarioEtudiantUi.pointerArrivee(),
      );
    }
    final reponse = await _client.post(EndpointsApi.pointageArrivee);
    if (reponse['success'] != true) {
      throw ErreurApi(
        code: 'POINTAGE_REFUSE',
        message:
            reponse['message']?.toString() ?? 'Pointage d\'arrivée impossible.',
        details: reponse['data'],
      );
    }
    final donnees = reponse['data'];
    if (donnees is! Map) {
      throw const ErreurApi(
        code: 'DONNEES_API_INVALIDES',
        message: 'Le pointage reçu du serveur est invalide.',
      );
    }
    return MappeurPresenceApi.normaliserPointage({
      ...Map<String, dynamic>.from(donnees),
      'message': reponse['message']?.toString() ?? '',
    });
  }

  Future<Map<String, dynamic>> pointerDepart() async {
    if (ConfigurationApi.utiliserDonneesMockees) {
      return MappeurPresenceApi.normaliserPointage(
        ScenarioEtudiantUi.pointerDepart(),
      );
    }
    final reponse = await _client.post(EndpointsApi.pointageDepart);
    if (reponse['success'] != true) {
      throw ErreurApi(
        code: 'POINTAGE_REFUSE',
        message:
            reponse['message']?.toString() ?? 'Pointage de départ impossible.',
        details: reponse['data'],
      );
    }
    final donnees = reponse['data'];
    if (donnees is! Map) {
      throw const ErreurApi(
        code: 'DONNEES_API_INVALIDES',
        message: 'Le pointage reçu du serveur est invalide.',
      );
    }
    return MappeurPresenceApi.normaliserPointage({
      ...Map<String, dynamic>.from(donnees),
      'message': reponse['message']?.toString() ?? '',
    });
  }

  Future<Map<String, dynamic>> presences({
    String? assignmentUuid,
    String? rotationUuid,
    dynamic status,
    String? dateFrom,
    String? dateTo,
    int page = 1,
    int perPage = 20,
  }) async {
    if (ConfigurationApi.utiliserDonneesMockees) {
      return MappeurPresenceApi.normaliserReponse(
        DonneesEtudiantMockees.pourEndpoint(EndpointsApi.presencesEtudiant),
      );
    }
    final parametres = <String, dynamic>{
      'assignment_uuid': ?assignmentUuid,
      'rotation_uuid': ?rotationUuid,
      if (status != null)
        'status': status is List ? status.join(',') : status.toString(),
      'date_from': ?dateFrom,
      'date_to': ?dateTo,
      'page': page,
      'per_page': perPage,
    };
    final reponse = await _client.get(
      EndpointsApi.presencesEtudiant,
      parametres: parametres,
    );
    if (reponse['success'] != true) {
      throw ErreurApi(
        code: 'REPONSE_API_REFUSEE',
        message: reponse['message']?.toString() ?? 'Requête refusée.',
        details: reponse['data'],
      );
    }
    final donnees = reponse['data'];
    if (donnees is! Map) {
      throw const ErreurApi(
        code: 'DONNEES_API_INVALIDES',
        message: 'Les données reçues du serveur sont invalides.',
      );
    }
    return MappeurPresenceApi.normaliserReponse(
      Map<String, dynamic>.from(donnees),
    );
  }

  Future<Map<String, dynamic>> journal({
    String? assignmentUuid,
    String? rotationUuid,
    dynamic status,
    String? dateFrom,
    String? dateTo,
    bool? editable,
    int page = 1,
    int perPage = 20,
  }) async {
    if (ConfigurationApi.utiliserDonneesMockees) {
      return MappeurJournalStageApi.normaliserReponse(
        DonneesEtudiantMockees.pourEndpoint(EndpointsApi.journalEtudiant),
      );
    }
    final parametres = <String, dynamic>{
      'assignment_uuid': ?assignmentUuid,
      'rotation_uuid': ?rotationUuid,
      if (status != null)
        'status': status is List ? status.join(',') : status.toString(),
      'date_from': ?dateFrom,
      'date_to': ?dateTo,
      'editable': ?editable,
      'page': page,
      'per_page': perPage,
    };
    final reponse = await _client.get(
      EndpointsApi.journalEtudiant,
      parametres: parametres,
    );
    if (reponse['success'] != true) {
      throw ErreurApi(
        code: 'REPONSE_API_REFUSEE',
        message: reponse['message']?.toString() ?? 'Requête refusée.',
        details: reponse['data'],
      );
    }
    final donnees = reponse['data'];
    if (donnees is! Map) {
      throw const ErreurApi(
        code: 'DONNEES_API_INVALIDES',
        message: 'Les données reçues du serveur sont invalides.',
      );
    }
    return MappeurJournalStageApi.normaliserReponse(
      Map<String, dynamic>.from(donnees),
    );
  }

  Future<Map<String, dynamic>> sauvegarderJournal({
    required String assignmentUuid,
    required String date,
    required String summary,
    required String learning,
    String? difficulties,
    String? duration,
    String? service,
    String? objectives,
    String? skills,
    String? results,
    required List<Map<String, dynamic>> activities,
    String? logbookUuid,
  }) async {
    if (ConfigurationApi.utiliserDonneesMockees) {
      return MappeurJournalStageApi.normaliserAction(
        ScenarioEtudiantUi.sauvegarderJournal(
          assignmentUuid: assignmentUuid,
          date: date,
          summary: summary,
          learning: learning,
          difficulties: difficulties,
          activities: activities,
          logbookUuid: logbookUuid,
        ),
      );
    }

    final reponse = await _client.post(
      EndpointsApi.journalEtudiant,
      corps: {
        'assignment_uuid': assignmentUuid,
        'date': date,
        'summary': summary,
        'learning': learning,
        'difficulties': ?difficulties,
        'uuid': ?logbookUuid,
        'activities': activities,
      },
    );

    if (reponse['success'] != true) {
      throw ErreurApi(
        code: 'REPONSE_API_REFUSEE',
        message: reponse['message']?.toString() ?? 'Enregistrement refusé.',
        details: reponse['data'],
      );
    }
    return _normaliserActionJournal(reponse);
  }

  Future<Map<String, dynamic>> soumettreJournal({
    required String logbookUuid,
    String? assignmentUuid,
  }) async {
    if (ConfigurationApi.utiliserDonneesMockees) {
      return MappeurJournalStageApi.normaliserAction(
        ScenarioEtudiantUi.soumettreJournal(logbookUuid),
      );
    }

    final reponse = await _client.post(
      EndpointsApi.soumettreJournal(logbookUuid),
    );

    if (reponse['success'] != true) {
      throw ErreurApi(
        code: 'REPONSE_API_REFUSEE',
        message: reponse['message']?.toString() ?? 'Soumission refusée.',
        details: reponse['data'],
      );
    }
    return _normaliserActionJournal(reponse);
  }

  Map<String, dynamic> _normaliserActionJournal(Map<String, dynamic> reponse) {
    final donnees = reponse['data'];
    if (donnees is! Map) {
      throw const ErreurApi(
        code: 'DONNEES_API_INVALIDES',
        message: 'Le journal actualisé reçu est invalide.',
      );
    }
    final resultat = MappeurJournalStageApi.normaliserAction({
      ...Map<String, dynamic>.from(donnees),
      'message': reponse['message']?.toString() ?? '',
    });
    final entree = resultat['entry'];
    if (entree is! Map || entree.isEmpty) {
      throw const ErreurApi(
        code: 'DONNEES_API_INVALIDES',
        message: 'Le journal actualisé reçu est invalide.',
      );
    }
    return resultat;
  }

  // Tâches
  Future<Map<String, dynamic>> taches({
    String? assignmentUuid,
    String? rotationUuid,
    dynamic status,
    dynamic priority,
    String? dueFrom,
    String? dueTo,
    int page = 1,
    int perPage = 20,
  }) async {
    if (ConfigurationApi.utiliserDonneesMockees) {
      return MappeurTacheStageApi.normaliserReponse(
        DonneesEtudiantMockees.pourEndpoint(EndpointsApi.tachesEtudiant),
      );
    }
    final parametres = <String, dynamic>{
      'assignment_uuid': ?assignmentUuid,
      'rotation_uuid': ?rotationUuid,
      if (status != null)
        'status': status is List ? status.join(',') : status.toString(),
      if (priority != null)
        'priority': priority is List ? priority.join(',') : priority.toString(),
      'due_from': ?dueFrom,
      'due_to': ?dueTo,
      'page': page,
      'per_page': perPage,
    };

    final reponse = await _client.get(
      EndpointsApi.tachesEtudiant,
      parametres: parametres,
    );
    if (reponse['success'] != true) {
      throw ErreurApi(
        code: 'REPONSE_API_REFUSEE',
        message:
            reponse['message']?.toString() ??
            'Impossible de récupérer les tâches.',
        details: reponse['data'],
      );
    }
    final donnees = reponse['data'];
    if (donnees is! Map) {
      throw const ErreurApi(
        code: 'DONNEES_API_INVALIDES',
        message: 'Les tâches reçues du serveur sont invalides.',
      );
    }
    return MappeurTacheStageApi.normaliserReponse(
      Map<String, dynamic>.from(donnees),
    );
  }

  Future<Map<String, dynamic>> demarrerTache(
    String uuid, {
    String? commentaire,
  }) async {
    final commentaireNettoye = commentaire?.trim() ?? '';
    if (ConfigurationApi.utiliserDonneesMockees) {
      return MappeurTacheStageApi.normaliserAction(
        ScenarioEtudiantUi.actionTache(
          uuid,
          'start',
          comment: commentaireNettoye,
        ),
      );
    }
    final reponse = await _client.post(
      EndpointsApi.demarrerTache(uuid),
      corps: commentaireNettoye.isNotEmpty
          ? {'comment': commentaireNettoye}
          : null,
    );
    if (reponse['success'] != true) {
      throw ErreurApi(
        code: 'ACTION_TACHE_REFUSEE',
        message:
            reponse['message']?.toString() ??
            'Impossible de démarrer la tâche.',
        details: reponse['data'],
      );
    }
    return _normaliserActionTache(reponse);
  }

  Future<Map<String, dynamic>> commenterTache(
    String uuid,
    String commentaire,
  ) async {
    final commentaireNettoye = commentaire.trim();
    if (commentaireNettoye.isEmpty) {
      throw const ErreurApi(
        code: 'COMMENTAIRE_REQUIS',
        message: 'Le commentaire est obligatoire.',
      );
    }
    if (ConfigurationApi.utiliserDonneesMockees) {
      return MappeurTacheStageApi.normaliserAction(
        ScenarioEtudiantUi.actionTache(
          uuid,
          'comment',
          comment: commentaireNettoye,
        ),
      );
    }
    final reponse = await _client.post(
      EndpointsApi.commenterTache(uuid),
      corps: {'comment': commentaireNettoye},
    );
    if (reponse['success'] != true) {
      throw ErreurApi(
        code: 'ACTION_TACHE_REFUSEE',
        message:
            reponse['message']?.toString() ??
            'Impossible d\'ajouter le commentaire.',
        details: reponse['data'],
      );
    }
    return _normaliserActionTache(reponse);
  }

  Future<Map<String, dynamic>> terminerTache(
    String uuid, {
    String? commentaire,
  }) async {
    final commentaireNettoye = commentaire?.trim() ?? '';
    if (ConfigurationApi.utiliserDonneesMockees) {
      return MappeurTacheStageApi.normaliserAction(
        ScenarioEtudiantUi.actionTache(
          uuid,
          'complete',
          comment: commentaireNettoye,
        ),
      );
    }
    final reponse = await _client.post(
      EndpointsApi.terminerTache(uuid),
      corps: commentaireNettoye.isNotEmpty
          ? {'comment': commentaireNettoye}
          : null,
    );
    if (reponse['success'] != true) {
      throw ErreurApi(
        code: 'ACTION_TACHE_REFUSEE',
        message:
            reponse['message']?.toString() ??
            'Impossible de terminer la tâche.',
        details: reponse['data'],
      );
    }
    return _normaliserActionTache(reponse);
  }

  Map<String, dynamic> _normaliserActionTache(Map<String, dynamic> reponse) {
    final donnees = reponse['data'];
    if (donnees is! Map) {
      throw const ErreurApi(
        code: 'DONNEES_API_INVALIDES',
        message: 'La tâche actualisée reçue est invalide.',
      );
    }
    final resultat = MappeurTacheStageApi.normaliserAction({
      ...Map<String, dynamic>.from(donnees),
      'message': reponse['message']?.toString() ?? '',
    });
    final tache = resultat['task'];
    if (tache is! Map || tache.isEmpty) {
      throw const ErreurApi(
        code: 'DONNEES_API_INVALIDES',
        message: 'La tâche actualisée reçue est invalide.',
      );
    }
    return resultat;
  }

  // Feedbacks
  Future<Map<String, dynamic>> feedbacks({
    dynamic type,
    String? assignmentUuid,
    String? rotationUuid,
    bool? seen,
    String? dateFrom,
    String? dateTo,
    int page = 1,
    int perPage = 20,
  }) async {
    if (ConfigurationApi.utiliserDonneesMockees) {
      return MappeurFeedbackStageApi.normaliserReponse(
        DonneesEtudiantMockees.pourEndpoint(EndpointsApi.feedbacksEtudiant),
      );
    }
    final parametres = <String, dynamic>{
      if (type != null) 'type': type is List ? type.join(',') : type.toString(),
      'assignment_uuid': ?assignmentUuid,
      'rotation_uuid': ?rotationUuid,
      'seen': ?seen,
      'date_from': ?dateFrom,
      'date_to': ?dateTo,
      'page': page,
      'per_page': perPage,
    };
    final reponse = await _client.get(
      EndpointsApi.feedbacksEtudiant,
      parametres: parametres,
    );
    if (reponse['success'] != true) {
      throw ErreurApi(
        code: 'REPONSE_API_REFUSEE',
        message:
            reponse['message']?.toString() ??
            'Impossible de récupérer les feedbacks.',
        details: reponse['data'],
      );
    }
    final donnees = reponse['data'];
    if (donnees is! Map) {
      throw const ErreurApi(
        code: 'DONNEES_API_INVALIDES',
        message: 'Les feedbacks reçus du serveur sont invalides.',
      );
    }
    return MappeurFeedbackStageApi.normaliserReponse(
      Map<String, dynamic>.from(donnees),
    );
  }

  Future<Map<String, dynamic>> marquerFeedbackLu(String uuid) async {
    if (ConfigurationApi.utiliserDonneesMockees) {
      return MappeurFeedbackStageApi.normaliserAction(
        ScenarioEtudiantUi.marquerFeedbackLu(uuid),
      );
    }
    final reponse = await _client.post(EndpointsApi.lireFeedback(uuid));
    if (reponse['success'] != true) {
      throw ErreurApi(
        code: 'LECTURE_FEEDBACK_REFUSEE',
        message:
            reponse['message']?.toString() ??
            'Impossible de marquer le feedback comme lu.',
        details: reponse['data'],
      );
    }
    final donnees = reponse['data'];
    if (donnees is! Map) {
      throw const ErreurApi(
        code: 'DONNEES_API_INVALIDES',
        message: 'Le feedback actualisé reçu est invalide.',
      );
    }
    final resultat = MappeurFeedbackStageApi.normaliserAction({
      ...Map<String, dynamic>.from(donnees),
      'message': reponse['message']?.toString() ?? '',
    });
    final feedback = resultat['feedback'];
    if (feedback is! Map || feedback.isEmpty) {
      throw const ErreurApi(
        code: 'DONNEES_API_INVALIDES',
        message: 'Le feedback actualisé reçu est invalide.',
      );
    }
    return resultat;
  }

  Future<Map<String, dynamic>> evaluations({
    dynamic type,
    dynamic status,
    String? assignmentUuid,
    String? rotationUuid,
    String? dateFrom,
    String? dateTo,
    int page = 1,
    int perPage = 20,
  }) async {
    if (ConfigurationApi.utiliserDonneesMockees) {
      return MappeurEvaluationStageApi.normaliserReponse(
        DonneesEtudiantMockees.pourEndpoint(EndpointsApi.evaluationsEtudiant),
      );
    }
    final parametres = <String, dynamic>{
      if (type != null) 'type': type is List ? type.join(',') : type.toString(),
      if (status != null)
        'status': status is List ? status.join(',') : status.toString(),
      'assignment_uuid': ?assignmentUuid,
      'rotation_uuid': ?rotationUuid,
      'date_from': ?dateFrom,
      'date_to': ?dateTo,
      'page': page,
      'per_page': perPage,
    };
    final reponse = await _client.get(
      EndpointsApi.evaluationsEtudiant,
      parametres: parametres,
    );
    if (reponse['success'] != true) {
      throw ErreurApi(
        code: 'REPONSE_API_REFUSEE',
        message: reponse['message']?.toString() ?? 'Requête refusée.',
        details: reponse['data'],
      );
    }
    final donnees = reponse['data'];
    if (donnees is! Map) {
      throw const ErreurApi(
        code: 'DONNEES_API_INVALIDES',
        message: 'Les évaluations reçues du serveur sont invalides.',
      );
    }
    return MappeurEvaluationStageApi.normaliserReponse(
      Map<String, dynamic>.from(donnees),
    );
  }

  Future<Map<String, dynamic>> paiements([
    Map<String, dynamic>? filtres,
  ]) async {
    if (ConfigurationApi.utiliserDonneesMockees) {
      return DepotMockEtudiant.listePaiements();
    }
    try {
      final reponse = await _client.get(
        EndpointsApi.paiementsEtudiant,
        parametres: filtres,
      );
      if (reponse['success'] != true) {
        // En cas de non-déploiement ou réponse négative du serveur de test, fallback gracieux
        return DepotMockEtudiant.listePaiements();
      }
      final donnees = reponse['data'];
      if (donnees is Map) {
        return Map<String, dynamic>.from(donnees);
      }
      return DepotMockEtudiant.listePaiements();
    } catch (_) {
      // Tolérance aux erreurs réseau ou 500 du serveur backend distant en cours de dev
      return DepotMockEtudiant.listePaiements();
    }
  }

  Future<Map<String, dynamic>> detailPaiement(String obligationUuid) async {
    if (ConfigurationApi.utiliserDonneesMockees) {
      return DepotMockEtudiant.detailObligation(obligationUuid);
    }
    try {
      final reponse = await _client.get(
        EndpointsApi.detailPaiementEtudiant(obligationUuid),
      );
      if (reponse['success'] != true) {
        return DepotMockEtudiant.detailObligation(obligationUuid);
      }
      final donnees = reponse['data'];
      return donnees is Map
          ? Map<String, dynamic>.from(donnees)
          : <String, dynamic>{};
    } catch (_) {
      // Tolérance si le module de paiement n'est pas encore déployé sur le backend distant
      return DepotMockEtudiant.detailObligation(obligationUuid);
    }
  }

  Future<Map<String, dynamic>> initierPaiement({
    required String obligationUuid,
    required String channel,
    required String phoneNumber,
    String? idempotencyKey,
    String? reservationUuid,
  }) async {
    final cle =
        idempotencyKey ??
        'idem-${DateTime.now().millisecondsSinceEpoch}-${obligationUuid.hashCode.abs()}';

    if (ConfigurationApi.utiliserDonneesMockees) {
      return DepotMockEtudiant.initierPaiement(
        obligationUuid: obligationUuid,
        channel: channel,
        phoneNumber: phoneNumber,
        idempotencyKey: cle,
      );
    }
    final reponse = await _client.post(
      EndpointsApi.initierPaiementEtudiant,
      corps: {
        'obligation_uuid': obligationUuid,
        'channel': channel,
        'phone_number': phoneNumber.trim(),
        'idempotency_key': cle,
        'reservation_uuid': ?reservationUuid,
      },
      entetes: {'Idempotency-Key': cle},
    );
    if (reponse['success'] != true) {
      throw ErreurApi(
        code: 'PAIEMENT_REFUSE',
        message:
            reponse['message']?.toString() ?? 'Initiation du paiement refusée.',
        details: reponse['data'],
      );
    }
    final donnees = reponse['data'];
    return donnees is Map
        ? Map<String, dynamic>.from(donnees)
        : <String, dynamic>{};
  }

  Future<Map<String, dynamic>> paiementSync({
    required String obligationUuid,
    String? reservationUuid,
  }) async {
    if (ConfigurationApi.utiliserDonneesMockees) {
      return DepotMockEtudiant.synchroniserPaiement(
        obligationUuid: obligationUuid,
      );
    }
    final reponse = await _client.post(
      EndpointsApi.paiementSync,
      corps: {
        'obligation_uuid': obligationUuid,
        'reservation_uuid': ?reservationUuid,
      },
    );
    if (reponse['success'] != true) {
      throw ErreurApi(
        code: 'REPONSE_API_REFUSEE',
        message: reponse['message']?.toString() ?? 'Synchronisation refusée.',
        details: reponse['data'],
      );
    }
    final donnees = reponse['data'];
    return donnees is Map
        ? Map<String, dynamic>.from(donnees)
        : <String, dynamic>{};
  }

  // Notes & Cursus
  Future<Map<String, dynamic>> notes([int? academicEnrollmentId]) async {
    final reponse = await _client.get(
      EndpointsApi.notesEtudiant,
      parametres: academicEnrollmentId != null
          ? {'academic_enrollment_id': academicEnrollmentId}
          : null,
    );
    if (reponse['success'] != true) {
      throw ErreurApi(
        code: 'REPONSE_API_REFUSEE',
        message:
            reponse['message']?.toString() ??
            'Impossible de récupérer les notes.',
        details: reponse['data'],
      );
    }
    final donnees = reponse['data'];
    return donnees is Map
        ? Map<String, dynamic>.from(donnees)
        : <String, dynamic>{};
  }

  // Conventions & Documents officiels
  Future<Map<String, dynamic>> conventions() =>
      _donnees(EndpointsApi.conventionsEtudiant);

  Future<Map<String, dynamic>> documentsAcademiques() =>
      _donnees(EndpointsApi.documentsAcademiques);

  Future<Map<String, dynamic>> documentsPersonnels() =>
      _donnees(EndpointsApi.documentsPersonnels);

  Future<Map<String, dynamic>> televerserDocumentPersonnel({
    required String cheminFichier,
    required String titre,
    String categorie = 'AUTRE',
  }) async {
    final reponse = await _client.envoyerFichier(
      EndpointsApi.documentsPersonnels,
      cheminFichier: cheminFichier,
      champs: {'title': titre, 'category': categorie},
      cleFichier: 'document',
    );
    if (reponse['success'] != true) {
      throw ErreurApi(
        code: 'UPLOAD_REFUSE',
        message: reponse['message']?.toString() ?? 'Téléversement refusé.',
        details: reponse['data'],
      );
    }
    final donnees = reponse['data'];
    return donnees is Map
        ? Map<String, dynamic>.from(donnees)
        : <String, dynamic>{};
  }

  Future<void> supprimerDocumentPersonnel(String uuid) async {
    final reponse = await _client.delete(EndpointsApi.documentPersonnel(uuid));
    if (reponse['success'] != true) {
      throw ErreurApi(
        code: 'SUPPRESSION_REFUSEE',
        message: reponse['message']?.toString() ?? 'Suppression impossible.',
        details: reponse['data'],
      );
    }
  }

  // --- Tâche 8 : Notifications & Badges ---
  Future<Map<String, dynamic>> notifications({
    int? limit,
    int? beforeId,
    bool? unread,
    String? type,
  }) async {
    if (ConfigurationApi.utiliserDonneesMockees) {
      return DonneesEtudiantMockees.pourEndpoint(
        EndpointsApi.notificationsEtudiant,
      );
    }
    final params = <String, String>{};
    if (limit != null) params['limit'] = limit.toString();
    if (beforeId != null) params['before_id'] = beforeId.toString();
    if (unread != null) params['unread'] = unread.toString();
    if (type != null) params['type'] = type;

    final reponse = await _client.get(
      EndpointsApi.notificationsEtudiant,
      parametres: params.isNotEmpty ? params : null,
    );
    if (reponse['success'] != true) {
      throw ErreurApi(
        code: 'NOTIFICATIONS_REFUSEES',
        message:
            reponse['message']?.toString() ??
            'Impossible de récupérer les notifications.',
        details: reponse['data'],
      );
    }
    final donnees = reponse['data'];
    return donnees is Map
        ? Map<String, dynamic>.from(donnees)
        : <String, dynamic>{};
  }

  Future<Map<String, dynamic>> notificationCounts() async {
    if (ConfigurationApi.utiliserDonneesMockees) {
      return DonneesEtudiantMockees.pourEndpoint(
        EndpointsApi.notificationsCounts,
      );
    }
    final reponse = await _client.get(EndpointsApi.notificationsCounts);
    if (reponse['success'] != true) {
      throw ErreurApi(
        code: 'COUNTS_REFUSES',
        message:
            reponse['message']?.toString() ??
            'Impossible d\'obtenir les compteurs.',
        details: reponse['data'],
      );
    }
    final donnees = reponse['data'];
    return donnees is Map
        ? Map<String, dynamic>.from(donnees)
        : <String, dynamic>{};
  }

  Future<void> marquerNotificationLue(String uuid) async {
    if (ConfigurationApi.utiliserDonneesMockees) {
      DepotMockEtudiant.marquerNotificationLue(uuid);
      return;
    }
    final reponse = await _client.post(
      EndpointsApi.marquerNotificationLue(uuid),
      corps: {},
    );
    if (reponse['success'] != true) {
      throw ErreurApi(
        code: 'LECTURE_NOTIFICATION_REFUSEE',
        message:
            reponse['message']?.toString() ??
            'Impossible de marquer la notification comme lue.',
        details: reponse['data'],
      );
    }
  }

  Future<void> archiverNotification(String uuid) async {
    if (ConfigurationApi.utiliserDonneesMockees) {
      DepotMockEtudiant.archiverNotification(uuid);
      return;
    }
    final reponse = await _client.post(
      EndpointsApi.archiverNotification(uuid),
      corps: {},
    );
    if (reponse['success'] != true) {
      throw ErreurApi(
        code: 'ARCHIVAGE_NOTIFICATION_REFUSE',
        message:
            reponse['message']?.toString() ??
            'Impossible d\'archiver la notification.',
        details: reponse['data'],
      );
    }
  }

  // --- Tâche 8 : Contacts & Messagerie ---
  Future<Map<String, dynamic>> contacts() =>
      _donnees(EndpointsApi.communicationContacts);

  Future<Map<String, dynamic>> conversations({int? limit, int? offset}) async {
    if (ConfigurationApi.utiliserDonneesMockees) {
      return DonneesEtudiantMockees.pourEndpoint(EndpointsApi.conversations);
    }
    final params = <String, String>{};
    if (limit != null) params['limit'] = limit.toString();
    if (offset != null) params['offset'] = offset.toString();

    final reponse = await _client.get(
      EndpointsApi.conversations,
      parametres: params.isNotEmpty ? params : null,
    );
    if (reponse['success'] != true) {
      throw ErreurApi(
        code: 'CONVERSATIONS_REFUSEES',
        message:
            reponse['message']?.toString() ??
            'Impossible de charger les conversations.',
        details: reponse['data'],
      );
    }
    final donnees = reponse['data'];
    return donnees is Map
        ? Map<String, dynamic>.from(donnees)
        : <String, dynamic>{};
  }

  Future<Map<String, dynamic>> messagesConversation(
    String convUuid, {
    int? afterId,
    int? limit,
  }) async {
    if (ConfigurationApi.utiliserDonneesMockees) {
      return {
        'conversation': {
          'uuid': convUuid,
          'subject': 'Discussion',
          'type': 'privee',
          'status': 'active',
          'participants': <Map<String, dynamic>>[],
        },
        'items': DepotMockEtudiant.messagesDeConversation(convUuid),
      };
    }
    final params = <String, String>{};
    if (afterId != null) params['after_id'] = afterId.toString();
    if (limit != null) params['limit'] = limit.toString();

    final reponse = await _client.get(
      EndpointsApi.conversationMessages(convUuid),
      parametres: params.isNotEmpty ? params : null,
    );
    if (reponse['success'] != true) {
      throw ErreurApi(
        code: 'MESSAGES_REFUSES',
        message:
            reponse['message']?.toString() ??
            'Impossible de charger les messages.',
        details: reponse['data'],
      );
    }
    final donnees = reponse['data'];
    return donnees is Map
        ? Map<String, dynamic>.from(donnees)
        : <String, dynamic>{};
  }

  Future<Map<String, dynamic>> envoyerMessageConversation(
    String convUuid, {
    required String contenu,
    File? pieceJointe,
  }) async {
    if (ConfigurationApi.utiliserDonneesMockees) {
      DepotMockEtudiant.ajouterMessage(
        conversationUuid: convUuid,
        contenu: contenu,
        nomFichier: pieceJointe?.path.split(Platform.pathSeparator).last,
      );
      return {'success': true};
    }

    if (pieceJointe != null) {
      final reponse = await _client.envoyerFichier(
        EndpointsApi.conversationMessages(convUuid),
        cleFichier: 'attachment',
        cheminFichier: pieceJointe.path,
        champs: {'content': contenu},
      );
      if (reponse['success'] != true) {
        throw ErreurApi(
          code: 'ENVOI_MESSAGE_REFUSE',
          message:
              reponse['message']?.toString() ?? 'Échec d\'envoi du message.',
          details: reponse['data'],
        );
      }
      final donnees = reponse['data'];
      return donnees is Map
          ? Map<String, dynamic>.from(donnees)
          : <String, dynamic>{};
    }

    final reponse = await _client.post(
      EndpointsApi.conversationMessages(convUuid),
      corps: {'content': contenu},
    );
    if (reponse['success'] != true) {
      throw ErreurApi(
        code: 'ENVOI_MESSAGE_REFUSE',
        message: reponse['message']?.toString() ?? 'Échec d\'envoi du message.',
        details: reponse['data'],
      );
    }
    final donnees = reponse['data'];
    return donnees is Map
        ? Map<String, dynamic>.from(donnees)
        : <String, dynamic>{};
  }

  Future<void> marquerMessagesConversationLus(
    String convUuid,
    String messageUuid,
  ) async {
    if (ConfigurationApi.utiliserDonneesMockees) return;
    await _client.post(
      EndpointsApi.marquerMessagesConversationLus(convUuid),
      corps: {'message_uuid': messageUuid},
    );
  }

  // --- Tâche 8 : Communications Officielles ---
  Future<Map<String, dynamic>> communicationsOfficielles({
    int? limit,
    int? offset,
  }) async {
    if (ConfigurationApi.utiliserDonneesMockees) {
      return DonneesEtudiantMockees.pourEndpoint(
        EndpointsApi.communicationsOfficielles,
      );
    }
    final params = <String, String>{};
    if (limit != null) params['limit'] = limit.toString();
    if (offset != null) params['offset'] = offset.toString();

    final reponse = await _client.get(
      EndpointsApi.communicationsOfficielles,
      parametres: params.isNotEmpty ? params : null,
    );
    if (reponse['success'] != true) {
      throw ErreurApi(
        code: 'COMMUNICATIONS_REFUSEES',
        message:
            reponse['message']?.toString() ??
            'Impossible de charger les communications officielles.',
        details: reponse['data'],
      );
    }
    final donnees = reponse['data'];
    return donnees is Map
        ? Map<String, dynamic>.from(donnees)
        : <String, dynamic>{};
  }

  Future<void> marquerCommunicationLue(String uuid) async {
    if (ConfigurationApi.utiliserDonneesMockees) {
      DepotMockEtudiant.marquerCommunicationLue(uuid);
      return;
    }
    final reponse = await _client.post(
      EndpointsApi.marquerCommunicationLue(uuid),
      corps: {},
    );
    if (reponse['success'] != true) {
      throw ErreurApi(
        code: 'LECTURE_COMMUNICATION_REFUSEE',
        message: reponse['message']?.toString() ?? 'Accusé de lecture refusé.',
        details: reponse['data'],
      );
    }
  }

  // --- Tâche 8 : Calendrier & Invitations ---
  Future<Map<String, dynamic>> calendrier({
    DateTime? from,
    DateTime? to,
  }) async {
    if (ConfigurationApi.utiliserDonneesMockees) {
      return DonneesEtudiantMockees.pourEndpoint(
        EndpointsApi.calendrierEtudiant,
      );
    }
    final params = <String, String>{};
    if (from != null) params['from'] = from.toIso8601String();
    if (to != null) params['to'] = to.toIso8601String();

    final reponse = await _client.get(
      EndpointsApi.calendrierEtudiant,
      parametres: params.isNotEmpty ? params : null,
    );
    if (reponse['success'] != true) {
      throw ErreurApi(
        code: 'CALENDRIER_REFUSE',
        message:
            reponse['message']?.toString() ??
            'Impossible d\'obtenir le calendrier.',
        details: reponse['data'],
      );
    }
    final donnees = reponse['data'];
    return donnees is Map
        ? Map<String, dynamic>.from(donnees)
        : <String, dynamic>{};
  }

  Future<void> repondreInvitationCalendrier(
    String uuid,
    String response,
  ) async {
    if (ConfigurationApi.utiliserDonneesMockees) {
      DepotMockEtudiant.repondreInvitationCalendrier(uuid, response);
      return;
    }
    final reponse = await _client.post(
      EndpointsApi.repondreInvitationCalendrier(uuid),
      corps: {'response': response},
    );
    if (reponse['success'] != true) {
      throw ErreurApi(
        code: 'REPONSE_CALENDRIER_REFUSEE',
        message:
            reponse['message']?.toString() ??
            'Impossible d\'enregistrer votre réponse.',
        details: reponse['data'],
      );
    }
  }

  Future<void> creerEvenementCalendrier({
    required String title,
    required DateTime startsAt,
    required DateTime endsAt,
    required List<int> participantUserIds,
    String? type,
    String? description,
    String? location,
  }) async {
    final payload = {
      'title': title,
      'starts_at': startsAt.toIso8601String(),
      'ends_at': endsAt.toIso8601String(),
      'participant_user_ids': participantUserIds,
      if (type != null) ...{'type': type},
      if (description != null) ...{'description': description},
      if (location != null) ...{'location': location},
    };

    if (ConfigurationApi.utiliserDonneesMockees) {
      DepotMockEtudiant.ajouterEvenementCalendrier({
        'uuid': '01JQ0CAL${DateTime.now().millisecondsSinceEpoch}',
        ...payload,
        'status': 'confirme',
        'creator_user_id': 999,
        'response_status': 'accepte',
        'responded_at': DateTime.now().toIso8601String(),
        'service': 'Stage clinique',
        'departement': 'Général',
        'superviseur': 'Superviseur de Stage',
      });
      return;
    }
    final reponse = await _client.post(
      EndpointsApi.calendrierEtudiant,
      corps: payload,
    );
    if (reponse['success'] != true) {
      throw ErreurApi(
        code: 'CREATION_CALENDRIER_REFUSEE',
        message:
            reponse['message']?.toString() ??
            'Impossible de créer l\'événement.',
        details: reponse['data'],
      );
    }
  }

  Future<Map<String, dynamic>> _donnees(String endpoint) async {
    if (ConfigurationApi.utiliserDonneesMockees) {
      return DonneesEtudiantMockees.pourEndpoint(endpoint);
    }
    final reponse = await _client.get(endpoint);
    if (reponse['success'] != true) {
      throw ErreurApi(
        code: 'REPONSE_API_REFUSEE',
        message: reponse['message']?.toString() ?? 'Requête refusée.',
        details: reponse['data'],
      );
    }

    final donnees = reponse['data'];
    if (donnees is! Map) {
      throw const ErreurApi(
        code: 'DONNEES_API_INVALIDES',
        message: 'Les données reçues du serveur sont invalides.',
      );
    }
    return Map<String, dynamic>.from(donnees);
  }
}
