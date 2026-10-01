import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:stagia/core/network/client_api_http.dart';
import 'package:stagia/core/services/preference_onboarding.dart';
import 'package:stagia/core/services/session_authentification_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  test('l onboarding est mémorisé après sa première présentation', () async {
    const preference = PreferenceOnboarding();

    expect(await preference.estTerminee(), isFalse);
    await preference.terminer();
    expect(await preference.estTerminee(), isTrue);
  });

  test('une session enregistrée reste disponible localement', () async {
    await SessionAuthentificationService.enregistrer({
      'access_token': 'access-local',
      'refresh_token': 'refresh-local',
      'expires_in': 3600,
      'refresh_expires_in': 2592000,
      'user': {'email': 'etudiant@example.test'},
      'student': {'stagia_code': 'STG-TEST-1'},
    });

    expect(await SessionAuthentificationService.estConnecte(), isTrue);
    expect(await SessionAuthentificationService.jeton(), 'access-local');
    expect(
      await SessionAuthentificationService.refreshToken(),
      'refresh-local',
    );
  });

  test('une coupure réseau pendant le refresh conserve la session', () async {
    await SessionAuthentificationService.enregistrer({
      'access_token': 'access-local',
      'refresh_token': 'refresh-local',
      'expires_in': 1,
      'refresh_expires_in': 2592000,
    });
    final client = ClientApiHttp(
      client: MockClient((_) async {
        throw http.ClientException('hors connexion');
      }),
    );

    final resultat = await client.rafraichirSessionSiDisponible();

    expect(resultat, ResultatRafraichissementSession.indisponible);
    expect(await SessionAuthentificationService.estConnecte(), isTrue);
    expect(await SessionAuthentificationService.jeton(), 'access-local');
  });

  test('la déconnexion explicite supprime la session locale', () async {
    await SessionAuthentificationService.enregistrer({
      'access_token': 'access-local',
      'refresh_token': 'refresh-local',
    });

    await SessionAuthentificationService.supprimer();

    expect(await SessionAuthentificationService.estConnecte(), isFalse);
    expect(await SessionAuthentificationService.jeton(), isNull);
    expect(await SessionAuthentificationService.refreshToken(), isNull);
  });
}
