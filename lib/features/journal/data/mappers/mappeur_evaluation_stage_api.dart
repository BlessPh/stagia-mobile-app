/// Normalise les évaluations publiées à l'étudiant et leur contexte complet.
abstract final class MappeurEvaluationStageApi {
  static Map<String, dynamic> normaliserReponse(Map<String, dynamic> donnees) {
    final finale = _map(donnees['final_evaluation']);
    return <String, dynamic>{
      ...donnees,
      'items': _liste(
        donnees['items'],
      ).map(normaliserEvaluation).toList(growable: false),
      'stats': _map(donnees['stats']),
      'final_evaluation': finale.isEmpty ? null : normaliserEvaluation(finale),
      'pagination': _map(donnees['pagination']),
      'filters': _map(donnees['filters']),
      'available_filters': _map(donnees['available_filters']),
    };
  }

  static Map<String, dynamic> normaliserEvaluation(Map<String, dynamic> json) {
    final evaluator = _map(json['evaluator']);
    final rotation = _map(json['rotation']);
    final assignment = _map(json['assignment']);
    final campaign = _map(json['campaign']);
    final hospital = _map(json['hospital']);
    final unit = _map(json['unit']);
    final scoreSummary = _map(json['score_summary']);
    final scores = _liste(
      json['scores'],
    ).map(_normaliserScore).toList(growable: false);
    final note = _decimal(json['note'] ?? json['score']);

    return <String, dynamic>{
      ...json,
      'uuid': json['uuid']?.toString(),
      'type': json['type']?.toString().toUpperCase(),
      'status': json['status']?.toString().toUpperCase(),
      'note': note,
      'score': note,
      'score_summary': scoreSummary,
      'scores': scores,
      'evaluator': evaluator,
      'rotation': rotation,
      'assignment': assignment,
      'campaign': campaign,
      'hospital': hospital,
      'unit': unit.isEmpty ? null : unit,
      'evaluator_name':
          evaluator['name'] ?? json['evaluator_name'] ?? json['supervisor'],
      'evaluator_function': evaluator['function'] ?? json['evaluator_function'],
      'assignment_uuid':
          assignment['uuid'] ??
          assignment['assignment_uuid'] ??
          json['assignment_uuid'],
      'rotation_uuid': rotation['uuid'] ?? json['rotation_uuid'],
      'campaign_title':
          campaign['title'] ?? campaign['name'] ?? json['campaign_title'],
      'hospital_name': hospital['name'] ?? json['hospital_name'],
      'unit_name': unit['name'] ?? json['unit_name'],
    };
  }

  static Map<String, dynamic> _normaliserScore(Map<String, dynamic> json) {
    final note = _decimal(json['note'] ?? json['score']);
    final maximum = _decimal(json['note_max'] ?? json['maximum']);
    final percentage = note != null && maximum != null && maximum > 0
        ? note / maximum * 100
        : _decimal(json['percentage']);
    return <String, dynamic>{
      ...json,
      'nom': json['nom'] ?? json['name'] ?? json['title'],
      'categorie': json['categorie'] ?? json['category'],
      'note': note,
      'note_max': maximum,
      'poids': _decimal(json['poids'] ?? json['weight']),
      'commentaire': json['commentaire'] ?? json['comment'],
      'percentage': percentage,
    };
  }

  static double? _decimal(Object? valeur) => valeur is num
      ? valeur.toDouble()
      : double.tryParse(valeur?.toString() ?? '');

  static Map<String, dynamic> _map(Object? valeur) =>
      valeur is Map ? Map<String, dynamic>.from(valeur) : <String, dynamic>{};

  static List<Map<String, dynamic>> _liste(Object? valeur) => valeur is List
      ? valeur
            .whereType<Map>()
            .map((item) => Map<String, dynamic>.from(item))
            .toList()
      : <Map<String, dynamic>>[];
}
