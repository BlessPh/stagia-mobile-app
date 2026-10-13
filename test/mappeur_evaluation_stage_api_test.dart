import 'package:flutter_test/flutter_test.dart';
import 'package:stagia/features/journal/data/mappers/mappeur_evaluation_stage_api.dart';

void main() {
  test('normalise une évaluation et son contexte complet', () {
    final resultat = MappeurEvaluationStageApi.normaliserReponse({
      'items': [
        {
          'uuid': 'evaluation-uuid',
          'type': 'fin_rotation',
          'status': 'finalisee',
          'note': 16.5,
          'strengths': 'Communication clinique.',
          'improvement_areas': 'Gagner en rapidité.',
          'score_summary': {'total': 33, 'maximum': 40, 'percentage': 82.5},
          'scores': [
            {
              'code': 'COMP-CLIN',
              'nom': 'Raisonnement clinique',
              'categorie': 'CLINIQUE',
              'note': 17,
              'note_max': 20,
              'poids': 1,
              'commentaire': 'Bonne analyse.',
            },
          ],
          'evaluator': {
            'user_id': 14,
            'name': 'Docteur Encadreur',
            'function': 'Maître de stage',
          },
          'rotation': {'uuid': 'rotation-uuid'},
          'assignment': {'uuid': 'assignment-uuid'},
          'campaign': {'title': 'Stage clinique 2026'},
          'hospital': {'name': 'Hôpital Général'},
          'unit': {'name': 'Consultation'},
        },
      ],
      'stats': {'total': 1, 'average': 16.5},
      'final_evaluation': {
        'uuid': 'evaluation-uuid',
        'type': 'FIN_ROTATION',
        'status': 'FINALISEE',
        'note': 16.5,
      },
      'pagination': {'page': 1, 'per_page': 20, 'total': 1, 'pages': 1},
      'filters': {
        'statuses': ['FINALISEE'],
      },
      'available_filters': {
        'types': ['CONTINUE', 'MI_ROTATION', 'FIN_ROTATION'],
      },
    });

    final evaluation = (resultat['items'] as List<Map<String, dynamic>>).single;
    expect(evaluation['type'], 'FIN_ROTATION');
    expect(evaluation['status'], 'FINALISEE');
    expect(evaluation['note'], 16.5);
    expect(evaluation['evaluator_name'], 'Docteur Encadreur');
    expect(evaluation['evaluator_function'], 'Maître de stage');
    expect(evaluation['assignment_uuid'], 'assignment-uuid');
    expect(evaluation['rotation_uuid'], 'rotation-uuid');
    expect(evaluation['campaign_title'], 'Stage clinique 2026');
    expect(evaluation['hospital_name'], 'Hôpital Général');
    expect(evaluation['unit_name'], 'Consultation');
    final score = (evaluation['scores'] as List<Map<String, dynamic>>).single;
    expect(score['percentage'], 85.0);
    expect(score['commentaire'], 'Bonne analyse.');
    expect((resultat['final_evaluation'] as Map)['uuid'], 'evaluation-uuid');
  });
}
