import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:stagia/core/services/preferences_application_service.dart';
import 'package:stagia/features/profile/presentation/pages/supprimer_compte_page.dart';
import 'package:stagia/features/profile/presentation/widgets/section_parametres_profil.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets(
    'SectionParametresProfil affiche fidèlement les éléments de la maquette',
    (tester) async {
      await tester.pumpWidget(
        ChangeNotifierProvider<PreferencesApplicationService>.value(
          value: PreferencesApplicationService.instance,
          child: const MaterialApp(home: SectionParametresProfil()),
        ),
      );

      await tester.pumpAndSettle();

      // 1. En-tête AppBar
      expect(find.text('Paramètres'), findsOneWidget);
      expect(find.byIcon(Icons.arrow_back_ios_new_rounded), findsOneWidget);

      // 2. Carte Profil
      expect(find.text('Étudiant'), findsOneWidget);
      expect(find.text('Stagiaire'), findsOneWidget);

      // 3. Titre de section
      expect(find.text('AUTRES PARAMÈTRES'), findsOneWidget);

      // 4. Groupe 1
      expect(find.text('Informations personnelles'), findsOneWidget);
      expect(find.text('Mot de passe'), findsOneWidget);
      expect(find.text('Notifications'), findsOneWidget);
      expect(find.text('Mode sombre'), findsOneWidget);
      expect(find.byType(Switch), findsOneWidget);

      // 5. Groupe 2
      expect(find.text('A propos application'), findsOneWidget);
      expect(find.text('Aide/FAQ'), findsOneWidget);
      expect(find.text('Supprimer mon compte'), findsOneWidget);

      // 6. Test du switch Mode sombre
      final switchFinder = find.byType(Switch);
      expect(tester.widget<Switch>(switchFinder).value, isFalse);
      await tester.tap(switchFinder);
      await tester.pumpAndSettle();
      expect(PreferencesApplicationService.instance.modeSombre, isTrue);

      // 7. Test de la modale Supprimer mon compte
      await tester.tap(find.text('Supprimer mon compte'));
      await tester.pumpAndSettle();
      expect(find.text('Supprimer le compte ?'), findsOneWidget);
      expect(find.textContaining('30 jours'), findsOneWidget);
      await tester.tap(find.text('Annuler'));
      await tester.pumpAndSettle();
      expect(find.text('Supprimer le compte ?'), findsNothing);
    },
  );

  testWidgets('le bouton Désactiver ouvre la confirmation détaillée', (
    tester,
  ) async {
    await tester.pumpWidget(
      ChangeNotifierProvider<PreferencesApplicationService>.value(
        value: PreferencesApplicationService.instance,
        child: const MaterialApp(home: SectionParametresProfil()),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Supprimer mon compte'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Désactiver'));
    await tester.pumpAndSettle();

    expect(find.byType(SupprimerComptePage), findsOneWidget);
    expect(find.text('Mot de passe actuel'), findsOneWidget);
    expect(find.text('Phrase de confirmation'), findsOneWidget);
    expect(find.textContaining('automatiquement réactivé'), findsOneWidget);
  });
}
