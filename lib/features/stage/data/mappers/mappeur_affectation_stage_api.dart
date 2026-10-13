/// Normalise le contrat de `GET /student/stages` pour tous les écrans mobiles.
///
/// Le mappeur conserve les objets canoniques (`hospital`, `campaign`,
/// `planning`, etc.) et ajoute uniquement des alias de compatibilité calculés
/// à partir de ces objets. Il n'injecte aucune donnée métier fictive.
abstract final class MappeurAffectationStageApi {
  static Map<String, dynamic> normaliserReponse(Map<String, dynamic> donnees) {
    final items = _liste(
      donnees['items'],
    ).map(depuisJson).toList(growable: false);
    return {...donnees, 'items': items};
  }

  static Map<String, dynamic> depuisJson(Map<String, dynamic> json) {
    final hospital = _map(json['hospital']);
    final campaign = _map(json['campaign']);
    final department = _map(json['department']);
    final period = _periode(json['period'], json);
    final planningBrut = _map(json['planning']);

    final currentRotation = _rotationOptionnelle(
      planningBrut['current_rotation'] ?? json['current_rotation'],
    );
    final nextRotation = _rotationOptionnelle(
      planningBrut['next_rotation'] ?? json['next_rotation'],
    );

    final rotations = _liste(
      planningBrut['rotations'] ??
          json['rotations'] ??
          json['rotation_items'] ??
          _map(json['parcours'])['rotations'],
    ).map(_normaliserRotation).toList();

    _fusionnerRotationDetaillee(rotations, currentRotation);
    _fusionnerRotationDetaillee(rotations, nextRotation);
    rotations.sort(_comparerRotations);

    final planning = <String, dynamic>{
      ...planningBrut,
      'current_rotation': currentRotation,
      'next_rotation': nextRotation,
      'rotations': rotations,
      'total': _entier(planningBrut['total']) ?? rotations.length,
    };

    final rotationActive = currentRotation;
    final serviceActif = _map(rotationActive?['service']);
    final uniteActive = _map(rotationActive?['unit']);
    final superviseurActif = _map(rotationActive?['supervisor']);

    return <String, dynamic>{
      ...json,
      'assignment_id': json['assignment_id'] ?? json['id'],
      'assignment_uuid': json['assignment_uuid'] ?? json['uuid']?.toString(),
      'assignment_status':
          json['assignment_status'] ?? json['status'] ?? json['statut'],
      'workflow_status': json['workflow_status'],
      'department': department,
      'hospital': hospital,
      'campaign': campaign,
      'period': period,
      'planning': planning,
      'rotations': rotations,
      // Alias de compatibilité issus exclusivement du contrat canonique.
      'hospital_name': hospital['name'] ?? json['hospital_name'],
      'campaign_title': campaign['title'] ?? json['campaign_title'],
      'date_debut': period['start_date'] ?? json['date_debut'],
      'date_fin': period['end_date'] ?? json['date_fin'],
      'department_name': department['name'] ?? json['department_name'],
      'service_name': serviceActif['name'] ?? json['service_name'],
      'unit_name': uniteActive['name'] ?? json['unit_name'],
      'supervisor_name': superviseurActif['name'] ?? json['supervisor_name'],
      'supervisor_function':
          superviseurActif['function'] ?? json['supervisor_function'],
      'total_rotations': planning['total'],
    };
  }

  static bool estActive(Map<String, dynamic> affectation) =>
      _statut(affectation) == 'ACTIVE';

  static bool estPlanifiee(Map<String, dynamic> affectation) =>
      _statut(affectation) == 'PLANIFIEE';

  static bool estTerminee(Map<String, dynamic> affectation) =>
      _statut(affectation) == 'TERMINEE';

  static Map<String, dynamic>? selectionnerAffectationPrincipale(
    List<Map<String, dynamic>> affectations,
  ) {
    if (affectations.isEmpty) return null;
    for (final affectation in affectations) {
      if (estActive(affectation)) return affectation;
    }
    for (final affectation in affectations) {
      if (estPlanifiee(affectation)) return affectation;
    }
    for (final affectation in affectations) {
      if (estTerminee(affectation)) return affectation;
    }
    return affectations.first;
  }

  static Map<String, dynamic> _normaliserRotation(Map<String, dynamic> json) {
    final service = _map(json['service']);
    final unit = _map(json['unit']);
    final supervisor = _map(json['supervisor']);
    final period = _periode(json['period'], json);
    final status = json['status'] ?? json['statut'];

    return <String, dynamic>{
      ...json,
      'id': json['id'] ?? json['rotation_id'],
      'uuid': json['uuid'] ?? json['rotation_uuid'],
      'position': json['position'],
      'sequence': json['sequence'],
      'status': status,
      'period': period,
      'service': service,
      'unit': unit.isEmpty ? null : unit,
      'supervisor': supervisor.isEmpty ? null : supervisor,
      'service_name': service['name'] ?? json['service_name'],
      'unit_name': unit['name'] ?? json['unit_name'],
      'supervisor_name': supervisor['name'] ?? json['supervisor_name'],
      'supervisor_function':
          supervisor['function'] ?? json['supervisor_function'],
      'date_debut': period['start_date'] ?? json['date_debut'],
      'date_fin': period['end_date'] ?? json['date_fin'],
      'statut': status,
    };
  }

  static Map<String, dynamic>? _rotationOptionnelle(Object? valeur) {
    final rotation = _map(valeur);
    return rotation.isEmpty ? null : _normaliserRotation(rotation);
  }

  static void _fusionnerRotationDetaillee(
    List<Map<String, dynamic>> rotations,
    Map<String, dynamic>? detail,
  ) {
    if (detail == null) return;
    final uuid = detail['uuid']?.toString();
    final id = detail['id']?.toString();
    final index = rotations.indexWhere((rotation) {
      if (uuid != null && uuid.isNotEmpty) {
        return rotation['uuid']?.toString() == uuid;
      }
      return id != null && id.isNotEmpty && rotation['id']?.toString() == id;
    });
    if (index < 0) {
      rotations.add(detail);
      return;
    }
    rotations[index] = _normaliserRotation({...rotations[index], ...detail});
  }

  static int _comparerRotations(
    Map<String, dynamic> a,
    Map<String, dynamic> b,
  ) {
    final sequenceA = _entier(a['sequence']) ?? 1 << 30;
    final sequenceB = _entier(b['sequence']) ?? 1 << 30;
    final parSequence = sequenceA.compareTo(sequenceB);
    if (parSequence != 0) return parSequence;

    final dateA = _map(a['period'])['start_date']?.toString() ?? '';
    final dateB = _map(b['period'])['start_date']?.toString() ?? '';
    final parDate = dateA.compareTo(dateB);
    if (parDate != 0) return parDate;

    return (_entier(a['id']) ?? 1 << 30).compareTo(_entier(b['id']) ?? 1 << 30);
  }

  static Map<String, dynamic> _periode(
    Object? valeur,
    Map<String, dynamic> secours,
  ) {
    final periode = _map(valeur);
    return <String, dynamic>{
      ...periode,
      'start_date':
          periode['start_date'] ??
          secours['start_date'] ??
          secours['date_debut'],
      'end_date':
          periode['end_date'] ?? secours['end_date'] ?? secours['date_fin'],
    };
  }

  static String _statut(Map<String, dynamic> affectation) =>
      (affectation['assignment_status'] ??
              affectation['status'] ??
              affectation['statut'])
          ?.toString()
          .toUpperCase() ??
      '';

  static Map<String, dynamic> _map(Object? valeur) =>
      valeur is Map ? Map<String, dynamic>.from(valeur) : <String, dynamic>{};

  static List<Map<String, dynamic>> _liste(Object? valeur) => valeur is List
      ? valeur
            .whereType<Map>()
            .map((item) => Map<String, dynamic>.from(item))
            .toList()
      : <Map<String, dynamic>>[];

  static int? _entier(Object? valeur) =>
      valeur is num ? valeur.toInt() : int.tryParse(valeur?.toString() ?? '');
}
