import 'dart:io';

import '../services/session_authentification_service.dart';
import 'configuration_api.dart';
import 'reponse_api.dart';

class TelechargeurDocumentApi {
  const TelechargeurDocumentApi();

  Future<String> enregistrerFichier({
    required List<int> contenu,
    required String nom,
    String? extension,
  }) async {
    final estPdf =
        contenu.length >= 4 &&
        contenu[0] == 0x25 &&
        contenu[1] == 0x50 &&
        contenu[2] == 0x44 &&
        contenu[3] == 0x46;
    final estPng =
        contenu.length >= 8 &&
        contenu[0] == 0x89 &&
        contenu[1] == 0x50 &&
        contenu[2] == 0x4E &&
        contenu[3] == 0x47;
    final estJpeg =
        contenu.length >= 3 &&
        contenu[0] == 0xFF &&
        contenu[1] == 0xD8 &&
        contenu[2] == 0xFF;
    final estZip =
        contenu.length >= 4 &&
        contenu[0] == 0x50 &&
        contenu[1] == 0x4B &&
        contenu[2] == 0x03 &&
        contenu[3] == 0x04;
    final extensionNormalisee = extension?.trim().toLowerCase().replaceFirst(
      '.',
      '',
    );
    final extensionFinale = extensionNormalisee?.isNotEmpty == true
        ? extensionNormalisee!
        : estPdf
        ? 'pdf'
        : estPng
        ? 'png'
        : estJpeg
        ? 'jpg'
        : estZip
        ? 'docx'
        : 'bin';
    final nomSain = nom
        .replaceAll(RegExp(r'[^a-zA-Z0-9._-]'), '_')
        .replaceAll(
          RegExp(r'\.(pdf|docx?|png|jpe?g|bin)$', caseSensitive: false),
          '',
        );
    final fichier = File(
      '${Directory.systemTemp.path}${Platform.pathSeparator}$nomSain.$extensionFinale',
    );
    await fichier.writeAsBytes(contenu, flush: true);
    return fichier.path;
  }

  Future<String> telechargerPdf({
    required String endpoint,
    required String nom,
  }) async {
    final base = Uri.parse(ConfigurationApi.urlBase);
    final chemin = endpoint.startsWith('/') ? endpoint : '/$endpoint';
    final uri = base.replace(
      path: chemin.split('?').first,
      query: Uri.parse(endpoint).query,
    );
    final jeton = await SessionAuthentificationService.jeton();
    if (jeton == null || jeton.isEmpty) {
      throw const ErreurApi(
        code: 'SESSION_ABSENTE',
        message: 'Votre session a expiré.',
      );
    }

    final client = HttpClient();
    try {
      final requete = await client
          .getUrl(uri)
          .timeout(ConfigurationApi.dureeExpiration);
      requete.headers.set(HttpHeaders.authorizationHeader, 'Bearer $jeton');
      requete.headers.set(HttpHeaders.acceptHeader, 'application/pdf');
      requete.headers.set('ngrok-skip-browser-warning', 'true');
      final reponse = await requete.close().timeout(
        ConfigurationApi.dureeExpiration,
      );
      if (reponse.statusCode != HttpStatus.ok) {
        throw ErreurApi(
          code: 'HTTP_${reponse.statusCode}',
          message: 'Le document est indisponible sur le serveur.',
        );
      }
      final nomSain = nom.replaceAll(RegExp(r'[^a-zA-Z0-9._-]'), '_');
      final fichier = File(
        '${Directory.systemTemp.path}${Platform.pathSeparator}$nomSain.pdf',
      );
      await reponse.pipe(fichier.openWrite());
      return fichier.path;
    } finally {
      client.close(force: true);
    }
  }
}
