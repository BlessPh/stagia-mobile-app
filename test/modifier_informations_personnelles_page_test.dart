import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stagia/features/profile/data/models/etudiant_profil.dart';
import 'package:stagia/features/profile/presentation/pages/modifier_informations_personnelles_page.dart';

void main() {
  testWidgets(
    'les informations personnelles API sont affichées en lecture seule',
    (tester) async {
      final profilInitial = EtudiantProfil.vide().copyWith(
        nom: 'MBIMBU',
        postnom: 'GEMIMA',
        prenom: 'Gemima',
        nomComplet: 'KABAMBA Jonas',
        sexe: 'F',
        dateNaissance: '1993-07-12',
        adresse: 'RTR',
        ville: 'KIB',
        province: 'Maniema',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: ModifierInformationsPersonnellesPage(profil: profilInitial),
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

      final champs = tester.widgetList<TextFormField>(
        find.byType(TextFormField),
      );
      expect(champs.every((champ) => champ.readOnly), isTrue);

      // 4. Le seul bouton ferme la page sans modifier le profil.
      expect(find.text('Fermer'), findsOneWidget);
      await tester.tap(find.text('Fermer'));
      await tester.pumpAndSettle();
    },
  );
}
