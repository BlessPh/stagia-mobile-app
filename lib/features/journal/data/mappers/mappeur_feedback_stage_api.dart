/// Normalise les feedbacks visibles par l'étudiant. L'action `read` renvoyée
/// par le serveur reste la seule source de vérité pour le marquage comme lu.
abstract final class MappeurFeedbackStageApi {
  static Map<String, dynamic> normaliserReponse(Map<String, dynamic> donnees) {
    return <String, dynamic>{
      ...donnees,
      'items': _liste(
        donnees['items'],
      ).map(normaliserFeedback).toList(growable: false),
      'stats': _map(donnees['stats']),
      'pagination': _map(donnees['pagination']),
      'filters': _map(donnees['filters']),
      'available_filters': _map(donnees['available_filters']),
    };
  }

  static Map<String, dynamic> normaliserAction(Map<String, dynamic> donnees) {
    final feedback = _map(donnees['feedback']);
    return <String, dynamic>{
      ...donnees,
      'feedback': feedback.isEmpty ? feedback : normaliserFeedback(feedback),
    };
  }

  static Map<String, dynamic> normaliserFeedback(Map<String, dynamic> json) {
    final assignment = _map(json['assignment']);
    final rotation = _map(json['rotation']);
    final hospital = _map(json['hospital']);
    final unit = _map(json['unit']);
    final author = _map(json['author']);
    final actions = _map(json['actions']);
    final read = _map(actions['read']);
    final seen = json['seen'] == true;

    return <String, dynamic>{
      ...json,
      'uuid': json['uuid']?.toString(),
      'type': json['type']?.toString().toUpperCase(),
      'seen': seen,
      'assignment': assignment,
      'rotation': rotation,
      'hospital': hospital,
      'unit': unit.isEmpty ? null : unit,
      'author': author,
      'actions': <String, dynamic>{
        ...actions,
        'read': <String, dynamic>{...read, 'allowed': read['allowed'] == true},
      },
      'assignment_uuid': assignment['uuid'] ?? json['assignment_uuid'],
      'rotation_uuid': rotation['uuid'] ?? json['rotation_uuid'],
      'hospital_name': hospital['name'] ?? json['hospital_name'],
      'unit_name': unit['name'] ?? json['unit_name'],
      'author_name': author['name'] ?? json['author_name'],
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
