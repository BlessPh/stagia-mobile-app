import 'package:flutter_test/flutter_test.dart';
import 'package:stagia/features/stage/data/mappers/mappeur_affectation_stage_api.dart';

void main() {
  group('MappeurAffectationStageApi', () {
    test(
      'normalise le nouveau contrat sans inventer une rotation courante',
      () {
        final reponse = MappeurAffectationStageApi.normaliserReponse({
          'student': {'id': 30, 'stagia_code': 'STG-ETU-00000030'},
          'items': [
            {
              'assignment_id': 47,
              'assignment_uuid': 'assignment-uuid',
              'assignment_status': 'PLANIFIEE',
              'workflow_status': 'PLANIFIE',
              'department': {
                'id': 12,
                'code': 'DEP-PED',
                'name': 'Département de pédiatrie',
                'type': 'DEPARTEMENT',
                'active': true,
              },
              'department_integrity': {
                'valid': true,
                'source': 'stage_admissions.coordination_unit_id',
              },
              'hospital': {
                'id': 8,
                'code': 'HOP-001',
                'name': 'Hôpital Général',
                'phone': '+243000000000',
                'email': 'contact@hopital.test',
                'location': {'city': 'Kinshasa', 'province': 'Kinshasa'},
              },
              'campaign': {
                'id': 39,
                'uuid': 'campaign-uuid',
                'code': 'CAM-000039',
                'title': 'Stage de fin d’année 2026',
                'stage_type': <String, dynamic>{},
              },
              'period': {'start_date': '2026-10-10', 'end_date': '2026-11-10'},
              'planning': {
                'current_rotation': null,
                'next_rotation': {
                  'id': 71,
                  'uuid': 'rotation-uuid',
                  'position': 1,
                  'sequence': 1,
                  'status': 'PLANIFIEE',
                  'period': {
                    'start_date': '2026-10-10',
                    'end_date': '2026-10-20',
                  },
                  'service': {
                    'id': 31,
                    'code': 'SRV-PED',
                    'name': 'Pédiatrie',
                    'type': 'SERVICE',
                  },
                  'unit': {
                    'id': 38,
                    'code': 'UNT-URG',
                    'name': 'Urgences',
                    'type': 'UNITE',
                  },
                  'supervisor': {
                    'user_id': 82,
                    'name': 'Dr Exemple',
                    'function': 'Maître de stage',
                  },
                  'objectives': 'Prise en charge initiale.',
                  'integrity': {'valid': true},
                },
                'rotations': [
                  {
                    'id': 71,
                    'uuid': 'rotation-uuid',
                    'position': 1,
                    'sequence': 1,
                    'status': 'PLANIFIEE',
                  },
                ],
                'total': 1,
              },
            },
          ],
          'summary': {
            'total': 1,
            'by_status': {'PLANIFIEE': 1},
          },
        });

        final stage = (reponse['items'] as List<Map<String, dynamic>>).single;
        final planning = stage['planning'] as Map<String, dynamic>;
        final rotations = planning['rotations'] as List<Map<String, dynamic>>;

        expect(planning['current_rotation'], isNull);
        expect((planning['next_rotation'] as Map)['uuid'], 'rotation-uuid');
        expect(rotations, hasLength(1));
        expect((rotations.single['service'] as Map)['name'], 'Pédiatrie');
        expect((rotations.single['unit'] as Map)['name'], 'Urgences');
        expect((rotations.single['supervisor'] as Map)['name'], 'Dr Exemple');
        expect(stage['hospital_name'], 'Hôpital Général');
        expect(stage['campaign_title'], 'Stage de fin d’année 2026');
        expect(stage['date_debut'], '2026-10-10');
        expect(stage['date_fin'], '2026-11-10');
        expect(stage['service_name'], isNull);
        expect(stage['supervisor_name'], isNull);
        expect(reponse['summary'], isNotNull);
      },
    );

    test(
      'trie les rotations et sélectionne en priorité l’affectation active',
      () {
        final active = MappeurAffectationStageApi.depuisJson({
          'assignment_uuid': 'active',
          'assignment_status': 'ACTIVE',
          'planning': {
            'rotations': [
              {
                'id': 22,
                'uuid': 'rotation-2',
                'sequence': 2,
                'status': 'PLANIFIEE',
              },
              {
                'id': 11,
                'uuid': 'rotation-1',
                'sequence': 1,
                'status': 'ACTIVE',
              },
            ],
          },
        });
        final planned = MappeurAffectationStageApi.depuisJson({
          'assignment_uuid': 'planned',
          'assignment_status': 'PLANIFIEE',
        });

        final rotations =
            (active['planning'] as Map)['rotations']
                as List<Map<String, dynamic>>;
        expect(rotations.map((rotation) => rotation['sequence']), [1, 2]);
        expect(
          MappeurAffectationStageApi.selectionnerAffectationPrincipale([
            planned,
            active,
          ])?['assignment_uuid'],
          'active',
        );
      },
    );
  });
}
