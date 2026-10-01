import 'dart:io';
import 'client_api.dart';
import 'endpoints_api.dart';
import 'reponse_api.dart';
import 'configuration_api.dart';
import '../mocks/donnees_etudiant_mockees.dart';
import '../mocks/depot_mock_etudiant.dart';

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

  Future<Map<String, dynamic>> stages() =>
      _donnees(EndpointsApi.stagesEtudiant);

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
    return donnees is Map ? Map<String, dynamic>.from(donnees) : <String, dynamic>{};
  }

  Future<Map<String, dynamic>> annulerReservation(String uuid) async {
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
    return donnees is Map ? Map<String, dynamic>.from(donnees) : <String, dynamic>{};
  }

  Future<Map<String, dynamic>> admissions([String? reservationUuid]) async {
    if (ConfigurationApi.utiliserDonneesMockees) {
      return DonneesEtudiantMockees.pourEndpoint(EndpointsApi.admissionEtudiant);
    }
    final reponse = await _client.get(
      EndpointsApi.admissionEtudiant,
      parametres: reservationUuid != null ? {'reservation_uuid': reservationUuid} : null,
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

  Future<Map<String, dynamic>> contextePointage([String? assignmentUuid]) async {
    if (ConfigurationApi.utiliserDonneesMockees) {
      return {
        'can_punch': true,
        'next_action': 'ARRIVEE',
        'active_rotation': {
          'title': 'Chirurgie Générale',
          'hospital_name': 'Hôpital Général Provincial',
          'department': 'Chirurgie',
        },
        'today_punches': <Map<String, dynamic>>[],
      };
    }
    final reponse = await _client.get(
      EndpointsApi.contextePointage,
      parametres: assignmentUuid != null ? {'assignment_uuid': assignmentUuid} : null,
    );
    if (reponse['success'] != true) {
      throw ErreurApi(
        code: 'REPONSE_API_REFUSEE',
        message: reponse['message']?.toString() ?? 'Impossible d\'obtenir le contexte de pointage.',
        details: reponse['data'],
      );
    }
    final donnees = reponse['data'];
    return donnees is Map ? Map<String, dynamic>.from(donnees) : <String, dynamic>{};
  }

  Future<Map<String, dynamic>> pointerArrivee() async {
    final reponse = await _client.post(EndpointsApi.pointageArrivee, corps: {});
    if (reponse['success'] != true) {
      throw ErreurApi(
        code: 'POINTAGE_REFUSE',
        message: reponse['message']?.toString() ?? 'Pointage d\'arrivée impossible.',
        details: reponse['data'],
      );
    }
    final donnees = reponse['data'];
    return donnees is Map ? Map<String, dynamic>.from(donnees) : <String, dynamic>{};
  }

  Future<Map<String, dynamic>> pointerDepart() async {
    final reponse = await _client.post(EndpointsApi.pointageDepart, corps: {});
    if (reponse['success'] != true) {
      throw ErreurApi(
        code: 'POINTAGE_REFUSE',
        message: reponse['message']?.toString() ?? 'Pointage de départ impossible.',
        details: reponse['data'],
      );
    }
    final donnees = reponse['data'];
    return donnees is Map ? Map<String, dynamic>.from(donnees) : <String, dynamic>{};
  }

  Future<Map<String, dynamic>> presences([String? assignmentUuid]) async {
    if (ConfigurationApi.utiliserDonneesMockees) {
      return DonneesEtudiantMockees.pourEndpoint(
        EndpointsApi.presencesEtudiant,
      );
    }
    final reponse = await _client.get(
      EndpointsApi.presencesEtudiant,
      parametres:
          assignmentUuid != null ? {'assignment_uuid': assignmentUuid} : null,
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

  Future<Map<String, dynamic>> journal([String? assignmentUuid]) async {
    if (ConfigurationApi.utiliserDonneesMockees) {
      return DonneesEtudiantMockees.pourEndpoint(
        EndpointsApi.journalEtudiant,
      );
    }
    final reponse = await _client.get(
      EndpointsApi.journalEtudiant,
      parametres:
          assignmentUuid != null ? {'assignment_uuid': assignmentUuid} : null,
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
      final premiereActivite =
          activities.isNotEmpty ? activities.first : <String, dynamic>{};
      final categorie = premiereActivite['category']?.toString() ?? 'CHIRURGIE';
      if (logbookUuid != null && logbookUuid.isNotEmpty) {
        DepotMockEtudiant.modifierActivite(
          logbookUuid,
          titre: learning,
          description: summary,
          difficulte: difficulties ?? '',
          date: date,
          categorie: categorie,
          duree: duration ?? '4',
          service: service ?? 'Service de Chirurgie Générale',
          objectifs: objectives ?? '',
          competences: skills ?? '',
          resultats: results ?? '',
        );
        return {
          'logbook_uuid': logbookUuid,
          'statut': 'BROUILLON',
          'date': date,
        };
      } else {
        DepotMockEtudiant.ajouterActivite(
          titre: learning,
          description: summary,
          difficulte: difficulties ?? '',
          date: date,
          categorie: categorie,
          duree: duration ?? '4',
          service: service ?? 'Service de Chirurgie Générale',
          objectifs: objectives ?? '',
          competences: skills ?? '',
          resultats: results ?? '',
        );
        return {
          'logbook_uuid':
              'journal-local-${DateTime.now().millisecondsSinceEpoch}',
          'statut': 'BROUILLON',
          'date': date,
        };
      }
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
    final donnees = reponse['data'];
    return donnees is Map
        ? Map<String, dynamic>.from(donnees)
        : <String, dynamic>{};
  }

  Future<Map<String, dynamic>> soumettreJournal({
    required String logbookUuid,
    String? assignmentUuid,
  }) async {
    if (ConfigurationApi.utiliserDonneesMockees) {
      DepotMockEtudiant.soumettreActivite(logbookUuid);
      return {
        'logbook_uuid': logbookUuid,
        'statut': 'SOUMIS',
      };
    }

    final reponse = await _client.post(
      EndpointsApi.soumettreJournal(logbookUuid),
      corps: {},
    );

    if (reponse['success'] != true) {
      throw ErreurApi(
        code: 'REPONSE_API_REFUSEE',
        message: reponse['message']?.toString() ?? 'Soumission refusée.',
        details: reponse['data'],
      );
    }
    final donnees = reponse['data'];
    return donnees is Map
        ? Map<String, dynamic>.from(donnees)
        : <String, dynamic>{};
  }

  // Tâches
  Future<Map<String, dynamic>> taches({String? assignmentUuid, String? status}) async {
    final parametres = <String, dynamic>{};
    if (assignmentUuid != null) parametres['assignment_uuid'] = assignmentUuid;
    if (status != null) parametres['status'] = status;

    final reponse = await _client.get(
      EndpointsApi.tachesEtudiant,
      parametres: parametres.isNotEmpty ? parametres : null,
    );
    if (reponse['success'] != true) {
      throw ErreurApi(
        code: 'REPONSE_API_REFUSEE',
        message: reponse['message']?.toString() ?? 'Impossible de récupérer les tâches.',
        details: reponse['data'],
      );
    }
    final donnees = reponse['data'];
    return donnees is Map ? Map<String, dynamic>.from(donnees) : <String, dynamic>{};
  }

  Future<Map<String, dynamic>> demarrerTache(String uuid, {String? commentaire}) async {
    final reponse = await _client.post(
      EndpointsApi.demarrerTache(uuid),
      corps: commentaire != null && commentaire.isNotEmpty ? {'comment': commentaire} : {},
    );
    if (reponse['success'] != true) {
      throw ErreurApi(
        code: 'ACTION_TACHE_REFUSEE',
        message: reponse['message']?.toString() ?? 'Impossible de démarrer la tâche.',
        details: reponse['data'],
      );
    }
    final donnees = reponse['data'];
    return donnees is Map ? Map<String, dynamic>.from(donnees) : <String, dynamic>{};
  }

  Future<Map<String, dynamic>> commenterTache(String uuid, String commentaire) async {
    final reponse = await _client.post(
      EndpointsApi.commenterTache(uuid),
      corps: {'comment': commentaire},
    );
    if (reponse['success'] != true) {
      throw ErreurApi(
        code: 'ACTION_TACHE_REFUSEE',
        message: reponse['message']?.toString() ?? 'Impossible d\'ajouter le commentaire.',
        details: reponse['data'],
      );
    }
    final donnees = reponse['data'];
    return donnees is Map ? Map<String, dynamic>.from(donnees) : <String, dynamic>{};
  }

  Future<Map<String, dynamic>> terminerTache(String uuid, {String? commentaire}) async {
    final reponse = await _client.post(
      EndpointsApi.terminerTache(uuid),
      corps: commentaire != null && commentaire.isNotEmpty ? {'comment': commentaire} : {},
    );
    if (reponse['success'] != true) {
      throw ErreurApi(
        code: 'ACTION_TACHE_REFUSEE',
        message: reponse['message']?.toString() ?? 'Impossible de terminer la tâche.',
        details: reponse['data'],
      );
    }
    final donnees = reponse['data'];
    return donnees is Map ? Map<String, dynamic>.from(donnees) : <String, dynamic>{};
  }

  // Feedbacks
  Future<Map<String, dynamic>> feedbacks({String? type}) async {
    final reponse = await _client.get(
      EndpointsApi.feedbacksEtudiant,
      parametres: type != null ? {'type': type} : null,
    );
    if (reponse['success'] != true) {
      throw ErreurApi(
        code: 'REPONSE_API_REFUSEE',
        message: reponse['message']?.toString() ?? 'Impossible de récupérer les feedbacks.',
        details: reponse['data'],
      );
    }
    final donnees = reponse['data'];
    return donnees is Map ? Map<String, dynamic>.from(donnees) : <String, dynamic>{};
  }

  Future<Map<String, dynamic>> evaluations([String? assignmentUuid]) async {
    if (ConfigurationApi.utiliserDonneesMockees) {
      return DonneesEtudiantMockees.pourEndpoint(
        EndpointsApi.evaluationsEtudiant,
      );
    }
    final reponse = await _client.get(
      EndpointsApi.evaluationsEtudiant,
      parametres: assignmentUuid != null
          ? {'assignment_uuid': assignmentUuid}
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
    return donnees is Map
        ? Map<String, dynamic>.from(donnees)
        : <String, dynamic>{};
  }

  Future<Map<String, dynamic>> paiements() =>
      _donnees(EndpointsApi.paiementsEtudiant);

  Future<Map<String, dynamic>> initierPaiement({
    required String reservationUuid,
    required String channel,
    String? phoneNumber,
    required String idempotencyKey,
  }) async {
    if (ConfigurationApi.utiliserDonneesMockees) {
      return {
        'payment': {
          'created': true,
          'idempotent': false,
          'uuid': 'pay-mock-uuid-${DateTime.now().millisecondsSinceEpoch}',
          'reference': 'PAY-STG-MOCK',
          'amount': 50000,
          'currency': 'CDF',
          'channel': channel,
          'status': 'EN_ATTENTE',
          'phone_number': phoneNumber,
        },
        'reservation_uuid': reservationUuid,
      };
    }
    final reponse = await _client.post(
      EndpointsApi.initierPaiementEtudiant,
      corps: {
        'reservation_uuid': reservationUuid,
        'channel': channel,
        if (phoneNumber != null && phoneNumber.trim().isNotEmpty)
          'phone_number': phoneNumber.trim(),
        'idempotency_key': idempotencyKey,
      },
      entetes: {
        'Idempotency-Key': idempotencyKey,
      },
    );
    if (reponse['success'] != true) {
      throw ErreurApi(
        code: 'PAIEMENT_REFUSE',
        message: reponse['message']?.toString() ?? 'Initiation du paiement refusée.',
        details: reponse['data'],
      );
    }
    final donnees = reponse['data'];
    return donnees is Map ? Map<String, dynamic>.from(donnees) : <String, dynamic>{};
  }

  Future<Map<String, dynamic>> paiementSync({
    required String reservationUuid,
  }) async {
    if (ConfigurationApi.utiliserDonneesMockees) {
      return DonneesEtudiantMockees.pourEndpoint(
        EndpointsApi.paiementSync,
      );
    }
    final reponse = await _client.post(
      EndpointsApi.paiementSync,
      corps: {'reservation_uuid': reservationUuid},
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
      parametres: academicEnrollmentId != null ? {'academic_enrollment_id': academicEnrollmentId} : null,
    );
    if (reponse['success'] != true) {
      throw ErreurApi(
        code: 'REPONSE_API_REFUSEE',
        message: reponse['message']?.toString() ?? 'Impossible de récupérer les notes.',
        details: reponse['data'],
      );
    }
    final donnees = reponse['data'];
    return donnees is Map ? Map<String, dynamic>.from(donnees) : <String, dynamic>{};
  }

  // Conventions & Documents officiels
  Future<Map<String, dynamic>> conventions() => _donnees(EndpointsApi.conventionsEtudiant);

  Future<Map<String, dynamic>> documentsAcademiques() => _donnees(EndpointsApi.documentsAcademiques);

  Future<Map<String, dynamic>> documentsPersonnels() => _donnees(EndpointsApi.documentsPersonnels);

  Future<Map<String, dynamic>> televerserDocumentPersonnel({
    required String cheminFichier,
    required String titre,
    String categorie = 'AUTRE',
  }) async {
    final reponse = await _client.envoyerFichier(
      EndpointsApi.documentsPersonnels,
      cheminFichier: cheminFichier,
      champs: {
        'title': titre,
        'category': categorie,
      },
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
    return donnees is Map ? Map<String, dynamic>.from(donnees) : <String, dynamic>{};
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
      return DonneesEtudiantMockees.pourEndpoint(EndpointsApi.notificationsEtudiant);
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
        message: reponse['message']?.toString() ?? 'Impossible de récupérer les notifications.',
        details: reponse['data'],
      );
    }
    final donnees = reponse['data'];
    return donnees is Map ? Map<String, dynamic>.from(donnees) : <String, dynamic>{};
  }

  Future<Map<String, dynamic>> notificationCounts() async {
    if (ConfigurationApi.utiliserDonneesMockees) {
      return DonneesEtudiantMockees.pourEndpoint(EndpointsApi.notificationsCounts);
    }
    final reponse = await _client.get(EndpointsApi.notificationsCounts);
    if (reponse['success'] != true) {
      throw ErreurApi(
        code: 'COUNTS_REFUSES',
        message: reponse['message']?.toString() ?? 'Impossible d\'obtenir les compteurs.',
        details: reponse['data'],
      );
    }
    final donnees = reponse['data'];
    return donnees is Map ? Map<String, dynamic>.from(donnees) : <String, dynamic>{};
  }

  Future<void> marquerNotificationLue(String uuid) async {
    if (ConfigurationApi.utiliserDonneesMockees) {
      DepotMockEtudiant.marquerNotificationLue(uuid);
      return;
    }
    final reponse = await _client.post(EndpointsApi.marquerNotificationLue(uuid), corps: {});
    if (reponse['success'] != true) {
      throw ErreurApi(
        code: 'LECTURE_NOTIFICATION_REFUSEE',
        message: reponse['message']?.toString() ?? 'Impossible de marquer la notification comme lue.',
        details: reponse['data'],
      );
    }
  }

  Future<void> archiverNotification(String uuid) async {
    if (ConfigurationApi.utiliserDonneesMockees) {
      DepotMockEtudiant.archiverNotification(uuid);
      return;
    }
    final reponse = await _client.post(EndpointsApi.archiverNotification(uuid), corps: {});
    if (reponse['success'] != true) {
      throw ErreurApi(
        code: 'ARCHIVAGE_NOTIFICATION_REFUSE',
        message: reponse['message']?.toString() ?? 'Impossible d\'archiver la notification.',
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
        message: reponse['message']?.toString() ?? 'Impossible de charger les conversations.',
        details: reponse['data'],
      );
    }
    final donnees = reponse['data'];
    return donnees is Map ? Map<String, dynamic>.from(donnees) : <String, dynamic>{};
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
        message: reponse['message']?.toString() ?? 'Impossible de charger les messages.',
        details: reponse['data'],
      );
    }
    final donnees = reponse['data'];
    return donnees is Map ? Map<String, dynamic>.from(donnees) : <String, dynamic>{};
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
          message: reponse['message']?.toString() ?? 'Échec d\'envoi du message.',
          details: reponse['data'],
        );
      }
      final donnees = reponse['data'];
      return donnees is Map ? Map<String, dynamic>.from(donnees) : <String, dynamic>{};
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
    return donnees is Map ? Map<String, dynamic>.from(donnees) : <String, dynamic>{};
  }

  Future<void> marquerMessagesConversationLus(String convUuid, String messageUuid) async {
    if (ConfigurationApi.utiliserDonneesMockees) return;
    await _client.post(
      EndpointsApi.marquerMessagesConversationLus(convUuid),
      corps: {'message_uuid': messageUuid},
    );
  }

  // --- Tâche 8 : Communications Officielles ---
  Future<Map<String, dynamic>> communicationsOfficielles({int? limit, int? offset}) async {
    if (ConfigurationApi.utiliserDonneesMockees) {
      return DonneesEtudiantMockees.pourEndpoint(EndpointsApi.communicationsOfficielles);
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
        message: reponse['message']?.toString() ?? 'Impossible de charger les communications officielles.',
        details: reponse['data'],
      );
    }
    final donnees = reponse['data'];
    return donnees is Map ? Map<String, dynamic>.from(donnees) : <String, dynamic>{};
  }

  Future<void> marquerCommunicationLue(String uuid) async {
    if (ConfigurationApi.utiliserDonneesMockees) {
      DepotMockEtudiant.marquerCommunicationLue(uuid);
      return;
    }
    final reponse = await _client.post(EndpointsApi.marquerCommunicationLue(uuid), corps: {});
    if (reponse['success'] != true) {
      throw ErreurApi(
        code: 'LECTURE_COMMUNICATION_REFUSEE',
        message: reponse['message']?.toString() ?? 'Accusé de lecture refusé.',
        details: reponse['data'],
      );
    }
  }

  // --- Tâche 8 : Calendrier & Invitations ---
  Future<Map<String, dynamic>> calendrier({DateTime? from, DateTime? to}) async {
    if (ConfigurationApi.utiliserDonneesMockees) {
      return DonneesEtudiantMockees.pourEndpoint(EndpointsApi.calendrierEtudiant);
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
        message: reponse['message']?.toString() ?? 'Impossible d\'obtenir le calendrier.',
        details: reponse['data'],
      );
    }
    final donnees = reponse['data'];
    return donnees is Map ? Map<String, dynamic>.from(donnees) : <String, dynamic>{};
  }

  Future<void> repondreInvitationCalendrier(String uuid, String response) async {
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
        message: reponse['message']?.toString() ?? 'Impossible d\'enregistrer votre réponse.',
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
        message: reponse['message']?.toString() ?? 'Impossible de créer l\'événement.',
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
