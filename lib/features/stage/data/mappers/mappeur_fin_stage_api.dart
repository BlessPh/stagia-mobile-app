/// Normalise et protège les données publiques de fin de stage.
///
/// Le mobile ne doit jamais exposer une note, une décision ou un fichier avant
/// la validation prévue par le contrat, même si un ancien serveur renvoie ces
/// champs prématurément.
abstract final class MappeurFinStageApi {
  static Map<String, dynamic> completions(Map<String, dynamic> donnees) => {
    ...donnees,
    'items': _items(donnees)
        .map((item) {
          final statut = item['status']?.toString().toUpperCase();
          return {
            ...item,
            if (statut != 'VALIDE' && item.containsKey('score')) 'score': null,
          };
        })
        .toList(growable: false),
  };

  static Map<String, dynamic> resultats(Map<String, dynamic> donnees) => {
    ...donnees,
    'items': _items(donnees)
        .map((item) {
          final processus = _map(item['administrative_process']);
          final transmission = _map(processus['university_transmission']);
          final statutTransmission = transmission['status']
              ?.toString()
              .toUpperCase();
          final valide = const {
            'VALIDE',
            'ARCHIVE',
          }.contains(statutTransmission);
          return {
            ...item,
            if (!valide) 'decision': null,
            if (!valide) 'score': null,
            if (!valide) 'appreciation': null,
            if (item['document'] is Map)
              'document': _document(
                Map<String, dynamic>.from(item['document'] as Map),
                resultatValide: valide,
              ),
          };
        })
        .toList(growable: false),
  };

  static Map<String, dynamic> documents(Map<String, dynamic> donnees) => {
    ...donnees,
    'items': _items(donnees)
        .map((item) => _document(item, resultatValide: true))
        .toList(growable: false),
  };

  static Map<String, dynamic> _document(
    Map<String, dynamic> document, {
    required bool resultatValide,
  }) {
    final disponible = document['available'] == true;
    final genere = document['status']?.toString().toUpperCase() == 'GENERE';
    final statutResultat = document['university_result_status']
        ?.toString()
        .toUpperCase();
    final validationDocument =
        statutResultat == null ||
        const {'VALIDE', 'ARCHIVE'}.contains(statutResultat);
    final fichierAccessible =
        resultatValide && disponible && genere && validationDocument;
    return {
      ...document,
      if (!fichierAccessible) 'available': false,
      if (!fichierAccessible) 'file_endpoint': null,
      if (!fichierAccessible) 'download_endpoint': null,
    };
  }

  static List<Map<String, dynamic>> _items(Map<String, dynamic> donnees) =>
      donnees['items'] is List
      ? (donnees['items'] as List)
            .whereType<Map>()
            .map(Map<String, dynamic>.from)
            .toList(growable: false)
      : <Map<String, dynamic>>[];

  static Map<String, dynamic> _map(Object? valeur) =>
      valeur is Map ? Map<String, dynamic>.from(valeur) : <String, dynamic>{};
}
