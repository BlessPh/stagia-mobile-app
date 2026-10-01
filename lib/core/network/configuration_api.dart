abstract final class ConfigurationApi {
  /// Bascule principale : quand true, l'application utilise les mocks.
  /// Quand false, l'application interagit avec les endpoints réels de l'API PHP.
  static const utiliserDonneesMockees = false;

  /// Utilisé par les sources d'authentification pour déterminer le mode actif.
  static bool get utiliserAuthentificationApi => !utiliserDonneesMockees;

  /// URL de base par défaut conforme au contrat OpenAPI PHP (WAMP / serveur local)
  static const urlBase = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://stagia-rdc.onrender.com/api/v1',
  );

  static const dureeExpiration = Duration(seconds: 30);
}
