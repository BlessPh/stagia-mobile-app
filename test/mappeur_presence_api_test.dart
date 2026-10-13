import 'package:flutter_test/flutter_test.dart';
import 'package:stagia/features/journal/data/mappers/mappeur_presence_api.dart';

void main() {
  test('normalise le contrat complet de GET /student/attendance', () {
    final resultat = MappeurPresenceApi.normaliserReponse({
      'items': [
        {
          'uuid': 'attendance-uuid',
          'date': '2026-10-09',
          'status': 'RETARD',
          'arrival_time': '08:02:00',
          'departure_time': '16:10:00',
          'source': 'MOBILE',
          'minutes_late': 2,
          'duration_minutes': 488,
          'validated': true,
          'validator': {'user_id': 14, 'name': 'Docteur Encadreur'},
          'rotation': {'uuid': 'rotation-uuid', 'sequence': 1},
          'assignment': {'uuid': 'assignment-uuid', 'status': 'ACTIVE'},
          'campaign': {'code': 'CAM-000039', 'title': 'Stage 2026'},
          'hospital': {'code': 'HOP-001', 'name': 'Hôpital Général'},
          'unit': {'id': 8, 'code': 'SRV-PED', 'name': 'Pédiatrie'},
        },
      ],
      'stats': {'total': 12, 'attendance_rate': 91.67},
      'pagination': {'page': 1, 'per_page': 20, 'total': 12, 'pages': 1},
      'filters': {
        'assignment_uuid': 'assignment-uuid',
        'statuses': ['PRESENT', 'RETARD'],
      },
      'available_filters': {
        'statuses': ['PRESENT', 'RETARD', 'ABSENT', 'JUSTIFIE', 'GARDE'],
        'per_page_max': 100,
      },
    });

    final presence = (resultat['items'] as List<Map<String, dynamic>>).single;
    expect(presence['status'], 'RETARD');
    expect(presence['statut'], 'RETARD');
    expect(presence['time_in'], '08:02:00');
    expect(presence['time_out'], '16:10:00');
    expect(presence['hospital_name'], 'Hôpital Général');
    expect(presence['unit_name'], 'Pédiatrie');
    expect(presence['assignment_uuid'], 'assignment-uuid');
    expect(presence['rotation_uuid'], 'rotation-uuid');
    expect((resultat['stats'] as Map)['attendance_rate'], 91.67);
    expect((resultat['pagination'] as Map)['total'], 12);
    expect((resultat['available_filters'] as Map)['per_page_max'], 100);
  });

  test('ne fabrique pas de contexte absent de la réponse', () {
    final presence = MappeurPresenceApi.normaliserPresence({
      'uuid': 'attendance-uuid',
      'date': '2026-10-09',
      'status': 'ABSENT',
    });

    expect(presence['hospital_name'], isNull);
    expect(presence['unit_name'], isNull);
    expect(presence['arrival_time'], isNull);
    expect(presence['departure_time'], isNull);
    expect(presence['validator'], isNull);
  });

  test('normalise le punch retourné après une arrivée ou un départ', () {
    final resultat = MappeurPresenceApi.normaliserPointage({
      'message': 'Arrivée pointée à 08:02.',
      'punch': {
        'date': '2026-10-09',
        'assignment_id': 47,
        'rotation': {'uuid': 'rotation-uuid'},
        'attendance': {
          'uuid': 'attendance-uuid',
          'date_presence': '2026-10-09',
          'heure_arrivee': '08:02:00',
          'heure_depart': null,
          'statut': 'PRESENT',
        },
        'can_punch': true,
        'next_action': 'depart',
        'reason': null,
      },
    });

    final punch = resultat['punch'] as Map<String, dynamic>;
    final presence = punch['attendance'] as Map<String, dynamic>;
    expect(punch['next_action'], 'DEPART');
    expect(punch['can_punch'], isTrue);
    expect(presence['date'], '2026-10-09');
    expect(presence['arrival_time'], '08:02:00');
    expect(presence['departure_time'], isNull);
    expect(presence['status'], 'PRESENT');
  });
}
