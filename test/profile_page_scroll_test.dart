import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:stagia/core/services/preferences_application_service.dart';
import 'package:stagia/features/profile/presentation/pages/profile_page.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('ProfilePage affiche le ClipPath fixe et permet le défilement superposé des ListTiles', (tester) async {
    await tester.pumpWidget(
      ChangeNotifierProvider<PreferencesApplicationService>.value(
        value: PreferencesApplicationService.instance,
        child: const MaterialApp(
          home: ProfilePage(),
        ),
      ),
    );

    // Attendre le chargement asynchrone du profil
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    // 1. Vérifier la présence des éléments de l'en-tête fixe
    expect(find.text('Mon profil'), findsOneWidget);
    expect(find.byIcon(Icons.settings_rounded), findsOneWidget);
    expect(find.text('Informations personnelles'), findsOneWidget);
    expect(find.text('Adresse e-mail'), findsOneWidget);

    // 2. Vérifier la position initiale
    final positionInitialeListTile = tester.getTopLeft(find.text('Informations personnelles'));
    final positionInitialeTitre = tester.getTopLeft(find.text('Mon profil'));

    // 3. Défiler vers le bas (drag vers le haut)
    await tester.drag(find.byType(ListView), const Offset(0, -150));
    await tester.pump();

    // La position du texte "Informations personnelles" est montée d'environ 150px
    final positionApresScroll = tester.getTopLeft(find.text('Informations personnelles'));
    expect(positionApresScroll.dy, lessThan(positionInitialeListTile.dy));

    // L'en-tête "Mon profil" reste fixé en haut et ne bouge pas
    final positionTitreApresScroll = tester.getTopLeft(find.text('Mon profil'));
    expect(positionTitreApresScroll.dy, equals(positionInitialeTitre.dy));

    // 4. Défiler vers le haut pour remonter
    await tester.drag(find.byType(ListView), const Offset(0, 150));
    await tester.pump();

    // La position redescend exactement à sa position initiale
    final positionRetour = tester.getTopLeft(find.text('Informations personnelles'));
    expect(positionRetour.dy, closeTo(positionInitialeListTile.dy, 2.0));

    // 5. Tester le tap sur un ListTile visible de la feuille (Adresse e-mail)
    await tester.tap(find.text('Adresse e-mail'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('E-MAIL'), findsOneWidget);
    await tester.tap(find.byIcon(Icons.arrow_back_ios_new_rounded));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
  });
}
