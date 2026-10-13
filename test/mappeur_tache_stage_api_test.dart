import 'package:flutter_test/flutter_test.dart';
import 'package:stagia/features/journal/data/mappers/mappeur_tache_stage_api.dart';

void main() {
  test('normalise une tâche et conserve uniquement les actions du serveur', () {
    final resultat = MappeurTacheStageApi.normaliserReponse({
      'items': [
        {
          'uuid': 'task-uuid',
          'title': 'Consultation pédiatrique',
          'description': 'Anamnèse supervisée.',
          'priority': 'HAUTE',
          'status': 'A_FAIRE',
          'due_date': '2026-10-12',
          'supervisor_comment': 'Respecter le protocole.',
          'assignment': {'uuid': 'assignment-uuid', 'status': 'ACTIVE'},
          'rotation': {'uuid': 'rotation-uuid', 'sequence': 1},
          'hospital': {'id': 7, 'name': 'Hôpital Général'},
          'service': {'id': 8, 'name': 'Pédiatrie'},
          'unit': {'id': 9, 'name': 'Consultation'},
          'actions': {
            'start': {'allowed': true, 'method': 'POST'},
            'comment': {'allowed': true, 'method': 'POST'},
            'complete': {'allowed': false, 'method': 'POST'},
          },
        },
      ],
      'stats': {'total': 1, 'a_faire': 1},
      'progress': 0,
      'pagination': {'page': 1, 'per_page': 20, 'total': 1, 'pages': 1},
      'filters': <String, dynamic>{},
      'available_filters': {'per_page_max': 100},
    });

    final tache = (resultat['items'] as List<Map<String, dynamic>>).single;
    expect(tache['titre'], 'Consultation pédiatrique');
    expect(tache['priorite'], 'HAUTE');
    expect(tache['statut'], 'A_FAIRE');
    expect(tache['date_echeance'], '2026-10-12');
    expect(tache['hospital_name'], 'Hôpital Général');
    expect(tache['service_name'], 'Pédiatrie');
    expect(tache['unit_name'], 'Consultation');
    expect(tache['assignment_uuid'], 'assignment-uuid');
    expect(tache['rotation_uuid'], 'rotation-uuid');
    expect((tache['actions'] as Map)['start']['allowed'], isTrue);
    expect((tache['actions'] as Map)['complete']['allowed'], isFalse);
    expect(resultat['progress'], 0);
  });

  test('normalise la tâche complète retournée par une action', () {
    final resultat = MappeurTacheStageApi.normaliserAction({
      'message': 'Tache demarree.',
      'task': {
        'uuid': 'task-uuid',
        'title': 'Consultation',
        'status': 'EN_COURS',
        'actions': {
          'start': {'allowed': false},
          'comment': {'allowed': true},
          'complete': {'allowed': true},
        },
      },
    });

    final tache = resultat['task'] as Map<String, dynamic>;
    expect(tache['status'], 'EN_COURS');
    expect((tache['actions'] as Map)['start']['allowed'], isFalse);
    expect((tache['actions'] as Map)['complete']['allowed'], isTrue);
  });
}
