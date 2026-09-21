import '../../../../core/network/client_api.dart';
import '../../../../core/network/endpoints_api.dart';
import '../../../../core/network/configuration_api.dart';
import '../../../../core/network/reponse_api.dart';
import '../../../../core/mocks/donnees_etudiant_mockees.dart';
import '../../../../core/mocks/depot_mock_etudiant.dart';

class SourceStageDistante {
  const SourceStageDistante(this._client);
  final ClientApi _client;

  Future<Map<String, dynamic>> optionsStage() async {
    if (ConfigurationApi.utiliserDonneesMockees) {
      return DonneesEtudiantMockees.pourEndpoint(
        EndpointsApi.optionsStageEtudiant,
      );
    }

    final reponse = await _client.get(EndpointsApi.optionsStageEtudiant);
    if (reponse['success'] != true) {
      throw ErreurApi(
        code: 'REPONSE_API_REFUSEE',
        message: reponse['message']?.toString() ?? 'Requête refusée.',
        details: reponse['data'],
      );
    }
    return _normaliserCampagnes(reponse['data']);
  }

  Future<Map<String, dynamic>> campagnes({
    int page = 1,
    String? recherche,
  }) => optionsStage();

  Future<Map<String, dynamic>> opportunites(
    String campagneId, {
    int page = 1,
  }) => optionsStage();

  Future<Map<String, dynamic>> candidatures({
    int page = 1,
    String? statut,
  }) async {
    if (ConfigurationApi.utiliserDonneesMockees) {
      return DonneesEtudiantMockees.pourEndpoint(
        EndpointsApi.candidaturesEtudiant,
      );
    }

    final reponse = await _client.get(
      EndpointsApi.candidaturesEtudiant,
      parametres: {'page': page, 'status': ?statut},
    );
    if (reponse['success'] != true) {
      throw ErreurApi(
        code: 'REPONSE_API_REFUSEE',
        message: reponse['message']?.toString() ?? 'Requête refusée.',
        details: reponse['data'],
      );
    }
    return _normaliserListe(reponse['data']);
  }

  Future<Map<String, dynamic>> reservations() async {
    if (ConfigurationApi.utiliserDonneesMockees) {
      return DonneesEtudiantMockees.pourEndpoint(
        EndpointsApi.reservationsEtudiant,
      );
    }

    final reponse = await _client.get(EndpointsApi.reservationsEtudiant);
    if (reponse['success'] != true) {
      throw ErreurApi(
        code: 'REPONSE_API_REFUSEE',
        message: reponse['message']?.toString() ?? 'Requête refusée.',
        details: reponse['data'],
      );
    }
    return _normaliserListe(reponse['data']);
  }

  Future<Map<String, dynamic>> admission({String? reservationUuid}) async {
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
    return _normaliserListe(reponse['data']);
  }

  Future<Map<String, dynamic>> stages() async {
    if (ConfigurationApi.utiliserDonneesMockees) {
      return DonneesEtudiantMockees.pourEndpoint(
        EndpointsApi.stagesEtudiant,
      );
    }

    final reponse = await _client.get(EndpointsApi.stagesEtudiant);
    if (reponse['success'] != true) {
      throw ErreurApi(
        code: 'REPONSE_API_REFUSEE',
        message: reponse['message']?.toString() ?? 'Requête refusée.',
        details: reponse['data'],
      );
    }
    return _normaliserListe(reponse['data']);
  }

  Future<Map<String, dynamic>> reserver({
    required int campaignId,
    required int academicEnrollmentId,
    required int participationId,
    String? motivation,
    String? cleOption,
    String? campagneTitre,
    String? etablissementNom,
    String? localisation,
  }) async {
    if (ConfigurationApi.utiliserDonneesMockees) {
      return DepotMockEtudiant.ajouterReservation(
        campaignId: campaignId,
        academicEnrollmentId: academicEnrollmentId,
        participationId: participationId,
        motivation: motivation,
        cleOption: cleOption,
        campagneTitre: campagneTitre,
        etablissementNom: etablissementNom,
        localisation: localisation,
      );
    }

    final reponse = await _client.post(
      EndpointsApi.reserverStage,
      corps: {
        'campaign_id': campaignId,
        'academic_enrollment_id': academicEnrollmentId,
        'participation_id': participationId,
        if (motivation != null && motivation.trim().isNotEmpty)
          'motivation': motivation.trim(),
      },
    );

    if (reponse['success'] != true) {
      throw ErreurApi(
        code: 'REPONSE_API_REFUSEE',
        message: reponse['message']?.toString() ?? 'Réservation refusée.',
        details: reponse['data'],
      );
    }

    final donnees = reponse['data'];
    if (donnees is! Map) {
      throw const ErreurApi(
        code: 'DONNEES_API_INVALIDES',
        message: 'Les données de réservation reçues sont invalides.',
      );
    }
    return Map<String, dynamic>.from(donnees);
  }

  Future<Map<String, dynamic>> creerCandidature({
    required String campagneId,
    String? participationId,
    String? uniteAccueilId,
    required String motivation,
  }) {
    final cId = int.tryParse(campagneId.replaceAll(RegExp(r'[^0-9]'), '')) ?? 1;
    final pId = participationId != null
        ? (int.tryParse(participationId.replaceAll(RegExp(r'[^0-9]'), '')) ?? 101)
        : 101;
    return reserver(
      campaignId: cId,
      academicEnrollmentId: 1,
      participationId: pId,
      motivation: motivation,
    );
  }

  Future<Map<String, dynamic>> confirmerReservation(String reservationId) {
    if (ConfigurationApi.utiliserDonneesMockees) {
      return Future.value(
        DonneesEtudiantMockees.pourEndpoint(EndpointsApi.paiementCheckout),
      );
    }
    return _client.post(
      EndpointsApi.paiementCheckout,
      corps: {'reservation_uuid': reservationId},
    );
  }

  Future<Map<String, dynamic>> annulerReservation(String reservationId) =>
      _client.post(EndpointsApi.annulerReservation(reservationId));

  static Map<String, dynamic> _normaliserCampagnes(Object? donnees) {
    if (donnees is List) {
      return {'campaigns': _liste(donnees)};
    }
    if (donnees is Map) {
      final map = Map<String, dynamic>.from(donnees);
      final campagnes = map['campaigns'] ?? map['items'] ?? map['data'];
      if (campagnes is List) {
        return {...map, 'campaigns': _liste(campagnes)};
      }
      if (campagnes is Map) {
        final imbriquees = campagnes['items'] ?? campagnes['data'];
        if (imbriquees is List) {
          return {...map, 'campaigns': _liste(imbriquees)};
        }
      }
    }
    throw const ErreurApi(
      code: 'DONNEES_CAMPAGNES_INVALIDES',
      message: 'Les campagnes reçues du serveur sont invalides.',
    );
  }

  static List<Map<String, dynamic>> _liste(Object? valeur) => valeur is List
      ? valeur.whereType<Map>().map(Map<String, dynamic>.from).toList()
      : <Map<String, dynamic>>[];

  static Map<String, dynamic> _normaliserListe(Object? donnees) {
    if (donnees is Map) {
      final map = Map<String, dynamic>.from(donnees);
      final items = map['items'] ?? map['data'];
      if (items is List) return {...map, 'items': _liste(items)};
      if (items is Map && items['items'] is List) {
        return {...map, 'items': _liste(items['items'])};
      }
    }
    if (donnees is List) return {'items': _liste(donnees)};
    throw const ErreurApi(
      code: 'DONNEES_CANDIDATURES_INVALIDES',
      message: 'Les données reçues du serveur sont invalides.',
    );
  }
}
