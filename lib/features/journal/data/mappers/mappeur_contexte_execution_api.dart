import 'mappeur_presence_api.dart';

/// Normalise le contrat canonique de `GET /student/execution-context`.
///
/// Les blocs historiques `execution` et `punch` restent disponibles pour les
/// écrans existants, mais ils sont dérivés du bloc canonique `context`.
abstract final class MappeurContexteExecutionApi {
  static Map<String, dynamic> normaliser(Map<String, dynamic> donnees) {
    final contextBrut = _map(donnees['context']);
    if (contextBrut.isEmpty) return donnees;

    final assignment = _map(contextBrut['assignment']);
    final campaign = _map(contextBrut['campaign']);
    final hospital = _map(contextBrut['hospital']);
    final department = _map(contextBrut['department']);
    final currentRotation = _rotation(contextBrut['current_rotation']);
    final nextRotation = _rotation(contextBrut['next_rotation']);
    final attendanceBrute = _map(contextBrut['attendance']);
    final attendance = attendanceBrute.isEmpty
        ? <String, dynamic>{}
        : MappeurPresenceApi.normaliserPresence(attendanceBrute);
    final actions = _normaliserActions(contextBrut['actions']);
    final capabilities = _map(contextBrut['capabilities']);

    final context = <String, dynamic>{
      ...contextBrut,
      'assignment': assignment,
      'campaign': campaign,
      'hospital': hospital,
      'department': department,
      'current_rotation': currentRotation,
      'next_rotation': nextRotation,
      'attendance': attendance,
      'actions': actions,
      'capabilities': capabilities,
    };

    final arrivalAllowed = _map(actions['arrival'])['allowed'] == true;
    final departureAllowed = _map(actions['departure'])['allowed'] == true;
    final logbookAllowed = _map(actions['logbook'])['allowed'] == true;
    final canAttendance = capabilities['attendance'] == true;
    final legacyExecution = _map(donnees['execution']);
    final legacyPunch = _map(donnees['punch']);

    final execution = <String, dynamic>{
      ...legacyExecution,
      'date': context['date'],
      'current_rotation': currentRotation,
      'next_rotation': nextRotation,
      'can_logbook': capabilities.containsKey('logbook')
          ? capabilities['logbook'] == true && logbookAllowed
          : logbookAllowed,
      'can_attendance': canAttendance,
      'can_evaluation': capabilities['evaluation'] == true,
      'reason': context['reason'],
      'unlock_date': context['unlock_date'],
    };

    final nextAction = arrivalAllowed
        ? 'ARRIVEE'
        : departureAllowed
        ? 'DEPART'
        : legacyPunch['next_action']?.toString().toUpperCase() ?? 'TERMINE';
    final punch = <String, dynamic>{
      ...legacyPunch,
      'date': context['date'],
      'assignment_id': assignment['id'] ?? legacyPunch['assignment_id'],
      'assignment_uuid': assignment['uuid'],
      'rotation': currentRotation,
      'attendance': attendance,
      'can_punch': canAttendance && (arrivalAllowed || departureAllowed),
      'next_action': nextAction,
      'reason': context['reason'] ?? legacyPunch['reason'],
    };

    return <String, dynamic>{
      ...donnees,
      'context': context,
      'execution': execution,
      'punch': punch,
    };
  }

  static Map<String, dynamic>? _rotation(Object? valeur) {
    final rotation = _map(valeur);
    if (rotation.isEmpty) return null;
    final period = _map(rotation['period']);
    final service = _map(rotation['service']);
    final unit = _map(rotation['unit']);
    final supervisor = _map(rotation['supervisor']);

    return <String, dynamic>{
      ...rotation,
      'status': rotation['status'] ?? rotation['statut'],
      'statut': rotation['status'] ?? rotation['statut'],
      'period': period,
      'service': service,
      'unit': unit.isEmpty ? null : unit,
      'supervisor': supervisor.isEmpty ? null : supervisor,
      'service_name': service['name'] ?? rotation['service_name'],
      'unit_name': unit['name'] ?? rotation['unit_name'],
      'supervisor_name': supervisor['name'] ?? rotation['supervisor_name'],
    };
  }

  static Map<String, dynamic> _normaliserActions(Object? valeur) {
    final actions = _map(valeur);
    return <String, dynamic>{
      ...actions,
      'arrival': _map(actions['arrival']),
      'departure': _map(actions['departure']),
      'logbook': _map(actions['logbook']),
    };
  }

  static Map<String, dynamic> _map(Object? valeur) =>
      valeur is Map ? Map<String, dynamic>.from(valeur) : <String, dynamic>{};
}
