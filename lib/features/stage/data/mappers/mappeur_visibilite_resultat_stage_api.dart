/// Applique les règles de visibilité du contrat étudiant v1.9.
///
/// Une note finale et un certificat ne sont publics qu'après validation de la
/// clôture hospitalière. Le mobile garde cette protection même si une ancienne
/// version du serveur renvoie encore prématurément ces valeurs.
abstract final class MappeurVisibiliteResultatStageApi {
  static Map<String, dynamic> normaliserTableauDeBord(
    Map<String, dynamic> donnees,
  ) {
    final stage = _map(donnees['current_stage']);
    if (stage.isEmpty) return donnees;
    return {...donnees, 'current_stage': normaliserElement(stage)};
  }

  static Map<String, dynamic> normaliserCollection(
    Map<String, dynamic> donnees,
  ) => {
    ...donnees,
    'items': _liste(
      donnees['items'],
    ).map(normaliserElement).toList(growable: false),
  };

  static Map<String, dynamic> normaliserElement(Map<String, dynamic> json) {
    final completion = _map(json['completion']);
    final statut = (json['completion_status'] ?? completion['status'])
        ?.toString()
        .toUpperCase();
    if (statut == 'VALIDE') return Map<String, dynamic>.from(json);

    final certificat = _map(json['certificate']);
    return <String, dynamic>{
      ...json,
      if (json.containsKey('note_finale')) 'note_finale': null,
      if (json.containsKey('final_score')) 'final_score': null,
      if (completion.isNotEmpty)
        'completion': <String, dynamic>{
          ...completion,
          if (completion.containsKey('score')) 'score': null,
          if (completion.containsKey('final_score')) 'final_score': null,
        },
      if (json.containsKey('certificate_uuid')) 'certificate_uuid': null,
      if (json.containsKey('certificate_reference'))
        'certificate_reference': null,
      if (json.containsKey('certificate_type')) 'certificate_type': null,
      if (json.containsKey('certificate_status')) 'certificate_status': null,
      if (json.containsKey('certificate_generated_at'))
        'certificate_generated_at': null,
      if (json.containsKey('certificate_available'))
        'certificate_available': false,
      if (certificat.isNotEmpty)
        'certificate': <String, dynamic>{
          ...certificat,
          'available': false,
          if (certificat.containsKey('uuid')) 'uuid': null,
          if (certificat.containsKey('reference')) 'reference': null,
          if (certificat.containsKey('file_endpoint')) 'file_endpoint': null,
          if (certificat.containsKey('download_endpoint'))
            'download_endpoint': null,
        },
    };
  }

  static Map<String, dynamic> _map(Object? valeur) =>
      valeur is Map ? Map<String, dynamic>.from(valeur) : <String, dynamic>{};

  static List<Map<String, dynamic>> _liste(Object? valeur) => valeur is List
      ? valeur
            .whereType<Map>()
            .map((item) => Map<String, dynamic>.from(item))
            .toList()
      : <Map<String, dynamic>>[];
}
