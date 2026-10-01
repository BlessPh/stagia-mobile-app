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

  test('mappe une campagne universitaire et ses hôpitaux éligibles', () {
    final campagne = MappeurCampagneStageApi.depuisJson({
      'campaign_id': 32,
      'academic_enrollment_id': 43,
      'title': 'Lancement L1 2026-2027',
      'mode': {
        'is_d4': false,
        'self_reservation_allowed': false,
        'reservation_mode': 'UNIVERSITY_MANAGED',
      },
      'hospitals_count': 1,
      'hospitals': [
        {
          'participation_id': 27,
          'hospital': {
            'code': 'HGT',
            'name': 'Hôpital Général de Test',
            'city': 'MOMO',
            'province': 'Haut-Uélé',
            'services': [
              {
                'id': 12,
                'code': 'SRV-LOC-C4C50F65',
                'name': 'Gyn',
                'type': 'SERVICE',
              },
              {
                'id': 11,
                'code': 'SRV-LOC-D0AEF415',
                'name': 'Pediatrie',
                'type': 'SERVICE',
              },
            ],
          },
          'available_places': 10,
          'fees_required': false,
        },
      ],
    });

    expect(campagne.autoriseReservationAutonome, isFalse);
    expect(campagne.modeReservation, 'UNIVERSITY_MANAGED');
    expect(campagne.nombreHopitaux, 1);
    expect(campagne.hopitaux.single.nom, 'Hôpital Général de Test');
    expect(campagne.hopitaux.single.placesRestantesEffectives, 10);
    expect(campagne.hopitaux.single.services, ['Gyn', 'Pediatrie']);
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
}

class _ClientApiEspion implements ClientApi {
  String? cheminPost;
  Object? corpsPost;

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
  }) => throw UnimplementedError();

  @override
  Future<List<int>> getBytes(
    String chemin, {
    Map<String, dynamic>? parametres,
  }) => throw UnimplementedError();

  @override
  Future<Map<String, dynamic>> patch(String chemin, {Object? corps}) =>
      throw UnimplementedError();
}
