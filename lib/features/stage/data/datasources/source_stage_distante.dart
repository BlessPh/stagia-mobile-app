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
    return normaliserCampagnes(reponse['data']);
  }

  Future<Map<String, dynamic>> campagnes({int page = 1, String? recherche}) =>
      optionsStage();

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
      return DonneesEtudiantMockees.pourEndpoint(EndpointsApi.stagesEtudiant);
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
    required String academicEnrollmentId,
    required String participationId,
    required String motivation,
  }) {
    final cId = int.tryParse(campagneId);
    final academicId = int.tryParse(academicEnrollmentId);
    final pId = int.tryParse(participationId);
    if (cId == null || academicId == null || pId == null) {
      throw const ErreurApi(
        code: 'IDENTIFIANTS_STAGE_INVALIDES',
        message:
            'Cette option de stage ne contient pas les identifiants requis.',
      );
    }
    return reserver(
      campaignId: cId,
      academicEnrollmentId: academicId,
      participationId: pId,
      motivation: motivation,
    );
  }

  Future<Map<String, dynamic>> confirmerReservation(String reservationUuid) =>
      _client.post(EndpointsApi.confirmerReservationEtudiant(reservationUuid));

  Future<Map<String, dynamic>> annulerReservation(String reservationUuid) =>
      _client.post(EndpointsApi.annulerReservationEtudiant(reservationUuid));

  /// Construit la liste canonique consommée par l'application mobile.
  ///
  /// L'API sépare les campagnes où l'étudiant choisit lui-même un hôpital
  /// (`campaigns`) de celles dont le placement est géré par l'université
  /// (`university_managed_campaigns`). Les écrans mobiles consomment la clé
  /// `campaigns`, qui doit donc contenir les deux collections.
  static Map<String, dynamic> normaliserCampagnes(Object? donnees) {
    if (donnees is List) {
      final campagnes = _liste(donnees);
      return {
        'campaigns': campagnes,
        'self_reservation_campaigns': campagnes,
        'university_managed_campaigns': <Map<String, dynamic>>[],
      };
    }
    if (donnees is Map) {
      final map = Map<String, dynamic>.from(donnees);
      final campagnesReservation = _extraireListeCampagnes(
        map['campaigns'] ?? map['items'] ?? map['data'],
      );
      final campagnesUniversitaires = _extraireListeCampagnes(
        map['university_managed_campaigns'],
      );

      if (campagnesReservation != null || campagnesUniversitaires != null) {
        final reservations = campagnesReservation ?? <Map<String, dynamic>>[];
        final universitaires =
            campagnesUniversitaires ?? <Map<String, dynamic>>[];
        return {
          ...map,
          'self_reservation_campaigns': reservations,
          'university_managed_campaigns': universitaires,
          'campaigns': _fusionnerCampagnes(reservations, universitaires),
        };
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

  static List<Map<String, dynamic>>? _extraireListeCampagnes(Object? valeur) {
    if (valeur is List) return _liste(valeur);
    if (valeur is Map) {
      final imbriquees = valeur['items'] ?? valeur['data'];
      if (imbriquees is List) return _liste(imbriquees);
    }
    return null;
  }

  static List<Map<String, dynamic>> _fusionnerCampagnes(
    List<Map<String, dynamic>> campagnesReservation,
    List<Map<String, dynamic>> campagnesUniversitaires,
  ) {
    final resultat = <Map<String, dynamic>>[];
    final identifiants = <String>{};

    for (final campagne in [
      ...campagnesReservation,
      ...campagnesUniversitaires,
    ]) {
      final identifiant =
          campagne['campaign_id'] ?? campagne['id'] ?? campagne['code'];
      final cle = identifiant?.toString().trim();
      if (cle == null || cle.isEmpty || identifiants.add(cle)) {
        resultat.add(campagne);
      }
    }
    return resultat;
  }

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
