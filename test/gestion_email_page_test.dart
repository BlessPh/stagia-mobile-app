import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stagia/features/profile/presentation/pages/gestion_email_page.dart';

void main() {
  testWidgets('GestionEmailPage affiche fidèlement la maquette Adresse e-mail', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: GestionEmailPage(
          email: 'alfred.daniel@gmail.com',
        ),
      ),
    );

    await tester.pumpAndSettle();

    // 1. AppBar
    expect(find.text('Adresse e-mail'), findsOneWidget);
    expect(find.byIcon(Icons.arrow_back_ios_new_rounded), findsOneWidget);

    // 2. Carte e-mail
    expect(find.text('E-MAIL'), findsOneWidget);
    expect(find.text('alfred.daniel@gmail.com'), findsOneWidget);
    expect(find.text('Vérifié'), findsOneWidget);
    expect(find.text("Modifier l'adresse e-mail"), findsOneWidget);

    // 3. Section Préférences
    expect(find.text('PRÉFÉRENCES'), findsOneWidget);

    // 4. Lignes de préférences avec switches
    expect(find.text('Notifications par e-mail'), findsOneWidget);
    expect(find.text('Newsletter et promotions'), findsOneWidget);
    expect(find.text('Alertes de sécurité'), findsOneWidget);
    expect(find.byType(Switch), findsNWidgets(3));

    // 5. Action Supprimer
    expect(find.text('Supprimer mon adresse e-mail'), findsOneWidget);

    // 6. Test ouverture de modale modifier email
    await tester.tap(find.text("Modifier l'adresse e-mail"));
    await tester.pumpAndSettle();
    expect(find.text('Nouvelle adresse e-mail'), findsOneWidget);
    await tester.tap(find.text('Enregistrer'));
    await tester.pumpAndSettle();
    // Attendre l'expiration du timer de l'alerte
    await tester.pump(const Duration(seconds: 4));

    // 7. Test dialogue de suppression
    await tester.tap(find.text('Supprimer mon adresse e-mail'));
    await tester.pumpAndSettle();
    expect(find.text("Supprimer l'e-mail ?"), findsOneWidget);
    await tester.tap(find.text('Annuler'));
    await tester.pumpAndSettle();
  });
}
