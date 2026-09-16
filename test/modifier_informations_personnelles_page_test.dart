import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stagia/features/profile/data/models/etudiant_profil.dart';
import 'package:stagia/features/profile/presentation/pages/modifier_informations_personnelles_page.dart';

void main() {
  testWidgets('ModifierInformationsPersonnellesPage affiche fidèlement la maquette', (tester) async {
    final profilInitial = EtudiantProfil.vide().copyWith(
      nomComplet: 'KABAMBA Jonas',
      sexe: 'Masculin',
      dateNaissance: '14-03-2003',
      province: 'Kinshasa',
    );

    await tester.pumpWidget(
      MaterialApp(
        home: ModifierInformationsPersonnellesPage(
          profil: profilInitial,
        ),
      ),
    );

    await tester.pumpAndSettle();

    // 1. AppBar
    expect(find.text('Informations personnelles'), findsOneWidget);
    expect(find.byIcon(Icons.arrow_back_ios_new_rounded), findsOneWidget);

    // 2. Champs principaux visibles
    expect(find.text('Post-nom'), findsOneWidget);
    expect(find.text('Prénom'), findsOneWidget);
    expect(find.text('Sexe'), findsOneWidget);
    expect(find.text('Date de naissance'), findsOneWidget);

    // 3. Défiler vers le bas pour voir la section Adresse
    await tester.drag(find.byType(ListView), const Offset(0, -300));
    await tester.pumpAndSettle();

    expect(find.text('ADRESSE'), findsOneWidget);
    expect(find.text('Adresse'), findsOneWidget);
    expect(find.text('Cité/Ville'), findsOneWidget);
    expect(find.text('Province'), findsOneWidget);

    // 4. Bouton enregistrer
    expect(find.text('Enregistrer les modifications'), findsOneWidget);

    // 5. Test modification et enregistrement
    await tester.tap(find.text('Enregistrer les modifications'));
    await tester.pumpAndSettle();
  });
}
