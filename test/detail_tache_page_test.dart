import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stagia/core/theme/app_theme.dart';
import 'package:stagia/features/planning/data/datasources/source_planning_mock.dart';
import 'package:stagia/features/planning/presentation/pages/detail_tache_page.dart';

void main() {
  testWidgets('DetailTachePage affiche fidèlement la maquette de détail de la tâche', (
    tester,
  ) async {
    final tache = SourcePlanningMock.toutesLesTaches().firstWhere(
      (t) => t.titre == 'Cours de Mathématiques',
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: DetailTachePage(tache: tache),
      ),
    );
    await tester.pumpAndSettle();

    // 1. En-tête AppBar
    expect(find.text('Détail de la tâche'), findsOneWidget);
    expect(find.byIcon(Icons.chevron_left_rounded), findsOneWidget);

    // 2. Première carte (Aperçu, Badges & Métadonnées)
    expect(find.text('Cours'), findsOneWidget);
    expect(find.text('À venir'), findsOneWidget);
    expect(find.text('Cours de Mathématiques'), findsOneWidget);
    expect(find.text('Date & Horaires'), findsOneWidget);
    expect(find.text('Localisation'), findsOneWidget);
    expect(find.text('Salle B204, Bâtiment Principal'), findsOneWidget);
    expect(find.text('Enseignant'), findsOneWidget);
    expect(find.text('Prof. Mukendi'), findsOneWidget);

    // 3. Deuxième carte (Description)
    expect(find.text('Description'), findsOneWidget);
    expect(
      find.textContaining('Introduction aux équations différentielles'),
      findsOneWidget,
    );

    // 4. Troisième carte (Note / Rappel)
    expect(find.text('Note / Rappel'), findsOneWidget);
    expect(
      find.textContaining('polycopié de cours imprimé'),
      findsOneWidget,
    );

    // 5. Boutons du bas (Modifier & Terminé)
    expect(find.text('Modifier'), findsOneWidget);
    expect(find.text('Terminé'), findsOneWidget);

    // Cliquer sur Terminé
    await tester.tap(find.text('Terminé'));
    await tester.pumpAndSettle();

    // Le statut doit passer à Terminé
    expect(find.text('Terminé'), findsAtLeastNWidgets(2)); // Badge et bouton
  });
}
