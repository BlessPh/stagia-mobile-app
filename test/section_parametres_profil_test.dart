import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:stagia/core/services/preferences_application_service.dart';
import 'package:stagia/features/profile/presentation/widgets/section_parametres_profil.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('SectionParametresProfil affiche fidèlement les éléments de la maquette', (tester) async {
    await tester.pumpWidget(
      ChangeNotifierProvider<PreferencesApplicationService>.value(
        value: PreferencesApplicationService.instance,
        child: const MaterialApp(
          home: SectionParametresProfil(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // 1. En-tête AppBar
    expect(find.text('Paramètres'), findsOneWidget);
    expect(find.byIcon(Icons.arrow_back_ios_new_rounded), findsOneWidget);

    // 2. Carte Profil
    expect(find.text('Alfred Daniel'), findsOneWidget);
    expect(find.text('Product/UI Designer'), findsOneWidget);

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
    expect(find.text('Désactiver mon compte'), findsOneWidget);

    // 6. Test du switch Mode sombre
    final switchFinder = find.byType(Switch);
    expect(tester.widget<Switch>(switchFinder).value, isFalse);
    await tester.tap(switchFinder);
    await tester.pumpAndSettle();
    expect(PreferencesApplicationService.instance.modeSombre, isTrue);

    // 7. Test de la modale Désactiver mon compte
    await tester.tap(find.text('Désactiver mon compte'));
    await tester.pumpAndSettle();
    expect(find.text('Désactiver le compte ?'), findsOneWidget);
    await tester.tap(find.text('Annuler'));
    await tester.pumpAndSettle();
    expect(find.text('Désactiver le compte ?'), findsNothing);
  });
}
