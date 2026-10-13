import 'package:flutter_test/flutter_test.dart';
import 'package:stagia/features/journal/data/mappers/mappeur_feedback_stage_api.dart';

void main() {
  test('normalise un feedback et conserve l’action de lecture du serveur', () {
    final resultat = MappeurFeedbackStageApi.normaliserReponse({
      'items': [
        {
          'uuid': 'feedback-uuid',
          'date': '2026-10-09',
          'type': 'encouragement',
          'title': 'Bonne progression',
          'comment': 'Bonne qualité d’écoute.',
          'seen': false,
          'assignment': {'uuid': 'assignment-uuid'},
          'rotation': {'uuid': 'rotation-uuid'},
          'hospital': {'name': 'Hôpital Général'},
          'unit': {'name': 'Consultation'},
          'author': {'name': 'Docteur Encadreur'},
          'actions': {
            'read': {
              'allowed': true,
              'method': 'POST',
              'endpoint': '/api/v1/student/feedbacks/feedback-uuid/read',
            },
          },
        },
      ],
      'stats': {'total': 1, 'unread': 1},
      'pagination': {'page': 1, 'per_page': 20, 'total': 1, 'pages': 1},
      'filters': {'seen': false},
      'available_filters': {
        'types': ['OBSERVATION', 'ENCOURAGEMENT'],
      },
    });

    final feedback = (resultat['items'] as List<Map<String, dynamic>>).single;
    expect(feedback['type'], 'ENCOURAGEMENT');
    expect(feedback['assignment_uuid'], 'assignment-uuid');
    expect(feedback['rotation_uuid'], 'rotation-uuid');
    expect(feedback['hospital_name'], 'Hôpital Général');
    expect(feedback['unit_name'], 'Consultation');
    expect(feedback['author_name'], 'Docteur Encadreur');
    expect((feedback['actions'] as Map)['read']['allowed'], isTrue);
  });

  test('normalise le feedback complet retourné après lecture', () {
    final resultat = MappeurFeedbackStageApi.normaliserAction({
      'message': 'Feedback marque comme lu.',
      'feedback': {
        'uuid': 'feedback-uuid',
        'type': 'ENCOURAGEMENT',
        'seen': true,
        'seen_at': '2026-10-09 17:05:00',
        'actions': {
          'read': {'allowed': false},
        },
      },
    });

    final feedback = resultat['feedback'] as Map<String, dynamic>;
    expect(feedback['seen'], isTrue);
    expect((feedback['actions'] as Map)['read']['allowed'], isFalse);
  });
}
