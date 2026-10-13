import 'package:flutter_test/flutter_test.dart';
import 'package:stagia/features/journal/data/mappers/mappeur_contexte_execution_api.dart';

void main() {
  test('normalise le contexte canonique et ses alias historiques', () {
    final resultat = MappeurContexteExecutionApi.normaliser({
      'context': {
        'date': '2026-10-09',
        'assignment': {
          'id': 47,
          'uuid': 'assignment-uuid',
          'status': 'ACTIVE',
          'period': {'start_date': '2026-10-01', 'end_date': '2026-10-31'},
        },
        'campaign': {'id': 39, 'title': 'Stage clinique 2026'},
        'hospital': {'id': 7, 'name': 'Hôpital Général'},
        'department': {'id': 3, 'name': 'Médecine'},
        'current_rotation': {
          'id': 81,
          'uuid': 'rotation-uuid',
          'status': 'ACTIVE',
          'service': {'id': 8, 'name': 'Pédiatrie'},
          'unit': {'id': 9, 'name': 'Urgences'},
          'supervisor': {'user_id': 14, 'name': 'Docteur Encadreur'},
        },
        'next_rotation': null,
        'attendance': {
          'uuid': 'attendance-uuid',
          'date_presence': '2026-10-09',
          'heure_arrivee': '08:02:00',
          'heure_depart': null,
          'statut': 'PRESENT',
        },
        'actions': {
          'arrival': {'allowed': false},
          'departure': {'allowed': true},
          'logbook': {'allowed': true},
        },
        'capabilities': {
          'attendance': true,
          'logbook': true,
          'evaluation': true,
        },
        'reason': null,
        'unlock_date': null,
      },
      'execution': <String, dynamic>{},
      'punch': <String, dynamic>{},
    });

    final context = resultat['context'] as Map<String, dynamic>;
    final rotation = context['current_rotation'] as Map<String, dynamic>;
    final execution = resultat['execution'] as Map<String, dynamic>;
    final punch = resultat['punch'] as Map<String, dynamic>;

    expect((context['assignment'] as Map)['uuid'], 'assignment-uuid');
    expect(rotation['service_name'], 'Pédiatrie');
    expect(rotation['unit_name'], 'Urgences');
    expect((context['attendance'] as Map)['arrival_time'], '08:02:00');
    expect(execution['can_logbook'], isTrue);
    expect(execution['can_attendance'], isTrue);
    expect(punch['can_punch'], isTrue);
    expect(punch['next_action'], 'DEPART');
    expect(punch['assignment_uuid'], 'assignment-uuid');
  });

  test('conserve un contexte nul sans inventer une affectation', () {
    final resultat = MappeurContexteExecutionApi.normaliser({
      'context': null,
      'execution': {'reason': 'Aucune affectation active.'},
      'punch': {'can_punch': false},
    });

    expect(resultat['context'], isNull);
    expect(
      (resultat['execution'] as Map)['reason'],
      'Aucune affectation active.',
    );
    expect((resultat['punch'] as Map)['can_punch'], isFalse);
  });
}
