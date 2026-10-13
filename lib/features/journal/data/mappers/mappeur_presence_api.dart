/// Normalise le contrat de `GET /student/attendance` sans ajouter de données
/// métier qui ne proviennent pas de l'API.
abstract final class MappeurPresenceApi {
  static Map<String, dynamic> normaliserReponse(Map<String, dynamic> donnees) {
    final items = _liste(
      donnees['items'],
    ).map(normaliserPresence).toList(growable: false);

    return <String, dynamic>{
      ...donnees,
      'items': items,
      'stats': _map(donnees['stats']),
      'pagination': _map(donnees['pagination']),
      'filters': _map(donnees['filters']),
      'available_filters': _map(donnees['available_filters']),
    };
  }

  static Map<String, dynamic> normaliserPresence(Map<String, dynamic> json) {
    final rotation = _map(json['rotation']);
    final assignment = _map(json['assignment']);
    final campaign = _map(json['campaign']);
    final hospital = _map(json['hospital']);
    final unit = _map(json['unit']);
    final validator = _map(json['validator']);
    final status = json['status'] ?? json['statut'];
    final arrivalTime =
        json['arrival_time'] ?? json['heure_arrivee'] ?? json['time_in'];
    final departureTime =
        json['departure_time'] ?? json['heure_depart'] ?? json['time_out'];

    return <String, dynamic>{
      ...json,
      'uuid': json['uuid']?.toString(),
      'date': json['date'] ?? json['date_presence'],
      'status': status,
      'arrival_time': arrivalTime,
      'departure_time': departureTime,
      'source': json['source'],
      'minutes_late': _entier(json['minutes_late']) ?? 0,
      'duration_minutes': _entier(json['duration_minutes']),
      'validated': json['validated'] == true,
      'rotation': rotation,
      'assignment': assignment,
      'campaign': campaign,
      'hospital': hospital,
      'unit': unit.isEmpty ? null : unit,
      'validator': validator.isEmpty ? null : validator,
      // Alias de compatibilité calculés uniquement depuis la réponse.
      'statut': status,
      'time_in': arrivalTime,
      'time_out': departureTime,
      'heure_arrivee': arrivalTime,
      'heure_depart': departureTime,
      'hospital_name': hospital['name'] ?? json['hospital_name'],
      'unit_name': unit['name'] ?? json['unit_name'],
      'assignment_uuid': assignment['uuid'] ?? json['assignment_uuid'],
      'rotation_uuid': rotation['uuid'] ?? json['rotation_uuid'],
    };
  }

  static Map<String, dynamic> normaliserPointage(Map<String, dynamic> donnees) {
    final punchBrut = _map(donnees['punch']);
    if (punchBrut.isEmpty) return {...donnees, 'punch': punchBrut};

    final attendanceBrute = _map(punchBrut['attendance']);
    final attendance = attendanceBrute.isEmpty
        ? <String, dynamic>{}
        : normaliserPresence(attendanceBrute);

    return <String, dynamic>{
      ...donnees,
      'punch': <String, dynamic>{
        ...punchBrut,
        'rotation': _map(punchBrut['rotation']),
        'attendance': attendance,
        'can_punch': punchBrut['can_punch'] == true,
        'next_action': punchBrut['next_action']?.toString().toUpperCase(),
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

  static int? _entier(Object? valeur) =>
      valeur is num ? valeur.toInt() : int.tryParse(valeur?.toString() ?? '');
}
