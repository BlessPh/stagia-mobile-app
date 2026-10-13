import 'package:flutter_test/flutter_test.dart';
import 'package:stagia/features/journal/data/mappers/mappeur_journal_stage_api.dart';

void main() {
  test('normalise la liste et les droits explicites du journal', () {
    final resultat = MappeurJournalStageApi.normaliserReponse({
      'items': [
        {
          'uuid': 'logbook-uuid',
          'date': '2026-10-09',
          'status': 'SOUMIS',
          'summary': 'Consultations pédiatriques.',
          'learning': 'Signes de gravité.',
          'editable': false,
          'can_submit': false,
          'activities': [
            {
              'uuid': 'activity-uuid',
              'activity': 'Anamnèse',
              'category': 'PARTICIPATION',
              'involvement_level': 'REALISE_SUPERVISE',
              'quantity': 3,
            },
          ],
          'assignment': {'uuid': 'assignment-uuid'},
          'rotation': {'uuid': 'rotation-uuid'},
          'hospital': {'name': 'Hôpital Général'},
          'service': {'name': 'Pédiatrie'},
          'unit': null,
        },
      ],
      'stats': {'total': 1, 'submitted': 1},
      'pagination': {'page': 1, 'per_page': 20, 'total': 1, 'pages': 1},
      'filters': {
        'statuses': ['SOUMISE'],
      },
      'available_filters': {
        'statuses': ['BROUILLON', 'SOUMISE', 'VALIDEE', 'REJETEE'],
      },
    });

    final entree = (resultat['items'] as List<Map<String, dynamic>>).single;
    expect(entree['status'], 'SOUMISE');
    expect(entree['statut'], 'SOUMISE');
    expect(entree['activities_count'], 1);
    expect(entree['assignment_uuid'], 'assignment-uuid');
    expect(entree['rotation_uuid'], 'rotation-uuid');
    expect(entree['hospital_name'], 'Hôpital Général');
    expect(entree['unit_name'], 'Pédiatrie');
    expect((entree['actions'] as Map)['edit']['allowed'], isFalse);
    expect((entree['actions'] as Map)['submit']['allowed'], isFalse);
  });

  test('les actions de la réponse enregistrée priment sur les booléens', () {
    final resultat = MappeurJournalStageApi.normaliserAction({
      'message': 'Journal enregistré en brouillon.',
      'entry': {
        'uuid': 'logbook-uuid',
        'status': 'BROUILLON',
        'editable': false,
        'can_submit': false,
        'activities': <Map<String, dynamic>>[],
        'actions': {
          'edit': {'allowed': true, 'method': 'POST'},
          'submit': {'allowed': true, 'method': 'POST'},
        },
      },
    });

    final entree = resultat['entry'] as Map<String, dynamic>;
    expect(entree['editable'], isTrue);
    expect(entree['can_submit'], isTrue);
    expect((entree['actions'] as Map)['submit']['allowed'], isTrue);
  });
}
