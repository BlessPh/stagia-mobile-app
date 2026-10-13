import 'package:flutter_test/flutter_test.dart';
import 'package:stagia/core/network/client_api.dart';
import 'package:stagia/core/network/endpoints_api.dart';
import 'package:stagia/features/stage/data/datasources/source_stage_distante.dart';
import 'package:stagia/features/stage/data/mappers/mappeur_campagne_stage_api.dart';

void main() {
  group('normaliserCampagnes', () {
    test('fusionne les campagnes réservables et universitaires', () {
      final resultat = SourceStageDistante.normaliserCampagnes({
        'campaigns': [
          {
            'campaign_id': 12,
            'title': 'Campagne D4',
            'mode': {'self_reservation_allowed': true},
          },
        ],
        'university_managed_campaigns': [
          {
            'campaign_id': 32,
            'title': 'Lancement L1 2026-2027',
            'mode': {
              'self_reservation_allowed': false,
              'reservation_mode': 'UNIVERSITY_MANAGED',
            },
          },
        ],
        'stats': {'campaigns': 1, 'university_managed_campaigns': 1},
      });

      final campagnes = resultat['campaigns'] as List<Map<String, dynamic>>;
      expect(campagnes.map((item) => item['campaign_id']), [12, 32]);
      expect(
        (campagnes.last['mode'] as Map)['reservation_mode'],
        'UNIVERSITY_MANAGED',
      );
      expect(resultat['stats'], {
        'campaigns': 1,
        'university_managed_campaigns': 1,
      });
    });

    test('retourne les campagnes universitaires quand campaigns est vide', () {
      final resultat = SourceStageDistante.normaliserCampagnes({
        'campaigns': <Map<String, dynamic>>[],
        'university_managed_campaigns': [
          {'campaign_id': 30, 'title': 'Spécialisation'},
          {'campaign_id': 26, 'title': 'Session L1'},
        ],
      });

      final campagnes = resultat['campaigns'] as List<Map<String, dynamic>>;
      expect(campagnes, hasLength(2));
      expect(campagnes.first['campaign_id'], 30);
    });

    test('ne duplique pas une campagne présente dans les deux collections', () {
      final resultat = SourceStageDistante.normaliserCampagnes({
        'campaigns': [
          {'campaign_id': 32, 'title': 'Version réservations'},
        ],
        'university_managed_campaigns': [
          {'campaign_id': 32, 'title': 'Version université'},
        ],
      });

      final campagnes = resultat['campaigns'] as List<Map<String, dynamic>>;
      expect(campagnes, hasLength(1));
      expect(campagnes.single['title'], 'Version réservations');
    });
  });

  test('mappe le nouveau contrat d’une campagne et de ses hôpitaux', () {
    final campagne = MappeurCampagneStageApi.depuisJson({
      'campaign_id': 39,
      'academic_enrollment_id': 43,
      'code': 'CAM-000039',
      'title': 'Stage de fin d’année 2026',
      'start_date': '2026-10-01',
      'end_date': '2026-10-31',
      'stage_type': {'code': 'SPECIALISATION', 'label': 'Spécialisation'},
      'mode': {
        'is_d4': false,
        'self_reservation_allowed': true,
        'reservation_mode': 'STUDENT_CHOICE_UNIVERSITY_CONFIRMATION',
      },
      'promotion': {
        'code': 'PRO-0009',
        'name': 'Médecine Humaine · 2026-2027 · L1',
        'level': 'L1',
      },
      'program': 'Médecine Humaine',
      'hospitals_count': 1,
      'available_hospitals': 1,
      'hospitals': [
        {
          'participation_id': 81,
          'hospital': {
            'code': 'HOP-001',
            'name': 'Hôpital Général',
            'phone': '+243000000000',
            'city': 'Kinshasa',
            'province': 'Kinshasa',
            'services': <Map<String, dynamic>>[],
          },
          'capacity': 20,
          'used_places': 7,
          'available_places': 13,
          'available': true,
          'fees_required': true,
          'amount': 25.5,
          'currency': 'USD',
          'conditions': 'Tenue médicale obligatoire.',
        },
      ],
    });

    expect(campagne.id, '39');
    expect(campagne.code, 'CAM-000039');
    expect(campagne.autoriseReservationAutonome, isTrue);
    expect(campagne.modeReservation, 'STUDENT_CHOICE_UNIVERSITY_CONFIRMATION');
    expect(campagne.typeStageCode, 'SPECIALISATION');
    expect(campagne.typeStageLibelle, 'Spécialisation');
    expect(campagne.promotionCode, 'PRO-0009');
    expect(campagne.promotionNom, 'Médecine Humaine · 2026-2027 · L1');
    expect(campagne.niveau, 'L1');
    expect(campagne.periodeTexte, '2026-10-01 - 2026-10-31');
    expect(campagne.nombreHopitaux, 1);
    expect(campagne.nombreHopitauxDisponibles, 1);
    expect(campagne.hopitaux.single.nom, 'Hôpital Général');
    expect(campagne.hopitaux.single.capacite, 20);
    expect(campagne.hopitaux.single.placesUtilisees, 7);
    expect(campagne.hopitaux.single.placesRestantesEffectives, 13);
    expect(campagne.hopitaux.single.peutReserver, isTrue);
    expect(campagne.hopitaux.single.fraisRequis, isTrue);
    expect(campagne.hopitaux.single.montantFrais, 25.5);
    expect(campagne.hopitaux.single.devise, 'USD');
    expect(campagne.hopitaux.single.conditions, 'Tenue médicale obligatoire.');
    expect(campagne.hopitaux.single.localisationCourte, 'Kinshasa');
  });

  test('interdit la réservation quand l’API marque l’hôpital indisponible', () {
    final campagne = MappeurCampagneStageApi.depuisJson({
      'campaign_id': 39,
      'academic_enrollment_id': 43,
      'mode': {'self_reservation_allowed': true},
      'hospitals': [
        {
          'participation_id': 81,
          'hospital': {'name': 'Hôpital complet'},
          'available_places': 3,
          'available': false,
        },
      ],
    });

    expect(campagne.hopitaux.single.peutReserver, isFalse);
  });

  test(
    'envoie la réservation mobile au bon endpoint avec les identifiants API',
    () async {
      final client = _ClientApiEspion();
      final source = SourceStageDistante(client);

      final resultat = await source.reserver(
        campaignId: 17,
        academicEnrollmentId: 33,
        participationId: 42,
        motivation: 'Je souhaite effectuer ce stage.',
      );

      expect(client.cheminPost, EndpointsApi.reserverStage);
      expect(client.corpsPost, {
        'campaign_id': 17,
        'academic_enrollment_id': 33,
        'participation_id': 42,
        'motivation': 'Je souhaite effectuer ce stage.',
      });
      expect(resultat['reservation_uuid'], 'reservation-test');
      expect(resultat['created'], isTrue);
    },
  );

  test('transmet les filtres documentés de GET /student/stages', () async {
    final client = _ClientApiEspion();
    final source = SourceStageDistante(client);

    final resultat = await source.stages(
      status: ['PLANIFIEE', 'ACTIVE'],
      rotationStatus: ['PLANIFIEE', 'ACTIVE'],
      campaignId: [39, 40],
      hospitalId: 8,
      dateFrom: '2026-10-01',
      dateTo: '2026-10-31',
      include: ['rotations', 'supervisors', 'summary'],
    );

    expect(client.cheminGet, EndpointsApi.stagesEtudiant);
    expect(client.parametresGet, {
      'status': 'PLANIFIEE,ACTIVE',
      'rotation_status': 'PLANIFIEE,ACTIVE',
      'campaign_id': '39,40',
      'hospital_id': '8',
      'date_from': '2026-10-01',
      'date_to': '2026-10-31',
      'include': 'rotations,supervisors,summary',
    });
    expect((resultat['items'] as List), isEmpty);
  });
}

class _ClientApiEspion implements ClientApi {
  String? cheminPost;
  Object? corpsPost;
  String? cheminGet;
  Map<String, dynamic>? parametresGet;

  @override
  Future<Map<String, dynamic>> post(
    String chemin, {
    Object? corps,
    Map<String, String>? entetes,
  }) async {
    cheminPost = chemin;
    corpsPost = corps;
    return {
      'success': true,
      'message': 'Réservation créée.',
      'data': {
        'created': true,
        'reservation_uuid': 'reservation-test',
        'reservation_status': 'RESERVEE_TEMPORAIREMENT',
      },
    };
  }

  @override
  Future<Map<String, dynamic>> delete(String chemin) =>
      throw UnimplementedError();

  @override
  Future<Map<String, dynamic>> envoyerFichier(
    String chemin, {
    required String cheminFichier,
    required Map<String, String> champs,
    String cleFichier = 'document',
  }) => throw UnimplementedError();

  @override
  Future<Map<String, dynamic>> get(
    String chemin, {
    Map<String, dynamic>? parametres,
  }) async {
    cheminGet = chemin;
    parametresGet = parametres;
    return {
      'success': true,
      'message': '',
      'data': {'items': <Map<String, dynamic>>[]},
    };
  }

  @override
  Future<List<int>> getBytes(
    String chemin, {
    Map<String, dynamic>? parametres,
  }) => throw UnimplementedError();

  @override
  Future<Map<String, dynamic>> patch(String chemin, {Object? corps}) =>
      throw UnimplementedError();
}
