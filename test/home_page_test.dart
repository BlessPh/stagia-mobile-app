import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stagia/core/theme/app_theme.dart';
import 'package:stagia/features/home/presentation/pages/home_shared_widgets.dart';
import 'package:stagia/features/home/presentation/widgets/carousel_accueil.dart';
import 'package:stagia/features/home/presentation/widgets/section_taches_jour_accueil.dart';
import 'package:stagia/features/planning/domain/entities/tache_planning.dart';

void main() {
  testWidgets('EnTeteAccueil n\'affiche pas de compteurs mock en mode API', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          appBar: const EnTeteAccueil(
            etudiant: {'nom': 'KALONJI', 'prenom': 'Alfred'},
          ),
          body: const SizedBox(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Bonjour'), findsOneWidget);
    expect(find.text('Alfred KALONJI'), findsOneWidget);
    expect(find.text('3'), findsNothing);
    expect(find.text('5'), findsNothing);
    expect(find.byIcon(CupertinoIcons.chat_bubble_2), findsOneWidget);
    expect(find.byIcon(CupertinoIcons.bell), findsOneWidget);
  });

  testWidgets('CarouselAccueil affiche le défilement et les indicateurs', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: const Scaffold(body: CarouselAccueil(autoPlay: false)),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(CarouselAccueil), findsOneWidget);
    expect(find.byType(PageView), findsOneWidget);
  });

  testWidgets(
    'SectionTachesJourAccueil affiche au maximum 2 tâches et redirige vers le planning',
    (tester) async {
      final tachesTest = [
        TachePlanning(
          id: 't-1',
          titre: 'Cours de Mathématiques',
          date: DateTime(2026, 9, 10),
          heureDebut: '09:00',
          heureFin: '10:30',
          type: 'Cours',
          service: 'Académique',
          departement: 'Bâtiment Principal',
          superviseur: 'Prof. Mukendi',
          lieu: 'Salle B204',
          description: 'Equations différentielles',
        ),
        TachePlanning(
          id: 't-2',
          titre: 'Réunion groupe projet',
          date: DateTime(2026, 9, 10),
          heureDebut: '11:00',
          heureFin: '12:30',
          type: 'Projet',
          service: 'Pédagogique',
          departement: 'Projets',
          superviseur: 'Coord. Kabila',
          lieu: 'Espace Cowork',
          description: 'Revue de littérature',
        ),
        TachePlanning(
          id: 't-3',
          titre: 'Révision Physique',
          date: DateTime(2026, 9, 10),
          heureDebut: '14:00',
          heureFin: '16:00',
          type: 'Examen',
          service: 'Académique',
          departement: 'Sciences',
          superviseur: 'Dr. Ilunga',
          lieu: 'Bibliothèque',
          description: 'Imagerie médicale',
        ),
      ];

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: Scaffold(
            body: ListView(
              children: [
                SectionTachesJourAccueil(tachesPersonnalisees: tachesTest),
              ],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Doit afficher le titre et Voir tout
      expect(find.text('Tâches du jour'), findsOneWidget);
      expect(find.text('Voir tout'), findsOneWidget);

      // Ne doit afficher que les 2 premières tâches
      expect(find.text('Cours de Mathématiques'), findsOneWidget);
      expect(find.text('Réunion groupe projet'), findsOneWidget);
      expect(
        find.text('Révision Physique'),
        findsNothing,
      ); // La 3ème n'est pas affichée

      // Clic sur Voir tout
      await tester.tap(find.text('Voir tout'));
      await tester.pumpAndSettle();

      // Redirigé vers Mon planning
      expect(find.text('Mon planning'), findsOneWidget);
    },
  );
}
