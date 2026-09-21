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

  Future<Map<String, dynamic>> admission() =>
      _donnees(EndpointsApi.admissionEtudiant);

  Future<Map<String, dynamic>> optionsStage() =>
      _donnees(EndpointsApi.optionsStageEtudiant);

  Future<Map<String, dynamic>> candidatures() =>
      _donnees(EndpointsApi.candidaturesEtudiant);

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
      EndpointsApi.journalEnregistrer,
      corps: {
        'assignment_uuid': assignmentUuid,
        'date': date,
        'summary': summary,
        'learning': learning,
        'difficulties': ?difficulties,
        'logbook_uuid': ?logbookUuid,
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
      EndpointsApi.journalSoumettre,
      corps: {
        'logbook_uuid': logbookUuid,
        'assignment_uuid': ?assignmentUuid,
      },
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

  Future<Map<String, dynamic>> paiementCheckout({
    required String reservationUuid,
  }) async {
    if (ConfigurationApi.utiliserDonneesMockees) {
      return DonneesEtudiantMockees.pourEndpoint(
        EndpointsApi.paiementCheckout,
      );
    }
    final reponse = await _client.post(
      EndpointsApi.paiementCheckout,
      corps: {'reservation_uuid': reservationUuid},
    );
    if (reponse['success'] != true) {
      throw ErreurApi(
        code: 'REPONSE_API_REFUSEE',
        message: reponse['message']?.toString() ?? 'Checkout refusé.',
        details: reponse['data'],
      );
    }
    final donnees = reponse['data'];
    return donnees is Map
        ? Map<String, dynamic>.from(donnees)
        : <String, dynamic>{};
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
