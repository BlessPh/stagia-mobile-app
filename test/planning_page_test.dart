import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stagia/core/theme/app_theme.dart';
import 'package:stagia/features/planning/presentation/pages/planning_page.dart';

void main() {
  testWidgets('PlanningPage affiche le calendrier et les tâches fidèlement à la maquette', (
    tester,
  ) async {
    // Initialiser sur le 16 septembre 2026
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: const PlanningPage(
          dateInitiale: null, // utilise le 16 septembre 2026 par défaut
        ),
      ),
    );
    await tester.pumpAndSettle();

    // 1. En-tête
    expect(find.text('Mon planning'), findsOneWidget);
    expect(find.byIcon(Icons.arrow_back_ios_new_rounded), findsOneWidget);
    expect(find.byIcon(Icons.settings_rounded), findsNothing);

    // 2. Calendrier (Jours de la semaine)
    expect(find.text('Lun'), findsAtLeastNWidgets(1));
    expect(find.text('Mer'), findsAtLeastNWidgets(1));
    expect(find.text('Dim'), findsAtLeastNWidgets(1));

    // 3. Tâches du 16 septembre (Exemple de l'utilisateur : Effectuer une lectomie)
    expect(find.text('Tâches du jour'), findsOneWidget);
    expect(find.text('Effectuer une lectomie'), findsOneWidget);
    expect(find.text('10:00'), findsOneWidget);
    expect(find.text('10:30'), findsOneWidget);
    expect(find.text('Chirurgie'), findsAtLeastNWidgets(1));

    // 4. Clic sur une tâche pour ouvrir la page de détail complète
    await tester.tap(find.text('Effectuer une lectomie'));
    await tester.pumpAndSettle();

    // Vérifier la présence des éléments de DetailTachePage
    expect(find.text('Détail de la tâche'), findsOneWidget);
    expect(find.text('Superviseur'), findsOneWidget);
    expect(find.text('Ngoy Jean'), findsOneWidget);
    expect(find.text('Description'), findsOneWidget);
    expect(find.text('Note / Rappel'), findsOneWidget);
    expect(find.text('Modifier'), findsOneWidget);
    expect(find.text('Terminé'), findsOneWidget);

    // Revenir en arrière vers la page planning
    await tester.tap(find.byTooltip('Retour'));
    await tester.pumpAndSettle();

    // 5. Clic sur le jour 10 pour afficher les tâches de la maquette (10 septembre)
    final cellule10 = find.text('10');
    expect(cellule10, findsOneWidget);
    await tester.tap(cellule10);
    await tester.pumpAndSettle();

    // Vérifier les tâches de la maquette pour le 10 septembre
    expect(find.text('Cours de Mathématiques'), findsOneWidget);
    expect(find.text('Réunion groupe projet'), findsOneWidget);

    // Faire défiler pour afficher les cartes suivantes
    await tester.drag(find.byType(CustomScrollView), const Offset(0, -300));
    await tester.pumpAndSettle();

    expect(find.text('Révision Physique'), findsOneWidget);
    expect(find.text('Rapport de Stage'), findsOneWidget);

    // 6. Clic sur le bouton FAB "+" pour ouvrir le formulaire d'ajout
    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();

    expect(find.text('Ajouter au planning'), findsOneWidget);
    expect(find.text('Titre / Activité'), findsOneWidget);
    expect(find.text('Enregistrer dans le planning'), findsOneWidget);
  });
}
