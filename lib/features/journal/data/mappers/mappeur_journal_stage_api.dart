/// Normalise le contrat public du journal de stage sans déduire les droits
/// depuis le statut. Les indicateurs `editable`, `can_submit` et les actions
/// retournées par le serveur restent la source de vérité.
abstract final class MappeurJournalStageApi {
  static Map<String, dynamic> normaliserReponse(Map<String, dynamic> donnees) {
    return <String, dynamic>{
      ...donnees,
      'items': _liste(
        donnees['items'],
      ).map(normaliserEntree).toList(growable: false),
      'stats': _map(donnees['stats']),
      'pagination': _map(donnees['pagination']),
      'filters': _map(donnees['filters']),
      'available_filters': _map(donnees['available_filters']),
    };
  }

  static Map<String, dynamic> normaliserAction(Map<String, dynamic> donnees) {
    final entree = _map(donnees['entry']);
    return <String, dynamic>{
      ...donnees,
      'entry': entree.isEmpty ? entree : normaliserEntree(entree),
    };
  }

  static Map<String, dynamic> normaliserEntree(Map<String, dynamic> json) {
    final statut = _normaliserStatut(json['status'] ?? json['statut']);
    final activities = _liste(
      json['activities'],
    ).map(_normaliserActivite).toList(growable: false);
    final assignment = _map(json['assignment']);
    final rotation = _map(json['rotation']);
    final campaign = _map(json['campaign']);
    final hospital = _map(json['hospital']);
    final service = _map(json['service']);
    final unit = _map(json['unit']);
    final actionsBrutes = _map(json['actions']);
    final editable = json['editable'] == true;
    final canSubmit = json['can_submit'] == true;
    final edit = _action(actionsBrutes['edit'], valeurParDefaut: editable);
    final submit = _action(actionsBrutes['submit'], valeurParDefaut: canSubmit);

    return <String, dynamic>{
      ...json,
      'uuid': json['uuid']?.toString(),
      'status': statut,
      'statut': statut,
      'editable': edit['allowed'] == true,
      'can_submit': submit['allowed'] == true,
      'activities': activities,
      'activities_count':
          _entier(json['activities_count']) ?? activities.length,
      'assignment': assignment,
      'rotation': rotation,
      'campaign': campaign,
      'hospital': hospital,
      'service': service.isEmpty ? null : service,
      'unit': unit.isEmpty ? null : unit,
      'actions': <String, dynamic>{
        ...actionsBrutes,
        'edit': edit,
        'submit': submit,
      },
      'assignment_uuid': assignment['uuid'] ?? json['assignment_uuid'],
      'rotation_uuid': rotation['uuid'] ?? json['rotation_uuid'],
      'hospital_name': hospital['name'] ?? json['hospital_name'],
      'service_name': service['name'] ?? json['service_name'],
      'unit_name': unit['name'] ?? json['unit_name'] ?? service['name'],
    };
  }

  static Map<String, dynamic> _normaliserActivite(Map<String, dynamic> json) =>
      <String, dynamic>{
        ...json,
        'uuid': json['uuid']?.toString(),
        'activity': json['activity'] ?? json['title'] ?? json['intitule'],
        'category': json['category'] ?? json['type_activite'],
        'involvement_level':
            json['involvement_level'] ?? json['niveau_implication'],
        'quantity': _entier(json['quantity'] ?? json['quantite']) ?? 1,
      };

  static Map<String, dynamic> _action(
    Object? valeur, {
    required bool valeurParDefaut,
  }) {
    final action = _map(valeur);
    return <String, dynamic>{
      ...action,
      'allowed': action.containsKey('allowed')
          ? action['allowed'] == true
          : valeurParDefaut,
    };
  }

  static String _normaliserStatut(Object? valeur) =>
      switch (valeur?.toString().toUpperCase()) {
        'SOUMIS' => 'SOUMISE',
        'VALIDE' || 'VALIDÉ' => 'VALIDEE',
        'REJETE' || 'REJETÉ' => 'REJETEE',
        final statut => statut ?? '',
      };

  static int? _entier(Object? valeur) =>
      valeur is num ? valeur.toInt() : int.tryParse(valeur?.toString() ?? '');

  static Map<String, dynamic> _map(Object? valeur) =>
      valeur is Map ? Map<String, dynamic>.from(valeur) : <String, dynamic>{};

  static List<Map<String, dynamic>> _liste(Object? valeur) => valeur is List
      ? valeur
            .whereType<Map>()
            .map((item) => Map<String, dynamic>.from(item))
            .toList()
      : <Map<String, dynamic>>[];
}
