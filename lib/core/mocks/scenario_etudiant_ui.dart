import 'package:flutter/foundation.dart';

import '../network/endpoints_api.dart';

/// Scénario unique utilisé pour vérifier visuellement tout le parcours étudiant.
///
/// Les objets exposés ici reprennent les noms de champs du contrat API. Les
/// sources distantes continuent donc de passer par leurs mappeurs habituels :
/// le mode mock ne constitue pas un second contrat applicatif.
abstract final class ScenarioEtudiantUi {
  static const assignmentUuid = 'aac385ad-2069-4929-b231-461e7da40c16';
  static const rotationActiveUuid = 'f22bd970-53f8-4657-9913-19bd434daf48';
  static const rotationNextUuid = '1d7d188a-c2cd-43c7-9640-ae66b729ab12';
  static const campaignActiveId = 37;
  static const campaignOpenId = 39;
  static const academicEnrollmentId = 43;

  static final ValueNotifier<int> changements = ValueNotifier<int>(0);
  static bool _arrivalDone = false;
  static bool _departureDone = false;

  static final List<Map<String, dynamic>> _tasks = [
    _task(
      uuid: 'task-001',
      title: 'Participer à la consultation pédiatrique',
      description: 'Réaliser l’anamnèse sous supervision.',
      priority: 'HAUTE',
      status: 'A_FAIRE',
      dueDate: '2026-10-10',
    ),
    _task(
      uuid: 'task-002',
      title: 'Présenter le dossier clinique du patient',
      description: 'Préparer puis présenter la synthèse clinique.',
      priority: 'URGENTE',
      status: 'EN_COURS',
      dueDate: '2026-10-10',
      studentComment: 'Dossier en cours de préparation.',
      startedAt: '2026-10-10 08:20:00',
    ),
    _task(
      uuid: 'task-003',
      title: 'Réviser le protocole de réhydratation',
      description: 'Relire le protocole avant la garde.',
      priority: 'NORMALE',
      status: 'TERMINEE',
      dueDate: '2026-10-09',
      completedAt: '2026-10-09 15:30:00',
    ),
    _task(
      uuid: 'task-004',
      title: 'Maîtriser l’examen du nourrisson',
      description: 'Objectif validé par le maître de stage.',
      priority: 'NORMALE',
      status: 'VALIDEE',
      dueDate: '2026-10-08',
      completedAt: '2026-10-08 14:30:00',
      validatedAt: '2026-10-08 16:00:00',
      supervisorComment: 'Objectif atteint avec sérieux.',
    ),
  ];

  static final List<Map<String, dynamic>> _logbook = [
    _logbookEntry(
      uuid: 'logbook-001',
      date: '2026-10-10',
      status: 'BROUILLON',
      summary: 'Participation aux consultations pédiatriques.',
      learning: 'Évaluation des signes de gravité chez l’enfant.',
      difficulties: 'Communication avec un enfant anxieux.',
    ),
    _logbookEntry(
      uuid: 'logbook-002',
      date: '2026-10-09',
      status: 'SOUMISE',
      summary: 'Visite médicale et surveillance des patients hospitalisés.',
      learning: 'Suivi de l’évolution clinique et transmissions ciblées.',
      submittedAt: '2026-10-09 17:10:00',
    ),
    _logbookEntry(
      uuid: 'logbook-003',
      date: '2026-10-08',
      status: 'VALIDEE',
      summary: 'Prise des constantes et examen clinique supervisé.',
      learning: 'Interprétation des constantes pédiatriques.',
      submittedAt: '2026-10-08 16:30:00',
      validatedAt: '2026-10-09 08:00:00',
      validatorComment: 'Compte rendu précis et structuré.',
    ),
    _logbookEntry(
      uuid: 'logbook-004',
      date: '2026-10-07',
      status: 'REJETEE',
      summary: 'Observation aux urgences pédiatriques.',
      learning: 'Triage des urgences.',
      validatorComment: 'Ajouter les actes réalisés et les résultats.',
    ),
  ];

  static final List<Map<String, dynamic>> _feedbacks = [
    _feedback(
      uuid: 'feedback-001',
      date: '2026-10-10',
      type: 'ENCOURAGEMENT',
      title: 'Bonne progression',
      comment: 'Bonne qualité d’écoute et d’anamnèse.',
      seen: false,
    ),
    _feedback(
      uuid: 'feedback-002',
      date: '2026-10-09',
      type: 'A_AMELIORER',
      title: 'Structurer la présentation',
      comment: 'Présentez les antécédents avant l’examen clinique.',
      seen: false,
    ),
    _feedback(
      uuid: 'feedback-003',
      date: '2026-10-08',
      type: 'OBSERVATION',
      title: 'Ponctualité',
      comment: 'Votre régularité est appréciée par l’équipe.',
      seen: true,
      seenAt: '2026-10-08 18:00:00',
    ),
  ];

  static Map<String, dynamic>? pourEndpoint(String endpoint) =>
      switch (endpoint) {
        EndpointsApi.profilEtudiant ||
        EndpointsApi.profilActifEtudiant => profile,
        EndpointsApi.rattachementsEtudiant => enrollments,
        EndpointsApi.parcoursAcademiqueEtudiant => academicPath,
        EndpointsApi.tableauDeBordEtudiant => dashboard,
        EndpointsApi.optionsStageEtudiant => stageOptions,
        EndpointsApi.candidaturesEtudiant => applications,
        EndpointsApi.reservationsEtudiant => reservations,
        EndpointsApi.admissionEtudiant => admissions,
        EndpointsApi.stagesEtudiant => stages,
        EndpointsApi.cloturesStageEtudiant => completions,
        EndpointsApi.resultatsStageEtudiant => results,
        EndpointsApi.documentsEtudiant => documentsOfficiels,
        EndpointsApi.rapportsStageEtudiant => rapportsStage,
        EndpointsApi.justificationsStageEtudiant => justificationsStage,
        EndpointsApi.contexteExecution ||
        EndpointsApi.contextePointage => executionContext,
        EndpointsApi.presencesEtudiant => attendance,
        EndpointsApi.tachesEtudiant => tasks,
        EndpointsApi.journalEtudiant => logbook,
        EndpointsApi.feedbacksEtudiant => feedbacks,
        EndpointsApi.evaluationsEtudiant => evaluations,
        _ => null,
      };

  static const profile = <String, dynamic>{
    'user': {
      'id': 55,
      'identifiant': 'STG-ETU-00000030',
      'nom': 'MBIMBU',
      'postnom': 'GEMIMA',
      'prenom': 'Gemima',
      'sexe': 'F',
      'date_naissance': '1993-07-12',
      'adresse': 'Avenue des Écoles',
      'ville': 'Kindu',
      'province': 'Maniema',
      'avatar_url': null,
      'telephone': '+243810000030',
      'email': 'gemima.mbimbu@isp.cd',
      'matricule': 'ISP-ETU-2026-000044',
      'actif': true,
      'statut_compte': 'ACTIF',
      'role': {'code': 'STAGIAIRE', 'nom': 'Stagiaire'},
      'roles': ['STAGIAIRE'],
    },
    'student': {
      'id': 30,
      'stagia_code': 'STG-ETU-00000030',
      'nom': 'MBIMBU',
      'postnom': 'GEMIMA',
      'prenom': 'Gemima',
      'sexe': 'F',
      'date_naissance': '1993-07-12',
      'adresse': 'Avenue des Écoles',
      'ville': 'Kindu',
      'province': 'Maniema',
      'avatar_url': null,
      'telephone': '+243810000030',
      'email': 'gemima.mbimbu@isp.cd',
      'matricule': 'ISP-ETU-2026-000044',
      'statut': 'ACTIF',
    },
  };

  static const enrollments = <String, dynamic>{
    'items': [
      {
        'enrollment_id': academicEnrollmentId,
        'matricule': 'ISP-ETU-2026-000044',
        'institutional_email': 'gemima.mbimbu@isp.cd',
        'enrollment_date': '2026-09-07',
        'status': 'ACTIF',
        'is_active': true,
        'university': {
          'id': 23,
          'code': 'ISP',
          'name': 'Institut Supérieur Pédagogique de Kindu',
          'type': 'UNIVERSITE',
          'logo_url': null,
          'contact': {'email': 'contact@isp.cd', 'phone': '0990000000'},
          'location': {
            'address': 'Kindu',
            'city': 'Kindu',
            'province': 'Maniema',
          },
        },
        'academic_structure': {
          'academic_unit': {
            'id': 6,
            'type': 'FACULTE',
            'code': 'MED',
            'name': 'Faculté de médecine',
            'parent': null,
          },
          'department': {
            'id': 6,
            'code': 'DEP-MED',
            'name': 'Médecine humaine',
          },
          'program': {
            'id': 11,
            'code': 'MEDECINE_GENERALE',
            'name': 'Médecine générale',
            'duration_years': 7,
          },
          'specialty': null,
        },
        'current_academic': {
          'academic_enrollment_id': academicEnrollmentId,
          'academic_year': {
            'id': 6,
            'label': '2026-2027',
            'start_date': '2026-09-01',
            'end_date': '2027-07-31',
          },
          'level': 'L1',
          'promotion': {
            'id': 9,
            'code': 'PRO-0009',
            'name': 'Médecine Humaine · 2026-2027 · L1',
          },
          'status': 'EN_COURS',
        },
        'academic_history_count': 2,
      },
    ],
    'total': 1,
  };

  static const academicPath = <String, dynamic>{
    'enrollment': {
      'id': academicEnrollmentId,
      'matricule': 'ISP-ETU-2026-000044',
      'institutional_email': 'gemima.mbimbu@isp.cd',
      'enrollment_date': '2026-09-07',
      'status': 'ACTIF',
    },
    'university': {
      'id': 23,
      'code': 'ISP',
      'name': 'Institut Supérieur Pédagogique de Kindu',
    },
    'curriculum': {
      'faculty': {'id': 6, 'name': 'Faculté de médecine'},
      'department': {'id': 6, 'name': 'Médecine humaine'},
      'program': {
        'id': 11,
        'code': 'MEDECINE_GENERALE',
        'name': 'Médecine générale',
      },
    },
    'academic_years': [
      {
        'academic_enrollment_id': academicEnrollmentId,
        'academic_year': {
          'id': 6,
          'label': '2026-2027',
          'start_date': '2026-09-01',
          'end_date': '2027-07-31',
        },
        'level': 'L1',
        'promotion': {
          'id': 9,
          'code': 'PRO-0009',
          'name': 'Médecine Humaine · 2026-2027 · L1',
        },
        'status': 'EN_COURS',
        'is_current': true,
      },
      {
        'academic_enrollment_id': 31,
        'academic_year': {
          'id': 5,
          'label': '2025-2026',
          'start_date': '2025-09-01',
          'end_date': '2026-07-31',
        },
        'level': 'Préparatoire',
        'promotion': {
          'id': 5,
          'code': 'PRO-0005',
          'name': 'Médecine Humaine · 2025-2026 · Préparatoire',
        },
        'status': 'TERMINE',
        'is_current': false,
      },
    ],
  };

  static const dashboard = <String, dynamic>{
    'student': {
      'id': 30,
      'stagia_code': 'STG-ETU-00000030',
      'nom': 'MBIMBU',
      'postnom': 'GEMIMA',
      'prenom': 'Gemima',
    },
    'stats': {
      'applications': 3,
      'active_reservations': 2,
      'stages': 2,
      'planned_stages': 0,
      'active_stages': 1,
      'completed_stages': 1,
      'validated_stages': 1,
      'documents': 2,
    },
    'current_stage': {
      'uuid': assignmentUuid,
      'statut': 'ACTIVE',
      'date_debut': '2026-10-01',
      'date_fin': '2026-12-15',
      'campaign_code': 'CAM-000037',
      'campaign_title': 'Stage clinique intégré 2026',
      'hospital_code': 'HOP-001',
      'hospital_name': 'Hôpital Général de Référence de Kinshasa',
      'unit_code': 'UNI-URG',
      'unit_name': 'Urgences pédiatriques',
      'completion_status': 'EN_COURS',
      'taux_presence': 90.0,
      'note_finale': null,
      'total_rotations': 2,
      'journaux_valides': 1,
      'supervisor_name': 'Dr Grâce Mukendi',
    },
  };

  static const stageOptions = <String, dynamic>{
    'campaigns': [
      {
        'campaign_id': campaignOpenId,
        'academic_enrollment_id': academicEnrollmentId,
        'code': 'CAM-000039',
        'title': 'Stage de fin d’année 2026',
        'start_date': '2026-11-01',
        'end_date': '2026-12-20',
        'stage_type': {'code': 'SPECIALISATION', 'label': 'Spécialisation'},
        'mode': {
          'is_d4': false,
          'self_reservation_allowed': true,
          'reservation_mode': 'STUDENT_CHOICE_UNIVERSITY_CONFIRMATION',
        },
        'promotion': {
          'code': 'PRO-0009',
          'name': 'Médecine Humaine · 2026-2027 · L1',
          'level': 'L1',
        },
        'program': 'Médecine Humaine',
        'hospitals': [
          {
            'participation_id': 81,
            'hospital': {
              'id': 8,
              'code': 'HOP-001',
              'name': 'Hôpital Général de Référence de Kinshasa',
              'phone': '+243810000000',
              'city': 'Kinshasa',
              'province': 'Kinshasa',
              'services': [],
            },
            'capacity': 20,
            'used_places': 7,
            'available_places': 13,
            'available': true,
            'fees_required': true,
            'amount': 25,
            'currency': 'USD',
            'conditions': 'Tenue médicale et dossier académique complet.',
          },
          {
            'participation_id': 82,
            'hospital': {
              'id': 9,
              'code': 'HOP-002',
              'name': 'Centre Hospitalier Monkole',
              'phone': '+243820000000',
              'city': 'Kinshasa',
              'province': 'Kinshasa',
              'services': [],
            },
            'capacity': 10,
            'used_places': 10,
            'available_places': 0,
            'available': false,
            'fees_required': false,
            'amount': null,
            'currency': null,
            'conditions': null,
          },
        ],
        'hospitals_count': 2,
        'available_hospitals': 1,
        'available_places': 13,
      },
    ],
    'university_managed_campaigns': [],
    'stats': {
      'campaigns': 1,
      'university_managed_campaigns': 0,
      'hospitals': 2,
      'available_hospitals': 1,
      'available_places': 13,
    },
  };

  static const _baseApplications = <String, dynamic>{
    'items': [
      {
        'uuid': 'app-placement-001',
        'application_status': 'ACCEPTEE',
        'motivation': 'Je souhaite approfondir ma pratique clinique.',
        'refusal_reason': null,
        'campaign_id': 40,
        'campaign_code': 'CAM-000040',
        'campaign_title': 'Stage de médecine interne 2026',
        'campaign_start': '2026-11-01',
        'campaign_end': '2026-12-15',
        'hospital_id': 10,
        'hospital_name': 'Cliniques Universitaires de Kinshasa',
        'reservation_uuid': 'reservation-placement-001',
        'reservation_status': 'CONFIRMEE',
        'placement': null,
        'admission_uuid': null,
        'assignment_uuid': null,
        'assignment_status': null,
        'completion_status': null,
        'workflow_status': 'PLACEMENT_UNIVERSITAIRE_EN_ATTENTE',
        'workflow_message':
            'Votre dossier attend le placement de l’université.',
      },
      {
        'uuid': 'app-assignment-001',
        'application_status': 'ACCEPTEE',
        'motivation': 'Je souhaite développer mes compétences en chirurgie.',
        'refusal_reason': null,
        'campaign_id': 41,
        'campaign_code': 'CAM-000041',
        'campaign_title': 'Stage de chirurgie générale 2026',
        'campaign_start': '2026-11-15',
        'campaign_end': '2027-01-15',
        'hospital_id': 11,
        'hospital_name': 'Hôpital Saint-Joseph',
        'reservation_uuid': 'reservation-assignment-001',
        'reservation_status': 'CONFIRMEE',
        'placement': {'exists': true, 'status': 'CONFIRME'},
        'admission_uuid': 'admission-assignment-001',
        'assignment_uuid': null,
        'assignment_status': null,
        'completion_status': null,
        'workflow_status': 'AFFECTATION_EN_ATTENTE',
        'workflow_message':
            'Votre admission est confirmée. L’affectation est en préparation.',
      },
    ],
    'total': 2,
    'stats': {
      'total': 2,
      'draft': 0,
      'submitted': 0,
      'under_review': 0,
      'accepted': 2,
      'rejected': 0,
      'cancelled': 0,
    },
    'pagination': {
      'page': 1,
      'per_page': 20,
      'total': 2,
      'pages': 1,
      'from': 1,
      'to': 2,
    },
    'filters': <String, dynamic>{},
    'available_filters': <String, dynamic>{},
  };

  static const _baseReservations = <String, dynamic>{
    'items': [
      {
        'reservation': {
          'uuid': 'reservation-placement-001',
          'status': 'CONFIRMEE',
          'expires_at': null,
        },
        'application': {'uuid': 'app-placement-001', 'status': 'ACCEPTEE'},
        'campaign': {
          'id': 40,
          'code': 'CAM-000040',
          'title': 'Stage de médecine interne 2026',
        },
        'hospital': {'id': 10, 'name': 'Cliniques Universitaires de Kinshasa'},
        'payment': {'required': false, 'status': 'NOT_REQUIRED'},
        'placement': null,
        'admission': null,
        'assignment': null,
        'completion': null,
        'workflow': {
          'status': 'PLACEMENT_UNIVERSITAIRE_EN_ATTENTE',
          'message': 'Votre dossier attend le placement de l’université.',
        },
        'actions': {
          'cancel': {'allowed': false, 'method': 'POST', 'endpoint': null},
        },
      },
      {
        'reservation': {
          'uuid': 'reservation-assignment-001',
          'status': 'CONFIRMEE',
          'expires_at': null,
        },
        'application': {'uuid': 'app-assignment-001', 'status': 'ACCEPTEE'},
        'campaign': {
          'id': 41,
          'code': 'CAM-000041',
          'title': 'Stage de chirurgie générale 2026',
        },
        'hospital': {'id': 11, 'name': 'Hôpital Saint-Joseph'},
        'payment': {'required': true, 'status': 'PAID'},
        'placement': {'exists': true, 'status': 'CONFIRME'},
        'admission': {'exists': true, 'status': 'ADMIS'},
        'assignment': null,
        'completion': null,
        'workflow': {
          'status': 'AFFECTATION_EN_ATTENTE',
          'message':
              'Votre admission est confirmée. L’affectation est en préparation.',
        },
        'actions': {
          'cancel': {'allowed': false, 'method': 'POST', 'endpoint': null},
        },
      },
    ],
    'stats': {
      'total': 2,
      'temporary': 0,
      'waiting_payment': 0,
      'confirmed': 2,
      'expired': 0,
      'cancelled': 0,
      'can_cancel': 0,
    },
    'pagination': {
      'page': 1,
      'per_page': 20,
      'total': 2,
      'pages': 1,
      'from': 1,
      'to': 2,
    },
    'filters': <String, dynamic>{},
    'available_filters': <String, dynamic>{},
  };

  static final List<Map<String, dynamic>> _createdApplications = [];
  static final List<Map<String, dynamic>> _createdReservations = [];

  static Map<String, dynamic> get applications {
    final base = _maps(_baseApplications['items']);
    final items = [..._copyList(_createdApplications), ...base];
    return {
      ..._baseApplications,
      'items': items,
      'total': items.length,
      'pagination': {
        ...Map<String, dynamic>.from(_baseApplications['pagination'] as Map),
        'total': items.length,
        'to': items.length,
      },
    };
  }

  static Map<String, dynamic> get reservations {
    final base = _maps(_baseReservations['items']);
    final items = [..._copyList(_createdReservations), ...base];
    return {
      ..._baseReservations,
      'items': items,
      'stats': {
        ...Map<String, dynamic>.from(_baseReservations['stats'] as Map),
        'total': items.length,
        'temporary': _createdReservations.length,
        'can_cancel': _createdReservations.length,
      },
      'pagination': {
        ...Map<String, dynamic>.from(_baseReservations['pagination'] as Map),
        'total': items.length,
        'to': items.length,
      },
    };
  }

  static const admissions = <String, dynamic>{
    'items': [
      {
        'reservation': {
          'uuid': 'reservation-placement-001',
          'status': 'CONFIRMEE',
        },
        'application': {'uuid': 'app-placement-001', 'status': 'ACCEPTEE'},
        'placement': {'exists': false, 'status': null},
        'admission': {'exists': false, 'uuid': null, 'status': null},
        'assignment': {'exists': false, 'uuid': null, 'status': null},
        'campaign': {
          'id': 40,
          'code': 'CAM-000040',
          'name': 'Stage de médecine interne 2026',
        },
        'hospital': {
          'id': 10,
          'code': 'HOP-003',
          'name': 'Cliniques Universitaires de Kinshasa',
        },
        'completion': null,
        'workflow_status': 'PLACEMENT_UNIVERSITAIRE_EN_ATTENTE',
        'workflow_message':
            'Votre dossier attend le placement de l’université.',
      },
      {
        'reservation': {
          'uuid': 'reservation-assignment-001',
          'status': 'CONFIRMEE',
        },
        'application': {'uuid': 'app-assignment-001', 'status': 'ACCEPTEE'},
        'placement': {'exists': true, 'status': 'CONFIRME'},
        'admission': {
          'exists': true,
          'uuid': 'admission-assignment-001',
          'status': 'ADMIS',
        },
        'assignment': {'exists': false, 'uuid': null, 'status': null},
        'campaign': {
          'id': 41,
          'code': 'CAM-000041',
          'name': 'Stage de chirurgie générale 2026',
        },
        'hospital': {
          'id': 11,
          'code': 'HOP-004',
          'name': 'Hôpital Saint-Joseph',
        },
        'completion': null,
        'workflow_status': 'AFFECTATION_EN_ATTENTE',
        'workflow_message':
            'Votre admission est confirmée. L’affectation est en préparation.',
      },
    ],
    'stats': {
      'total': 2,
      'waiting_decision': 0,
      'waiting_payment': 0,
      'waiting_placement': 1,
      'waiting_admission': 0,
      'admitted': 1,
      'assigned': 0,
      'completed': 0,
      'refused': 0,
      'expired': 0,
    },
  };

  static final Map<String, dynamic> stages = {
    'student': {'id': 30, 'stagia_code': 'STG-ETU-00000030'},
    'items': [_activeAssignment, _historicalAssignment],
    'filters': <String, dynamic>{},
    'summary': {
      'total': 2,
      'by_status': {'ACTIVE': 1, 'TERMINEE': 1},
      'by_workflow_status': {'EN_COURS': 1, 'VALIDE': 1},
    },
  };

  static const completions = <String, dynamic>{
    'items': [
      {
        'uuid': 'completion-history-001',
        'status': 'VALIDE',
        'score': 17.0,
        'attendance_rate': 94.0,
        'final_appreciation': 'Excellent stage.',
        'decision_comment': 'Dossier complet transmis à l’université.',
        'prepared_at': '2026-07-01 09:00:00',
        'validated_at': '2026-07-03 14:30:00',
        'final_deliberation': {'status': 'VALIDEE'},
        'university_validation': {'status': 'VALIDE'},
        'progress': {'percent': 100},
        'readiness': {'ready': true, 'blockers': <String>[]},
        'validator': {'name': 'Dr Patrick Kabeya'},
        'assignment': {'uuid': 'assignment-history-001', 'status': 'TERMINEE'},
        'campaign': {
          'uuid': 'campaign-history-021',
          'code': 'CAM-000021',
          'title': 'Stage hospitalier du second semestre',
        },
        'hospital': {
          'id': 10,
          'code': 'HOP-003',
          'name': 'Cliniques Universitaires de Kinshasa',
        },
        'department': {'id': 20, 'name': 'Médecine interne'},
      },
    ],
    'pagination': {'page': 1, 'per_page': 20, 'total': 1, 'pages': 1},
    'stats': {'total': 1, 'validated': 1, 'pending': 0},
  };

  static const results = <String, dynamic>{
    'items': [
      {
        'uuid': 'result-history-001',
        'decision': 'VALIDE',
        'score': 17.0,
        'appreciation': 'Excellent stage.',
        'assignment': {'uuid': 'assignment-history-001', 'status': 'TERMINEE'},
        'campaign': {
          'uuid': 'campaign-history-021',
          'code': 'CAM-000021',
          'title': 'Stage hospitalier du second semestre',
        },
        'hospital': {
          'id': 10,
          'code': 'HOP-003',
          'name': 'Cliniques Universitaires de Kinshasa',
        },
        'administrative_process': {
          'status': 'COMPLETED',
          'university_transmission': {'status': 'VALIDE'},
        },
        'document': {
          'uuid': 'certificate-history-001',
          'reference': 'ATT-2026-000021',
          'type': 'ATTESTATION_STAGE',
          'status': 'GENERE',
          'available': true,
          'file_endpoint':
              '/api/v1/student/certificates/certificate-history-001/file',
          'download_endpoint':
              '/api/v1/student/certificates/certificate-history-001/file?download=1',
        },
      },
    ],
    'pagination': {'page': 1, 'per_page': 20, 'total': 1, 'pages': 1},
    'stats': {'total': 1, 'validated': 1},
  };

  static const documentsOfficiels = <String, dynamic>{
    'items': [
      {
        'uuid': 'certificate-history-001',
        'reference': 'ATT-2026-000021',
        'type_document': 'ATTESTATION_STAGE',
        'status': 'GENERE',
        'available': true,
        'availability_reason': null,
        'university_result_status': 'VALIDE',
        'file_endpoint':
            '/api/v1/student/certificates/certificate-history-001/file',
        'download_endpoint':
            '/api/v1/student/certificates/certificate-history-001/file?download=1',
        'stage': {'assignment_uuid': 'assignment-history-001'},
        'campaign': {
          'uuid': 'campaign-history-021',
          'code': 'CAM-000021',
          'title': 'Stage hospitalier du second semestre',
        },
        'hospital': {
          'id': 10,
          'code': 'HOP-003',
          'name': 'Cliniques Universitaires de Kinshasa',
        },
      },
    ],
    'pagination': {'page': 1, 'per_page': 20, 'total': 1, 'pages': 1},
    'stats': {'total': 1, 'available': 1, 'pending': 0},
    'filters': <String, dynamic>{},
    'available_filters': {
      'types': ['ATTESTATION_STAGE', 'CERTIFICAT_STAGE'],
      'statuses': ['GENERE'],
    },
  };

  static final Map<String, dynamic> rapportsStage = {
    'items': <Map<String, dynamic>>[
      {
        'uuid': 'report-history-002',
        'version': 2,
        'title': 'Rapport de stage corrigé',
        'description': 'Corrections demandées par l’université.',
        'status': 'ACCEPTE',
        'university_comment': 'Rapport conforme.',
        'submitted_at': '2026-07-05 10:00:00',
        'received_at': '2026-07-05 10:10:00',
        'reviewed_at': '2026-07-06 09:00:00',
        'reviewer': {'user_id': 18, 'name': 'Responsable académique'},
        'file': {
          'original_name': 'rapport_stage_corrige.pdf',
          'mime_type': 'application/pdf',
          'extension': 'pdf',
          'size': 524288,
        },
        'assignment': {
          'uuid': 'assignment-history-001',
          'status': 'TERMINEE',
          'start_date': '2026-04-01',
          'end_date': '2026-06-30',
        },
        'campaign': {
          'uuid': 'campaign-history-021',
          'code': 'CAM-000021',
          'title': 'Stage hospitalier du second semestre',
        },
        'hospital': {'id': 10, 'name': 'Cliniques Universitaires de Kinshasa'},
        'university': {'id': 23, 'name': 'ISP'},
        'department': {'id': 20, 'name': 'Médecine interne'},
      },
      {
        'uuid': 'report-history-001',
        'version': 1,
        'title': 'Rapport de stage',
        'description': 'Version initiale.',
        'status': 'A_CORRIGER',
        'university_comment': 'Compléter la conclusion.',
        'submitted_at': '2026-07-01 14:30:00',
        'assignment': {'uuid': 'assignment-history-001', 'status': 'TERMINEE'},
        'campaign': {
          'uuid': 'campaign-history-021',
          'code': 'CAM-000021',
          'title': 'Stage hospitalier du second semestre',
        },
        'hospital': {'id': 10, 'name': 'Cliniques Universitaires de Kinshasa'},
        'university': {'id': 23, 'name': 'ISP'},
      },
    ],
    'stats': {
      'total': 2,
      'by_status': {
        'SOUMIS': 0,
        'RECU': 0,
        'ACCEPTE': 1,
        'A_CORRIGER': 1,
        'REJETE': 0,
        'ARCHIVE': 0,
      },
      'assignments': 1,
    },
    'pagination': {'page': 1, 'per_page': 20, 'total': 2, 'pages': 1},
    'filters': <String, dynamic>{},
    'available_filters': {
      'statuses': [
        'SOUMIS',
        'RECU',
        'ACCEPTE',
        'A_CORRIGER',
        'REJETE',
        'ARCHIVE',
      ],
      'per_page_max': 100,
    },
  };

  static final Map<String, dynamic> justificationsStage = {
    'items': <Map<String, dynamic>>[
      {
        'assignment_uuid': assignmentUuid,
        'situation': 'INTERRUPTION',
        'allowed_type': 'INTERRUPTION',
        'message':
            'Une justification est demandée pour l’interruption de ce stage.',
        'justification_uuid': 'justification-stage-001',
        'justification_status': 'REJETEE',
        'reason': 'MALADIE',
        'explanation': null,
        'decision_seen': false,
        'decision_message':
            'Le document fourni ne permet pas de vérifier la période concernée.',
        'file_endpoint':
            '/api/v1/student/stage-justifications/justification-stage-001/file',
        'read_endpoint':
            '/api/v1/student/stage-justifications/justification-stage-001/read',
        'campaign': {
          'uuid': 'campaign-active-037',
          'title': 'Stage clinique intégré 2026',
        },
        'hospital': {'name': 'Hôpital Général de Référence de Kinshasa'},
        'actions': {
          'submit': {'allowed': true},
          'read': {'allowed': true},
        },
      },
    ],
    'stats': {'total': 1, 'pending': 0, 'accepted': 0, 'rejected': 1},
    'allowed_values': {
      'types': ['NON_DEMARRAGE', 'INTERRUPTION'],
      'reasons': ['MALADIE', 'ACCIDENT', 'CONTRAINTE_FAMILIALE', 'AUTRE'],
      'statuses': ['EN_ATTENTE', 'ACCEPTEE', 'REJETEE'],
    },
  };

  static final Map<String, dynamic> executionContext = {
    'context': {
      'date': '2026-10-10',
      'assignment': {
        'id': 47,
        'uuid': assignmentUuid,
        'status': 'ACTIVE',
        'period': {'start_date': '2026-10-01', 'end_date': '2026-12-15'},
      },
      'campaign': {
        'id': campaignActiveId,
        'uuid': 'campaign-active-037',
        'code': 'CAM-000037',
        'title': 'Stage clinique intégré 2026',
      },
      'hospital': _hospital,
      'department': _department,
      'current_rotation': _currentRotation,
      'next_rotation': _nextRotation,
      'attendance': <String, dynamic>{},
      'actions': _executionActions(arrival: true, departure: false),
      'capabilities': {'attendance': true, 'logbook': true, 'evaluation': true},
      'reason': null,
      'unlock_date': null,
    },
    'execution': <String, dynamic>{},
    'punch': <String, dynamic>{},
  };

  static Map<String, dynamic> get attendance {
    final items = <Map<String, dynamic>>[
      if (_arrivalDone) _todayAttendance,
      _attendance(
        'attendance-009',
        '2026-10-09',
        'PRESENT',
        '07:58:00',
        '16:10:00',
        0,
      ),
      _attendance(
        'attendance-008',
        '2026-10-08',
        'RETARD',
        '08:17:00',
        '16:05:00',
        17,
      ),
      _attendance(
        'attendance-007',
        '2026-10-07',
        'PRESENT',
        '07:55:00',
        '16:02:00',
        0,
      ),
      _attendance('attendance-006', '2026-10-06', 'ABSENT', null, null, 0),
      _attendance('attendance-005', '2026-10-05', 'JUSTIFIE', null, null, 0),
    ];
    return {
      'items': items,
      'stats': {
        'total': items.length,
        'present': items.where((e) => e['status'] == 'PRESENT').length,
        'late': items.where((e) => e['status'] == 'RETARD').length,
        'absent': items.where((e) => e['status'] == 'ABSENT').length,
        'justified': items.where((e) => e['status'] == 'JUSTIFIE').length,
        'guard': 0,
        'effective_presence': items
            .where((e) => e['arrival_time'] != null)
            .length,
        'attendance_rate': 80.0,
        'minutes_late': 17,
        'total_duration_minutes': 1457,
        'validated': 3,
      },
      'pagination': {
        'page': 1,
        'per_page': 20,
        'total': items.length,
        'pages': 1,
        'from': 1,
        'to': items.length,
      },
      'filters': <String, dynamic>{},
      'available_filters': {
        'statuses': ['PRESENT', 'RETARD', 'ABSENT', 'JUSTIFIE', 'GARDE'],
        'per_page_max': 100,
      },
    };
  }

  static Map<String, dynamic> get tasks => {
    'items': _copyList(_tasks),
    'stats': {
      'total': _tasks.length,
      'a_faire': _count(_tasks, 'A_FAIRE'),
      'en_cours': _count(_tasks, 'EN_COURS'),
      'terminees': _count(_tasks, 'TERMINEE'),
      'a_revoir': _count(_tasks, 'A_REVOIR'),
      'validees': _count(_tasks, 'VALIDEE'),
      'annulees': _count(_tasks, 'ANNULEE'),
    },
    'progress': 50,
    'pagination': {
      'page': 1,
      'per_page': 20,
      'total': _tasks.length,
      'pages': 1,
      'from': 1,
      'to': _tasks.length,
    },
    'filters': <String, dynamic>{},
    'available_filters': {
      'statuses': [
        'A_FAIRE',
        'EN_COURS',
        'TERMINEE',
        'A_REVOIR',
        'VALIDEE',
        'ANNULEE',
      ],
      'priorities': ['BASSE', 'NORMALE', 'HAUTE', 'URGENTE'],
      'per_page_max': 100,
    },
  };

  static Map<String, dynamic> get logbook => {
    'items': _copyList(_logbook),
    'stats': {
      'total': _logbook.length,
      'draft': _count(_logbook, 'BROUILLON'),
      'submitted': _count(_logbook, 'SOUMISE'),
      'validated': _count(_logbook, 'VALIDEE'),
      'rejected': _count(_logbook, 'REJETEE'),
      'activities': _logbook.fold<int>(
        0,
        (sum, e) => sum + ((e['activities'] as List?)?.length ?? 0),
      ),
    },
    'pagination': {
      'page': 1,
      'per_page': 20,
      'total': _logbook.length,
      'pages': 1,
      'from': 1,
      'to': _logbook.length,
    },
    'filters': <String, dynamic>{},
    'available_filters': {
      'statuses': ['BROUILLON', 'SOUMISE', 'VALIDEE', 'REJETEE'],
      'editable': [true, false],
      'per_page_max': 100,
    },
  };

  static Map<String, dynamic> get feedbacks => {
    'items': _copyList(_feedbacks),
    'stats': {
      'total': _feedbacks.length,
      'observations': _count(_feedbacks, 'OBSERVATION', key: 'type'),
      'encouragements': _count(_feedbacks, 'ENCOURAGEMENT', key: 'type'),
      'a_ameliorer': _count(_feedbacks, 'A_AMELIORER', key: 'type'),
      'avertissements': _count(_feedbacks, 'AVERTISSEMENT', key: 'type'),
      'unread': _feedbacks.where((e) => e['seen'] != true).length,
      'read': _feedbacks.where((e) => e['seen'] == true).length,
    },
    'pagination': {
      'page': 1,
      'per_page': 20,
      'total': _feedbacks.length,
      'pages': 1,
      'from': 1,
      'to': _feedbacks.length,
    },
    'filters': <String, dynamic>{},
    'available_filters': {
      'types': ['OBSERVATION', 'ENCOURAGEMENT', 'A_AMELIORER', 'AVERTISSEMENT'],
      'seen': [true, false],
      'per_page_max': 100,
    },
  };

  static const evaluations = <String, dynamic>{
    'items': [
      {
        'uuid': 'evaluation-continue-001',
        'type': 'CONTINUE',
        'status': 'VALIDEE',
        'note': 15.0,
        'appreciation': 'Bonne adaptation au service.',
        'strengths': 'Écoute et rigueur.',
        'improvement_areas': 'Approfondir le raisonnement diagnostique.',
        'evaluated_at': '2026-10-08 14:00:00',
        'submitted_at': '2026-10-08 14:10:00',
        'validated_at': '2026-10-08 15:00:00',
        'finalized_at': null,
        'score_summary': {'total': 30, 'maximum': 40, 'percentage': 75.0},
        'scores': [
          {
            'code': 'COMP-CLIN',
            'nom': 'Raisonnement clinique',
            'categorie': 'CLINIQUE',
            'note': 15,
            'note_max': 20,
            'poids': 1,
            'commentaire': 'Bonne progression.',
          },
          {
            'code': 'COMP-COM',
            'nom': 'Communication',
            'categorie': 'RELATIONNEL',
            'note': 15,
            'note_max': 20,
            'poids': 1,
            'commentaire': 'Écoute attentive.',
          },
        ],
        'evaluator': {
          'user_id': 14,
          'name': 'Dr Grâce Mukendi',
          'function': 'Maître de stage',
        },
        'rotation': {'uuid': rotationActiveUuid, 'sequence': 1},
        'assignment': {
          'uuid': assignmentUuid,
          'status': 'ACTIVE',
          'start_date': '2026-10-01',
          'end_date': '2026-12-15',
        },
        'campaign': {
          'code': 'CAM-000037',
          'title': 'Stage clinique intégré 2026',
        },
        'hospital': {
          'code': 'HOP-001',
          'name': 'Hôpital Général de Référence de Kinshasa',
        },
        'unit': {
          'id': 9,
          'code': 'UNI-URG',
          'name': 'Urgences pédiatriques',
          'type': 'UNITE',
        },
      },
      {
        'uuid': 'evaluation-finale-historique-001',
        'type': 'FIN_ROTATION',
        'status': 'FINALISEE',
        'note': 17.0,
        'appreciation': 'Très bonne progression clinique.',
        'strengths': 'Communication et raisonnement clinique.',
        'improvement_areas': 'Gagner en rapidité dans les urgences.',
        'evaluated_at': '2026-06-30 14:00:00',
        'submitted_at': '2026-06-30 14:10:00',
        'validated_at': '2026-06-30 15:00:00',
        'finalized_at': '2026-06-30 16:00:00',
        'score_summary': {'total': 34, 'maximum': 40, 'percentage': 85.0},
        'scores': [
          {
            'code': 'COMP-CLIN',
            'nom': 'Raisonnement clinique',
            'categorie': 'CLINIQUE',
            'note': 17,
            'note_max': 20,
            'poids': 1,
            'commentaire': 'Analyse pertinente.',
          },
        ],
        'evaluator': {
          'user_id': 18,
          'name': 'Dr Alain Ilunga',
          'function': 'Maître de stage',
        },
        'rotation': {'uuid': 'rotation-history-001', 'sequence': 2},
        'assignment': {
          'uuid': 'assignment-history-001',
          'status': 'TERMINEE',
          'start_date': '2026-04-01',
          'end_date': '2026-06-30',
        },
        'campaign': {
          'code': 'CAM-000021',
          'title': 'Stage hospitalier du second semestre',
        },
        'hospital': {
          'code': 'HOP-003',
          'name': 'Cliniques Universitaires de Kinshasa',
        },
        'unit': {
          'id': 21,
          'code': 'UNI-CARD',
          'name': 'Cardiologie',
          'type': 'UNITE',
        },
      },
    ],
    'stats': {
      'total': 2,
      'continuous': 1,
      'mid_rotation': 0,
      'final_rotation': 1,
      'validated': 1,
      'finalized': 1,
      'average': 16.0,
    },
    'final_evaluation': {
      'uuid': 'evaluation-finale-historique-001',
      'type': 'FIN_ROTATION',
      'status': 'FINALISEE',
      'note': 17.0,
    },
    'pagination': {
      'page': 1,
      'per_page': 20,
      'total': 2,
      'pages': 1,
      'from': 1,
      'to': 2,
    },
    'filters': <String, dynamic>{},
    'available_filters': {
      'types': ['CONTINUE', 'MI_ROTATION', 'FIN_ROTATION'],
      'statuses': ['VALIDEE', 'FINALISEE'],
      'per_page_max': 100,
    },
  };

  static Map<String, dynamic> pointerArrivee() {
    _arrivalDone = true;
    _departureDone = false;
    _synchroniserContextePointage();
    changements.value++;
    return {
      'message': 'Arrivée pointée à 08:02.',
      'punch': _punch(nextAction: 'DEPART', canPunch: true),
    };
  }

  static Map<String, dynamic> pointerDepart() {
    _arrivalDone = true;
    _departureDone = true;
    _synchroniserContextePointage();
    changements.value++;
    return {
      'message': 'Départ pointé à 16:10.',
      'punch': _punch(nextAction: 'TERMINE', canPunch: false),
    };
  }

  static Map<String, dynamic> actionTache(
    String uuid,
    String action, {
    String? comment,
  }) {
    final index = _tasks.indexWhere((item) => item['uuid'] == uuid);
    if (index < 0) return {'task': <String, dynamic>{}};
    final task = _tasks[index];
    if (comment?.trim().isNotEmpty == true) {
      task['student_comment'] = comment!.trim();
    }
    if (action == 'start') {
      task['status'] = 'EN_COURS';
      task['started_at'] = '2026-10-10 08:15:00';
    } else if (action == 'complete') {
      task['status'] = 'TERMINEE';
      task['completed_at'] = '2026-10-10 16:00:00';
    }
    task['updated_at'] = '2026-10-10 16:00:00';
    task['actions'] = _taskActions(uuid, task['status']?.toString() ?? '');
    changements.value++;
    return {
      'message': 'Tâche actualisée.',
      'task': Map<String, dynamic>.from(task),
    };
  }

  static Map<String, dynamic> marquerFeedbackLu(String uuid) {
    final index = _feedbacks.indexWhere((item) => item['uuid'] == uuid);
    if (index < 0) return {'feedback': <String, dynamic>{}};
    _feedbacks[index]['seen'] = true;
    _feedbacks[index]['seen_at'] = '2026-10-10 17:05:00';
    _feedbacks[index]['actions'] = {
      'read': {
        'allowed': false,
        'method': 'POST',
        'endpoint': '/api/v1/student/feedbacks/$uuid/read',
      },
    };
    changements.value++;
    return {
      'message': 'Feedback marqué comme lu.',
      'feedback': Map<String, dynamic>.from(_feedbacks[index]),
    };
  }

  static Map<String, dynamic> soumettreRapport({
    required String assignmentUuid,
    required String cheminFichier,
    String? title,
    String? description,
  }) {
    final items = rapportsStage['items'] as List<Map<String, dynamic>>;
    final versions = items
        .where(
          (item) =>
              (item['assignment'] as Map?)?['uuid']?.toString() ==
              assignmentUuid,
        )
        .map((item) => (item['version'] as num?)?.toInt() ?? 0);
    final version = versions.isEmpty
        ? 1
        : versions.reduce((a, b) => a > b ? a : b) + 1;
    final nomFichier = cheminFichier.split(RegExp(r'[/\\]')).last;
    final extension = nomFichier.contains('.')
        ? nomFichier.split('.').last.toLowerCase()
        : 'pdf';
    final stage = _assignmentByUuid(assignmentUuid);
    final rapport = <String, dynamic>{
      'uuid': 'report-mock-${DateTime.now().millisecondsSinceEpoch}',
      'version': version,
      'title': title?.trim().isNotEmpty == true
          ? title!.trim()
          : 'Rapport de stage',
      'description': description?.trim().isNotEmpty == true
          ? description!.trim()
          : null,
      'status': 'SOUMIS',
      'university_comment': null,
      'submitted_at': DateTime.now().toIso8601String(),
      'file': {'original_name': nomFichier, 'extension': extension, 'size': 0},
      'assignment': {
        'uuid': assignmentUuid,
        'status': stage?['assignment_status'],
      },
      'campaign': stage?['campaign'],
      'hospital': stage?['hospital'],
    };
    items.insert(0, rapport);
    rapportsStage['stats'] = {
      'total': items.length,
      'by_status': {
        for (final statut in const [
          'SOUMIS',
          'RECU',
          'ACCEPTE',
          'A_CORRIGER',
          'REJETE',
          'ARCHIVE',
        ])
          statut: items.where((item) => item['status'] == statut).length,
      },
      'assignments': items
          .map((item) => (item['assignment'] as Map?)?['uuid'])
          .whereType<String>()
          .toSet()
          .length,
    };
    changements.value++;
    return {'report': rapport};
  }

  static Map<String, dynamic> soumettreJustification({
    required String assignmentUuid,
    required String typeSituation,
    required String motif,
    required String explication,
    required String cheminDocument,
  }) {
    final items = justificationsStage['items'] as List<Map<String, dynamic>>;
    final index = items.indexWhere(
      (item) => item['assignment_uuid']?.toString() == assignmentUuid,
    );
    final precedente = index >= 0 ? items[index] : <String, dynamic>{};
    final uuid =
        precedente['justification_uuid']?.toString() ??
        'justification-${DateTime.now().millisecondsSinceEpoch}';
    final justification = <String, dynamic>{
      ...precedente,
      'assignment_uuid': assignmentUuid,
      'situation': typeSituation,
      'allowed_type': typeSituation,
      'justification_uuid': uuid,
      'justification_status': 'EN_ATTENTE',
      'reason': motif,
      'explanation': explication.isEmpty ? null : explication,
      'decision_seen': false,
      'decision_message': null,
      'file_endpoint': cheminDocument.isEmpty
          ? precedente['file_endpoint']
          : '/api/v1/student/stage-justifications/$uuid/file',
      'actions': {
        'submit': {'allowed': true},
        'read': {'allowed': false},
      },
    };
    if (index >= 0) {
      items[index] = justification;
    } else {
      items.add(justification);
    }
    changements.value++;
    return {'justification': justification};
  }

  static void marquerDecisionJustificationLue(String uuid) {
    final items = justificationsStage['items'] as List<Map<String, dynamic>>;
    final index = items.indexWhere(
      (item) => item['justification_uuid']?.toString() == uuid,
    );
    if (index < 0) return;
    items[index]['decision_seen'] = true;
    final actions = Map<String, dynamic>.from(
      items[index]['actions'] as Map? ?? const {},
    );
    actions['read'] = {'allowed': false};
    items[index]['actions'] = actions;
    changements.value++;
  }

  static Map<String, dynamic>? _assignmentByUuid(String uuid) {
    for (final stage in (stages['items'] as List).whereType<Map>()) {
      if (stage['assignment_uuid']?.toString() == uuid) {
        return Map<String, dynamic>.from(stage);
      }
    }
    return null;
  }

  static Map<String, dynamic> sauvegarderJournal({
    required String assignmentUuid,
    required String date,
    required String summary,
    required String learning,
    String? difficulties,
    required List<Map<String, dynamic>> activities,
    String? logbookUuid,
  }) {
    final uuid = logbookUuid?.isNotEmpty == true
        ? logbookUuid!
        : 'logbook-${DateTime.now().millisecondsSinceEpoch}';
    final entry = _logbookEntry(
      uuid: uuid,
      date: date,
      status: 'BROUILLON',
      summary: summary,
      learning: learning,
      difficulties: difficulties,
      activities: activities,
    );
    final index = _logbook.indexWhere((item) => item['uuid'] == uuid);
    if (index < 0) {
      _logbook.insert(0, entry);
    } else {
      _logbook[index] = entry;
    }
    changements.value++;
    return {
      'message': 'Journal enregistré en brouillon.',
      'entry': Map<String, dynamic>.from(entry),
    };
  }

  static Map<String, dynamic> soumettreJournal(String uuid) {
    final index = _logbook.indexWhere((item) => item['uuid'] == uuid);
    if (index < 0) return {'entry': <String, dynamic>{}};
    final entry = _logbook[index];
    entry['status'] = 'SOUMISE';
    entry['submitted_at'] = '2026-10-10 17:10:00';
    entry['editable'] = false;
    entry['can_submit'] = false;
    entry['actions'] = _logbookActions(uuid, editable: false);
    changements.value++;
    return {
      'message': 'Journal soumis pour validation.',
      'entry': Map<String, dynamic>.from(entry),
    };
  }

  static Map<String, dynamic> creerReservation({
    required int campaignId,
    required int academicEnrollmentId,
    required int participationId,
    String? motivation,
  }) {
    const applicationUuid = 'application-open-039';
    const reservationUuid = 'reservation-open-039';
    if (_createdApplications.any((item) => item['uuid'] == applicationUuid)) {
      return {
        'created': false,
        'application_id': 120,
        'application_uuid': applicationUuid,
        'application_status': 'SOUMISE',
        'reservation_id': 92,
        'reservation_uuid': reservationUuid,
        'reservation_status': 'RESERVEE_TEMPORAIREMENT',
        'expires_at': '2026-10-10 18:00:00',
        'workflow_status': 'DECISION_UNIVERSITAIRE_EN_ATTENTE',
      };
    }

    _createdApplications.add({
      'uuid': applicationUuid,
      'application_status': 'SOUMISE',
      'motivation': motivation ?? '',
      'refusal_reason': null,
      'campaign_id': campaignId,
      'campaign_code': 'CAM-000039',
      'campaign_title': 'Stage de fin d’année 2026',
      'campaign_start': '2026-11-01',
      'campaign_end': '2026-12-20',
      'hospital_id': 8,
      'hospital_name': 'Hôpital Général de Référence de Kinshasa',
      'reservation_uuid': reservationUuid,
      'reservation_status': 'RESERVEE_TEMPORAIREMENT',
      'expires_at': '2026-10-10 18:00:00',
      'placement': null,
      'admission_uuid': null,
      'assignment_uuid': null,
      'assignment_status': null,
      'completion_status': null,
      'workflow_status': 'DECISION_UNIVERSITAIRE_EN_ATTENTE',
      'workflow_message':
          'Votre réservation attend la décision de l’université.',
      'submitted_at': '2026-10-10 12:00:00',
    });
    _createdReservations.add({
      'reservation': {
        'uuid': reservationUuid,
        'status': 'RESERVEE_TEMPORAIREMENT',
        'expires_at': '2026-10-10 18:00:00',
      },
      'application': {'uuid': applicationUuid, 'status': 'SOUMISE'},
      'campaign': {
        'id': campaignId,
        'code': 'CAM-000039',
        'title': 'Stage de fin d’année 2026',
      },
      'hospital': {'id': 8, 'name': 'Hôpital Général de Référence de Kinshasa'},
      'payment': {'required': true, 'status': 'NOT_STARTED'},
      'placement': null,
      'admission': null,
      'assignment': null,
      'completion': null,
      'workflow': {
        'status': 'DECISION_UNIVERSITAIRE_EN_ATTENTE',
        'message': 'Votre réservation attend la décision de l’université.',
      },
      'actions': {
        'cancel': {
          'allowed': true,
          'method': 'POST',
          'endpoint': '/api/v1/student/reservations/$reservationUuid/cancel',
        },
      },
    });
    changements.value++;
    return {
      'created': true,
      'application_id': 120,
      'application_uuid': applicationUuid,
      'application_status': 'SOUMISE',
      'reservation_id': 92,
      'reservation_uuid': reservationUuid,
      'reservation_status': 'RESERVEE_TEMPORAIREMENT',
      'expires_at': '2026-10-10 18:00:00',
      'workflow_status': 'DECISION_UNIVERSITAIRE_EN_ATTENTE',
    };
  }

  static Map<String, dynamic> annulerReservation(String uuid) {
    final reservationIndex = _createdReservations.indexWhere(
      (item) =>
          item['reservation'] is Map &&
          (item['reservation'] as Map)['uuid'] == uuid,
    );
    if (reservationIndex >= 0) {
      final reservation = Map<String, dynamic>.from(
        _createdReservations[reservationIndex]['reservation'] as Map,
      );
      reservation['status'] = 'ANNULEE';
      _createdReservations[reservationIndex]['reservation'] = reservation;
      final workflow = Map<String, dynamic>.from(
        _createdReservations[reservationIndex]['workflow'] as Map,
      );
      workflow['status'] = 'ANNULEE';
      workflow['message'] = 'Votre réservation a été annulée.';
      _createdReservations[reservationIndex]['workflow'] = workflow;
    }
    final applicationIndex = _createdApplications.indexWhere(
      (item) => item['reservation_uuid'] == uuid,
    );
    if (applicationIndex >= 0) {
      _createdApplications[applicationIndex]['application_status'] = 'ANNULEE';
      _createdApplications[applicationIndex]['reservation_status'] = 'ANNULEE';
      _createdApplications[applicationIndex]['workflow_status'] = 'ANNULEE';
      _createdApplications[applicationIndex]['workflow_message'] =
          'Votre réservation a été annulée.';
    }
    changements.value++;
    return {
      'success': true,
      'message': 'Réservation annulée.',
      'data': {
        'reservation_uuid': uuid,
        'reservation_status': 'ANNULEE',
        'application_status': 'ANNULEE',
        'idempotent': reservationIndex < 0,
      },
    };
  }

  static const _hospital = <String, dynamic>{
    'id': 8,
    'code': 'HOP-001',
    'name': 'Hôpital Général de Référence de Kinshasa',
    'phone': '+243810000000',
    'email': 'contact@hgrk.cd',
    'address': 'Avenue de l’Hôpital, Kinshasa',
    'city': 'Kinshasa',
    'province': 'Kinshasa',
    'location': {'city': 'Kinshasa', 'province': 'Kinshasa'},
  };
  static const _department = <String, dynamic>{
    'id': 12,
    'code': 'DEP-PED',
    'name': 'Département de pédiatrie',
    'type': 'DEPARTEMENT',
    'active': true,
  };
  static const _service = <String, dynamic>{
    'id': 8,
    'code': 'SRV-PED',
    'name': 'Pédiatrie',
    'type': 'SERVICE',
  };
  static const _unit = <String, dynamic>{
    'id': 9,
    'code': 'UNI-URG',
    'name': 'Urgences pédiatriques',
    'type': 'UNITE',
  };
  static const _supervisor = <String, dynamic>{
    'user_id': 14,
    'name': 'Dr Grâce Mukendi',
    'function': 'Maître de stage',
  };

  static const _currentRotation = <String, dynamic>{
    'id': 71,
    'uuid': rotationActiveUuid,
    'position': 1,
    'sequence': 1,
    'status': 'ACTIVE',
    'period': {'start_date': '2026-10-01', 'end_date': '2026-10-20'},
    'service': _service,
    'unit': _unit,
    'supervisor': _supervisor,
    'objectives': 'Prise en charge initiale des urgences pédiatriques.',
    'observation': null,
    'integrity': {
      'valid': true,
      'service_target_valid': true,
      'belongs_to_assignment_department': true,
    },
  };
  static const _nextRotation = <String, dynamic>{
    'id': 72,
    'uuid': rotationNextUuid,
    'position': 2,
    'sequence': 2,
    'status': 'PLANIFIEE',
    'period': {'start_date': '2026-10-21', 'end_date': '2026-11-10'},
    'service': {
      'id': 10,
      'code': 'SRV-NEO',
      'name': 'Néonatologie',
      'type': 'SERVICE',
    },
    'unit': {
      'id': 11,
      'code': 'UNI-SOIN',
      'name': 'Soins intensifs néonataux',
      'type': 'UNITE',
    },
    'supervisor': {
      'user_id': 19,
      'name': 'Dr Patrick Kabeya',
      'function': 'Chef de service',
    },
    'objectives': 'Surveillance et soins du nouveau-né à risque.',
    'observation': null,
    'integrity': {
      'valid': true,
      'service_target_valid': true,
      'belongs_to_assignment_department': true,
    },
  };

  static const _activeAssignment = <String, dynamic>{
    'assignment_id': 47,
    'assignment_uuid': assignmentUuid,
    'assignment_status': 'ACTIVE',
    'workflow_status': 'EN_COURS',
    'department': _department,
    'department_integrity': {
      'valid': true,
      'source': 'stage_admissions.coordination_unit_id',
    },
    'hospital': _hospital,
    'campaign': {
      'id': campaignActiveId,
      'uuid': 'campaign-active-037',
      'code': 'CAM-000037',
      'title': 'Stage clinique intégré 2026',
      'stage_type': {'code': 'CLINIQUE', 'label': 'Stage clinique'},
    },
    'period': {'start_date': '2026-10-01', 'end_date': '2026-12-15'},
    'planning': {
      'current_rotation': _currentRotation,
      'next_rotation': _nextRotation,
      'rotations': [_currentRotation, _nextRotation],
      'total': 2,
    },
    'rotations': [
      _currentRotation,
      _nextRotation,
      {
        'id': 73,
        'uuid': 'rotation-future-003',
        'position': 3,
        'sequence': 3,
        'status': 'PLANIFIEE',
        'period': {'start_date': '2026-11-11', 'end_date': '2026-12-15'},
        'service': {
          'id': 12,
          'code': 'SRV-CONS',
          'name': 'Consultations externes',
          'type': 'SERVICE',
        },
        'unit': null,
        'supervisor': {
          'user_id': 22,
          'name': 'Dr Esther Mbala',
          'function': 'Pédiatre',
        },
        'objectives': 'Conduire une consultation pédiatrique complète.',
      },
    ],
    'execution_access': {
      'attendance': true,
      'logbook': true,
      'evaluation': true,
    },
    'summary': {
      'attendance_rate': 90.0,
      'tasks_total': 4,
      'tasks_completed': 2,
      'logbook_entries': 4,
    },
  };

  static const _historicalAssignment = <String, dynamic>{
    'assignment_id': 21,
    'assignment_uuid': 'assignment-history-001',
    'assignment_status': 'TERMINEE',
    'workflow_status': 'VALIDE',
    'department': {
      'id': 20,
      'code': 'DEP-MED',
      'name': 'Médecine interne',
      'type': 'DEPARTEMENT',
      'active': true,
    },
    'hospital': {
      'id': 10,
      'code': 'HOP-003',
      'name': 'Cliniques Universitaires de Kinshasa',
      'location': {'city': 'Kinshasa', 'province': 'Kinshasa'},
    },
    'campaign': {
      'id': 21,
      'uuid': 'campaign-history-021',
      'code': 'CAM-000021',
      'title': 'Stage hospitalier du second semestre',
      'stage_type': {'code': 'IMMERSION', 'label': 'Immersion'},
    },
    'period': {'start_date': '2026-04-01', 'end_date': '2026-06-30'},
    'planning': {
      'current_rotation': null,
      'next_rotation': null,
      'rotations': [],
      'total': 2,
    },
    'rotations': <Map<String, dynamic>>[],
    'completion': {
      'status': 'VALIDE',
      'attendance_rate': 94.0,
      'final_score': 17.0,
      'appreciation': 'Excellent stage.',
    },
    'certificate': {
      'available': true,
      'uuid': 'certificate-history-001',
      'reference': 'ATT-2026-000021',
    },
    'execution_access': null,
  };

  static Map<String, dynamic> _task({
    required String uuid,
    required String title,
    required String description,
    required String priority,
    required String status,
    required String dueDate,
    String? studentComment,
    String? supervisorComment,
    String? startedAt,
    String? completedAt,
    String? validatedAt,
  }) => {
    'uuid': uuid,
    'title': title,
    'description': description,
    'priority': priority,
    'status': status,
    'due_date': dueDate,
    'student_comment': studentComment,
    'supervisor_comment': supervisorComment,
    'started_at': startedAt,
    'completed_at': completedAt,
    'validated_at': validatedAt,
    'created_at': '2026-10-01 09:00:00',
    'updated_at': '2026-10-10 09:00:00',
    'training_plan_item': {'id': 4, 'title': 'Consultation supervisée'},
    'assignment': {
      'uuid': assignmentUuid,
      'status': 'ACTIVE',
      'period': {'start_date': '2026-10-01', 'end_date': '2026-12-15'},
    },
    'rotation': {
      'uuid': rotationActiveUuid,
      'sequence': 1,
      'status': 'ACTIVE',
      'period': {'start_date': '2026-10-01', 'end_date': '2026-10-20'},
    },
    'hospital': _hospital,
    'service': _service,
    'unit': _unit,
    'actions': _taskActions(uuid, status),
  };

  static Map<String, dynamic> _taskActions(String uuid, String status) => {
    'start': {
      'allowed': status == 'A_FAIRE',
      'method': 'POST',
      'path': '/api/v1/student/tasks/$uuid/start',
    },
    'comment': {
      'allowed': status != 'VALIDEE' && status != 'ANNULEE',
      'method': 'POST',
      'path': '/api/v1/student/tasks/$uuid/comment',
    },
    'complete': {
      'allowed': status == 'EN_COURS',
      'method': 'POST',
      'path': '/api/v1/student/tasks/$uuid/complete',
    },
  };

  static Map<String, dynamic> _logbookEntry({
    required String uuid,
    required String date,
    required String status,
    required String summary,
    required String learning,
    String? difficulties,
    String? submittedAt,
    String? validatedAt,
    String? validatorComment,
    List<Map<String, dynamic>>? activities,
  }) {
    final editable = status == 'BROUILLON' || status == 'REJETEE';
    final activityItems =
        activities ??
        [
          {
            'uuid': 'activity-$uuid',
            'activity': 'Anamnèse pédiatrique',
            'description': 'Interrogatoire sous supervision.',
            'category': 'PARTICIPATION',
            'involvement_level': 'REALISE_SUPERVISE',
            'quantity': 3,
            'observation': null,
          },
        ];
    return {
      'uuid': uuid,
      'date': date,
      'status': status,
      'summary': summary,
      'learning': learning,
      'difficulties': difficulties,
      'observation': null,
      'submitted_at': submittedAt,
      'validated_at': validatedAt,
      'validator_comment': validatorComment,
      'editable': editable,
      'can_submit': editable,
      'activities': activityItems,
      'activities_count': activityItems.length,
      'rotation': {
        'uuid': rotationActiveUuid,
        'sequence': 1,
        'status': 'ACTIVE',
        'period': {'start_date': '2026-10-01', 'end_date': '2026-10-20'},
      },
      'assignment': {
        'uuid': assignmentUuid,
        'status': 'ACTIVE',
        'period': {'start_date': '2026-10-01', 'end_date': '2026-12-15'},
      },
      'campaign': {
        'code': 'CAM-000037',
        'title': 'Stage clinique intégré 2026',
      },
      'hospital': {
        'code': 'HOP-001',
        'name': 'Hôpital Général de Référence de Kinshasa',
      },
      'service': _service,
      'unit': _unit,
      'actions': _logbookActions(uuid, editable: editable),
    };
  }

  static Map<String, dynamic> _logbookActions(
    String uuid, {
    required bool editable,
  }) => {
    'edit': {
      'allowed': editable,
      'method': 'POST',
      'path': '/api/v1/student/logbook',
    },
    'submit': {
      'allowed': editable,
      'method': 'POST',
      'path': '/api/v1/student/logbook/$uuid/submit',
    },
  };

  static Map<String, dynamic> _feedback({
    required String uuid,
    required String date,
    required String type,
    required String title,
    required String comment,
    required bool seen,
    String? seenAt,
  }) => {
    'uuid': uuid,
    'date': date,
    'type': type,
    'title': title,
    'comment': comment,
    'published_at': '$date 16:30:00',
    'seen': seen,
    'seen_at': seenAt,
    'assignment': {'uuid': assignmentUuid},
    'rotation': {'uuid': rotationActiveUuid, 'sequence': 1},
    'hospital': {'name': 'Hôpital Général de Référence de Kinshasa'},
    'unit': {'name': 'Urgences pédiatriques'},
    'author': {'name': 'Dr Grâce Mukendi'},
    'actions': {
      'read': {
        'allowed': !seen,
        'method': 'POST',
        'endpoint': '/api/v1/student/feedbacks/$uuid/read',
      },
    },
  };

  static Map<String, dynamic> _attendance(
    String uuid,
    String date,
    String status,
    String? arrival,
    String? departure,
    int late,
  ) => {
    'uuid': uuid,
    'date': date,
    'status': status,
    'arrival_time': arrival,
    'departure_time': departure,
    'source': 'MOBILE',
    'minutes_late': late,
    'duration_minutes': arrival != null && departure != null ? 488 : null,
    'justification': status == 'JUSTIFIE'
        ? 'Absence médicale justifiée.'
        : null,
    'observation': null,
    'validated': status == 'PRESENT' || status == 'RETARD',
    'validated_at': status == 'PRESENT' || status == 'RETARD'
        ? '$date 17:00:00'
        : null,
    'validator': status == 'PRESENT' || status == 'RETARD'
        ? {'user_id': 14, 'name': 'Dr Grâce Mukendi'}
        : null,
    'rotation': {'uuid': rotationActiveUuid, 'sequence': 1},
    'assignment': {
      'uuid': assignmentUuid,
      'status': 'ACTIVE',
      'start_date': '2026-10-01',
      'end_date': '2026-12-15',
    },
    'campaign': {'code': 'CAM-000037', 'title': 'Stage clinique intégré 2026'},
    'hospital': {
      'code': 'HOP-001',
      'name': 'Hôpital Général de Référence de Kinshasa',
    },
    'unit': _unit,
  };

  static Map<String, dynamic> get _todayAttendance => _attendance(
    'attendance-010',
    '2026-10-10',
    'PRESENT',
    '08:02:00',
    _departureDone ? '16:10:00' : null,
    2,
  );

  static Map<String, dynamic> _punch({
    required String nextAction,
    required bool canPunch,
  }) => {
    'date': '2026-10-10',
    'assignment_id': 47,
    'rotation': _currentRotation,
    'attendance': _todayAttendance,
    'can_punch': canPunch,
    'next_action': nextAction,
    'reason': canPunch ? null : 'Votre pointage du jour est terminé.',
  };

  static Map<String, dynamic> _executionActions({
    required bool arrival,
    required bool departure,
  }) => {
    'arrival': {
      'allowed': arrival,
      'method': 'POST',
      'path': '/api/v1/student/attendance/arrival',
    },
    'departure': {
      'allowed': departure,
      'method': 'POST',
      'path': '/api/v1/student/attendance/departure',
    },
    'logbook': {
      'allowed': true,
      'method': 'POST',
      'path': '/api/v1/student/logbook',
    },
  };

  static void _synchroniserContextePointage() {
    final context = Map<String, dynamic>.from(
      executionContext['context'] as Map,
    );
    context['attendance'] = _todayAttendance;
    context['actions'] = _executionActions(
      arrival: !_arrivalDone,
      departure: _arrivalDone && !_departureDone,
    );
    executionContext['context'] = context;
  }

  static int _count(
    List<Map<String, dynamic>> items,
    String value, {
    String key = 'status',
  }) => items.where((item) => item[key] == value).length;

  static List<Map<String, dynamic>> _copyList(
    List<Map<String, dynamic>> items,
  ) => items.map(Map<String, dynamic>.from).toList(growable: false);

  static List<Map<String, dynamic>> _maps(Object? value) => value is List
      ? value.whereType<Map>().map(Map<String, dynamic>.from).toList()
      : <Map<String, dynamic>>[];
}
