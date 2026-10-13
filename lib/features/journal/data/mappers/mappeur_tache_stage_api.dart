/// Normalise les tâches retournées par `/student/tasks` et par ses routes
/// d'action. Aucun droit n'est déduit du statut : `actions.*.allowed` reste la
/// source de vérité.
abstract final class MappeurTacheStageApi {
  static Map<String, dynamic> normaliserReponse(Map<String, dynamic> donnees) {
    final items = _liste(
      donnees['items'],
    ).map(normaliserTache).toList(growable: false);
    return <String, dynamic>{
      ...donnees,
      'items': items,
      'stats': _map(donnees['stats']),
      'pagination': _map(donnees['pagination']),
      'filters': _map(donnees['filters']),
      'available_filters': _map(donnees['available_filters']),
    };
  }

  static Map<String, dynamic> normaliserAction(Map<String, dynamic> donnees) {
    final task = _map(donnees['task']);
    return <String, dynamic>{
      ...donnees,
      'task': task.isEmpty ? task : normaliserTache(task),
    };
  }

  static Map<String, dynamic> normaliserTache(Map<String, dynamic> json) {
    final assignment = _map(json['assignment']);
    final rotation = _map(json['rotation']);
    final hospital = _map(json['hospital']);
    final service = _map(json['service']);
    final unit = _map(json['unit']);
    final trainingPlanItem = _map(json['training_plan_item']);
    final actions = _normaliserActions(json['actions']);
    final title = json['title'] ?? json['titre'];
    final priority = json['priority'] ?? json['priorite'];
    final status = json['status'] ?? json['statut'];
    final dueDate = json['due_date'] ?? json['date_echeance'];

    return <String, dynamic>{
      ...json,
      'uuid': json['uuid']?.toString(),
      'title': title,
      'priority': priority,
      'status': status,
      'due_date': dueDate,
      'training_plan_item': trainingPlanItem.isEmpty ? null : trainingPlanItem,
      'assignment': assignment,
      'rotation': rotation,
      'hospital': hospital,
      'service': service,
      'unit': unit.isEmpty ? null : unit,
      'actions': actions,
      // Alias réels utilisés par les composants historiques.
      'titre': title,
      'priorite': priority,
      'statut': status,
      'date_echeance': dueDate,
      'commentaire_encadreur':
          json['supervisor_comment'] ?? json['commentaire_encadreur'],
      'hospital_name': hospital['name'] ?? json['hospital_name'],
      'host_name': hospital['name'] ?? json['host_name'],
      'service_name': service['name'] ?? json['service_name'],
      'unit_name': unit['name'] ?? json['unit_name'] ?? service['name'],
      'assignment_uuid': assignment['uuid'] ?? json['assignment_uuid'],
      'rotation_uuid': rotation['uuid'] ?? json['rotation_uuid'],
    };
  }

  static Map<String, dynamic> _normaliserActions(Object? valeur) {
    final actions = _map(valeur);
    return <String, dynamic>{
      ...actions,
      'start': _map(actions['start']),
      'comment': _map(actions['comment']),
      'complete': _map(actions['complete']),
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
