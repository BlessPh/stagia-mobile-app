import 'package:flutter_test/flutter_test.dart';
import 'package:stagia/features/planning/domain/entities/tache_planning.dart';

void main() {
  group('TachePlanning API', () {
    test('mappe une tâche de stage sans inventer de données', () {
      final tache = TachePlanning.depuisTacheStage({
        'uuid': 'uuid-tache',
        'titre': 'Observer une consultation',
        'description': 'Assister l’encadreur.',
        'statut': 'A_FAIRE',
        'date_echeance': '2026-10-05',
        'host_name': 'Hôpital général',
        'unit_name': 'Cardiologie',
      });

      expect(tache.id, 'uuid-tache');
      expect(tache.titre, 'Observer une consultation');
      expect(tache.date, DateTime(2026, 10, 5));
      expect(tache.service, 'Cardiologie');
      expect(tache.departement, 'Hôpital général');
      expect(tache.superviseur, isEmpty);
      expect(tache.statut, 'A FAIRE');
    });

    test('mappe une rotation sur la date affichée du planning', () {
      final rotation = TachePlanning.depuisRotationStage(
        {
          'rotation_uuid': 'uuid-rotation',
          'date_debut': '2026-10-01',
          'date_fin': '2026-10-10',
          'unit_name': 'Cardiologie',
          'supervisor_name': 'Jean Médecin',
          'statut': 'ACTIVE',
        },
        nomHopital: 'Hôpital général',
        dateAffichee: DateTime(2026, 10, 5),
      );

      expect(rotation.id, 'uuid-rotation');
      expect(rotation.date, DateTime(2026, 10, 5));
      expect(rotation.titre, 'Cardiologie');
      expect(rotation.superviseur, 'Jean Médecin');
      expect(rotation.noteRappel, 'Du 01/10/2026 au 10/10/2026');
    });
  });
}
