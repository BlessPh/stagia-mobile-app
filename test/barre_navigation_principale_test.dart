import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stagia/app/barre_navigation/barre_navigation_principale.dart';
import 'package:stagia/core/theme/app_theme.dart';

void main() {
  testWidgets('BarreNavigationPrincipale affiche fidèlement le design avec le bouton + flottant', (
    tester,
  ) async {
    int indexSelectionne = 0;
    bool boutonAjoutClique = false;

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: const Center(child: Text('Contenu test')),
          bottomNavigationBar: StatefulBuilder(
            builder: (context, setState) {
              return BarreNavigationPrincipale(
                indexActuel: indexSelectionne,
                onDestinationSelectionnee: (index) {
                  setState(() => indexSelectionne = index);
                },
                onAjouter: () {
                  boutonAjoutClique = true;
                },
              );
            },
          ),
        ),
      ),
    );

    // Vérifier la présence des 4 libellés
    expect(find.text('Accueil'), findsOneWidget);
    expect(find.text('Stages'), findsOneWidget);
    expect(find.text('Journal'), findsOneWidget);
    expect(find.text('Profil'), findsOneWidget);

    // Vérifier la présence de l'icône "+" du 5ème élément flottant central
    expect(find.byIcon(Icons.add_rounded), findsOneWidget);

    // Vérifier l'icône Accueil active
    expect(find.byIcon(Icons.home_rounded), findsOneWidget);
    // Vérifier les icônes inactives
    expect(find.byIcon(Icons.work_outline_rounded), findsOneWidget);
    expect(find.byIcon(Icons.menu_book_outlined), findsOneWidget);
    expect(find.byIcon(Icons.person_outline_rounded), findsOneWidget);

    // Cliquer sur le bouton flottant "+"
    await tester.tap(find.byIcon(Icons.add_rounded));
    await tester.pump();
    expect(boutonAjoutClique, isTrue);

    // Cliquer sur 'Stages'
    await tester.tap(find.text('Stages'));
    await tester.pump();

    // Vérifier que Stages est maintenant sélectionné
    expect(indexSelectionne, 1);
    expect(find.byIcon(Icons.work_rounded), findsOneWidget);
    expect(find.byIcon(Icons.home_outlined), findsOneWidget);
  });

  testWidgets('BarreNavigationPrincipale ouvre les actions rapides par défaut si onAjouter est null', (
    tester,
  ) async {
    int indexSelectionne = 0;

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: const Center(child: Text('Contenu test')),
          bottomNavigationBar: StatefulBuilder(
            builder: (context, setState) {
              return BarreNavigationPrincipale(
                indexActuel: indexSelectionne,
                onDestinationSelectionnee: (index) {
                  setState(() => indexSelectionne = index);
                },
              );
            },
          ),
        ),
      ),
    );

    // Cliquer sur le bouton flottant "+"
    await tester.tap(find.byIcon(Icons.add_rounded));
    await tester.pumpAndSettle();

    // La boîte modale d'actions rapides doit être visible
    expect(find.text('Actions rapides'), findsOneWidget);
    expect(find.text('Nouvelle entrée au journal'), findsOneWidget);
    expect(find.text('Découvrir les offres de stages'), findsOneWidget);

    // Cliquer sur une option (Nouvelle entrée au journal -> index 2)
    await tester.tap(find.text('Nouvelle entrée au journal'));
    await tester.pumpAndSettle();

    expect(indexSelectionne, 2);
  });
}
