import '../network/endpoints_api.dart';
import 'depot_mock_etudiant.dart';

abstract final class DonneesEtudiantMockees {
  static Map<String, dynamic> pourEndpoint(String endpoint) {
    if (endpoint == EndpointsApi.tableauDeBordEtudiant) {
      return {
        ...tableauDeBord,
        'stats': {
          ...Map<String, dynamic>.from(tableauDeBord['stats'] as Map),
          'applications': DepotMockEtudiant.candidatures.length,
        },
      };
    }
    if (endpoint == EndpointsApi.candidaturesEtudiant) {
      final items = DepotMockEtudiant.candidatures;
      return {'items': items, 'total': items.length};
    }
    if (endpoint == EndpointsApi.reservationsEtudiant) {
      final items = DepotMockEtudiant.reservations;
      return {
        'items': items,
        'stats': {
          'total': items.length,
          'temporary': items
              .where((e) => e['statut'] == 'RESERVEE_TEMPORAIREMENT')
              .length,
          'waiting_payment':
              items.where((e) => e['statut'] == 'EN_ATTENTE_PAIEMENT').length,
          'confirmed': items.where((e) => e['statut'] == 'CONFIRMEE').length,
          'expired': items.where((e) => e['statut'] == 'EXPIREE').length,
        },
      };
    }
    if (endpoint == EndpointsApi.journalEtudiant) {
      final items = DepotMockEtudiant.journal;
      return {
        'items': items,
        'stats': {
          'total': items.length,
          'brouillon': items
              .where((e) =>
                  e['status'] == 'BROUILLON' || e['statut'] == 'BROUILLON')
              .length,
          'soumis': items
              .where(
                  (e) => e['status'] == 'SOUMIS' || e['statut'] == 'SOUMIS')
              .length,
          'valide': items
              .where(
                  (e) => e['status'] == 'VALIDE' || e['statut'] == 'VALIDE')
              .length,
          'rejete': items
              .where(
                  (e) => e['status'] == 'REJETE' || e['statut'] == 'REJETE')
              .length,
        },
        'can_add': true,
      };
    }
    if (endpoint == EndpointsApi.documentsEtudiant) {
      final itemsCandidatures = DepotMockEtudiant.documents;
      final itemsOfficiels = (documents['items'] as List?)
              ?.whereType<Map>()
              .map(Map<String, dynamic>.from)
              .toList() ??
          <Map<String, dynamic>>[];
      final tous = [...itemsOfficiels, ...itemsCandidatures];
      return {
        'items': tous,
        'stats': {
          'total': tous.length,
          'attestations': tous
              .where((d) => d['type_document'] == 'ATTESTATION_STAGE')
              .length,
          'certificates': tous
              .where((d) => d['type_document'] == 'CERTIFICAT_STAGE')
              .length,
          'available': tous.length,
          'cancelled': 0,
        },
      };
    }
    if (endpoint == EndpointsApi.notificationsEtudiant) {
      final items = DepotMockEtudiant.notifications;
      return {
        'items': items,
        'next_before_id': null,
        'counts': DepotMockEtudiant.notificationCounts,
      };
    }
    if (endpoint == EndpointsApi.notificationsCounts) {
      return DepotMockEtudiant.notificationCounts;
    }
    if (endpoint == EndpointsApi.communicationContacts) {
      final items = DepotMockEtudiant.contacts;
      return {'items': items, 'total': items.length};
    }
    if (endpoint == EndpointsApi.conversations) {
      final items = DepotMockEtudiant.conversations;
      return {'items': items, 'limit': 30, 'offset': 0};
    }
    if (endpoint == EndpointsApi.communicationsOfficielles) {
      final items = DepotMockEtudiant.communications;
      return {'items': items, 'limit': 30, 'offset': 0};
    }
    if (endpoint == EndpointsApi.calendrierEtudiant) {
      final items = DepotMockEtudiant.calendrier;
      return {'items': items};
    }
    if (endpoint == EndpointsApi.notificationsPreferences) {
      return {
        'items': [
          {'type': '*', 'channel': 'push', 'active': true},
          {'type': '*', 'channel': 'email', 'active': true},
          {'type': '*', 'channel': 'sms', 'active': false},
        ],
        'defaults': {'email': true, 'sms': false, 'push': true},
        'internal_notifications': true,
      };
    }
    if (endpoint == EndpointsApi.notificationsDevices) {
      return {
        'items': [
          {
            'uuid': '01JQ0DEV000000000000000001',
            'platform': 'android',
            'device_name': 'Pixel 8 Pro',
            'app_version': '1.0.0',
            'active': true,
            'last_seen_at': DateTime.now().toIso8601String(),
          }
        ]
      };
    }
    return Map<String, dynamic>.from(switch (endpoint) {
      EndpointsApi.profilEtudiant => profil,
      EndpointsApi.profilActifEtudiant => profil,
      EndpointsApi.rattachementsEtudiant => rattachements,
      EndpointsApi.parcoursAcademiqueEtudiant => parcoursAcademique,
      EndpointsApi.optionsStageEtudiant => optionsStage,
      EndpointsApi.stagesEtudiant => stages,
      EndpointsApi.reservationsEtudiant => reservations,
      EndpointsApi.admissionEtudiant => admission,
      EndpointsApi.presencesEtudiant => presences,
      EndpointsApi.evaluationsEtudiant => evaluations,
      EndpointsApi.paiementsEtudiant => paiements,
      EndpointsApi.initierPaiementEtudiant => paiementCheckout,
      EndpointsApi.paiementSync => paiementSync,
      _ => <String, dynamic>{},
    });
  }


  static const profil = <String, dynamic>{
    'user': {
      'identifiant': 'STG-ETU-00000030',
      'nom': 'KALONJI',
      'prenom': 'Alfred',
      'email': 'alfred.kalonji@stagia.cd',
      'actif': true,
      'role': {'code': 'STAGIAIRE', 'nom': 'Stagiaire'},
    },
    'student': {
      'stagia_code': 'STG-ETU-00000030',
      'nom': 'KALONJI',
      'postnom': '',
      'prenom': 'Alfred',
      'sexe': 'Masculin',
      'identifiant': 'STG-ETU-00000030',
      'email': 'alfred.kalonji@stagia.cd',
      'telephone': '+243 812 345 678',
      'province': 'Kinshasa',
      'university_code': 'UNIKIN',
      'university_name': 'Université de Kinshasa',
      'faculty_name': 'Faculté de Médecine',
      'department_name': 'Médecine Générale',
      'option_name': 'Chirurgie',
      'promotion_name': 'Licence 3',
      'academic_year': '2025-2026',
      'statut': 'ACTIF',
      'academic_status': 'ACTIF',
      'promotion': 'Licence 3',
      'filiere': 'Médecine Générale',
    },
  };

  static const tableauDeBord = <String, dynamic>{
    'student': {
      'stagia_code': 'STG-ETU-00000030',
      'nom': 'KALONJI',
      'postnom': '',
      'prenom': 'Alfred',
      'email': 'alfred.kalonji@stagia.cd',
      'identifiant': 'STG-ETU-00000030',
    },
    'stats': {
      'applications': 1,
      'active_reservations': 1,
      'stages': 1,
      'planned_stages': 0,
      'active_stages': 1,
      'completed_stages': 0,
      'validated_stages': 0,
      'documents': 2,
    },
    'current_stage': <String, dynamic>{
      'uuid': '6c049f97-408e-4fc2-bd59-11848000a714',
      'statut': 'ACTIVE',
      'date_debut': '2026-09-01',
      'date_fin': '2026-11-30',
      'campaign_code': 'CAM-STAGIA-001',
      'campaign_title': 'Campagne de stages professionnels 2026',
      'hospital_code': 'ENT-001',
      'hospital_name': 'Cliniques Universitaires de Kinshasa',
      'unit_code': 'CHIR-01',
      'unit_name': 'Service de Chirurgie Générale',
      'completion_status': 'EN_COURS',
      'taux_presence': 92.5,
      'note_finale': 17.0,
      'certificate_uuid': null,
      'certificate_reference': null,
    },
  };

  static const optionsStage = <String, dynamic>{
    'campaigns': [
      {
        'campaign_id': 1,
        'academic_enrollment_id': 1,
        'code': 'CAM-STAGIA-001',
        'title': 'Campagne de stages professionnels 2026',
        'start_date': '2026-10-01',
        'end_date': '2027-01-31',
        'promotion': {'code': 'L3', 'name': 'Licence 3', 'level': 'L3'},
        'program': 'Médecine Générale',
        'hospitals_count': 4,
        'available_hospitals': 4,
        'available_places': 30,
        'hospitals': [
          {
            'participation_id': 101,
            'hospital': {
              'id': 1,
              'code': 'ENT-001',
              'name': 'Cliniques Universitaires de Kinshasa',
              'city': 'Lemba',
              'province': 'Kinshasa',
              'latitude': -4.4172,
              'longitude': 15.3090,
            },
            'code': 'ENT-001',
            'name': 'Cliniques Universitaires de Kinshasa',
            'city': 'Lemba',
            'province': 'Kinshasa',
            'latitude': -4.4172,
            'longitude': 15.3090,
            'capacity': 10,
            'used_places': 5,
            'available_places': 5,
            'available': true,
            'fees_required': false,
            'amount': null,
            'currency': null,
            'conditions': 'Tenue médicale réglementaire obligatoire.',
          },
          {
            'participation_id': 102,
            'hospital': {
              'id': 2,
              'code': 'ENT-002',
              'name': 'Clinique Ngaliema',
              'city': 'Gombe',
              'province': 'Kinshasa',
              'latitude': -4.3060,
              'longitude': 15.2866,
            },
            'code': 'ENT-002',
            'name': 'Clinique Ngaliema',
            'city': 'Gombe',
            'province': 'Kinshasa',
            'latitude': -4.3060,
            'longitude': 15.2866,
            'capacity': 8,
            'used_places': 3,
            'available_places': 5,
            'available': true,
            'fees_required': false,
            'amount': null,
            'currency': null,
            'conditions': 'Dossier d’aptitude médicale requis.',
          },
          {
            'participation_id': 103,
            'hospital': {
              'id': 3,
              'code': 'ENT-003',
              'name': 'Hôpital Général de Référence de Kinshasa',
              'city': 'Gombe',
              'province': 'Kinshasa',
              'latitude': -4.3168,
              'longitude': 15.3082,
            },
            'code': 'ENT-003',
            'name': 'Hôpital Général de Référence de Kinshasa',
            'city': 'Gombe',
            'province': 'Kinshasa',
            'latitude': -4.3168,
            'longitude': 15.3082,
            'capacity': 15,
            'used_places': 3,
            'available_places': 12,
            'available': true,
            'fees_required': false,
            'amount': null,
            'currency': null,
            'conditions': 'Respect du planning de garde.',
          },
          {
            'participation_id': 104,
            'hospital': {
              'id': 4,
              'code': 'ENT-004',
              'name': 'Centre Hospitalier Monkole',
              'city': 'Mont-Ngafula',
              'province': 'Kinshasa',
              'latitude': -4.4137,
              'longitude': 15.2652,
            },
            'code': 'ENT-004',
            'name': 'Centre Hospitalier Monkole',
            'city': 'Mont-Ngafula',
            'province': 'Kinshasa',
            'latitude': -4.4137,
            'longitude': 15.2652,
            'capacity': 8,
            'used_places': 3,
            'available_places': 5,
            'available': true,
            'fees_required': false,
            'amount': null,
            'currency': null,
            'conditions': 'Assiduité et ponctualité obligatoires.',
          },
        ],
      },
    ],
    'stats': {
      'campaigns': 1,
      'hospitals': 4,
      'available_hospitals': 4,
      'available_places': 30,
    },
  };

  static const stages = <String, dynamic>{
    'items': [
      {
        'uuid': '6c049f97-408e-4fc2-bd59-11848000a714',
        'statut': 'ACTIVE',
        'date_debut': '2026-09-01',
        'date_fin': '2026-11-30',
        'observation': "Stage d'immersion clinique en chirurgie générale.",
        'assigned_at': '2026-08-25 09:00:00',
        'ended_at': null,
        'campaign_code': 'CAM-STAGIA-001',
        'campaign_title': 'Campagne de stages professionnels 2026',
        'campaign_start': '2026-09-01',
        'campaign_end': '2026-11-30',
        'hospital_code': 'ENT-001',
        'hospital_name': 'Cliniques Universitaires de Kinshasa',
        'ville': 'Lemba',
        'province': 'Kinshasa',
        'unit_code': 'CHIR-01',
        'unit_name': 'Service de Chirurgie Générale',
        'completion_status': 'EN_COURS',
        'total_rotations': 2,
        'total_presences': 24,
        'total_retards': 1,
        'total_absences': 0,
        'total_justifiees': 0,
        'taux_presence': 92.5,
        'total_journaux': 18,
        'journaux_valides': 16,
        'note_finale': 17.0,
        'appreciation_finale':
            'Très bon investissement clinique et régularité exemplaire.',
        'validated_at': null,
        'certificate_uuid': null,
        'certificate_reference': null,
        'certificate_type': null,
        'certificate_status': null,
        'certificate_generated_at': null,
        'workflow_status': 'EN_COURS',
        'certificate_available': false,
        'rotations': [
          {
            'service_name': 'Service de Chirurgie Générale',
            'unit_name': 'Chirurgie Générale',
            'supervisor_name': 'Dr. Jean Mukendi',
            'date_debut': '2026-09-01',
            'date_fin': '2026-10-15',
            'workflow_status': 'EN_COURS',
          },
          {
            'service_name': 'Traumatologie & Orthopédie',
            'unit_name': 'Traumatologie',
            'supervisor_name': 'Dr. Marie Kapinga',
            'date_debut': '2026-10-16',
            'date_fin': '2026-11-30',
            'workflow_status': 'PLANIFIEE',
          },
        ],
      },
    ],
    'stats': {
      'total': 1,
      'planned': 0,
      'active': 1,
      'completed': 0,
      'validated': 0,
    },
  };

  static const reservations = <String, dynamic>{
    'items': [
      {
        'uuid': 'STG-RES-84920',
        'statut': 'RESERVEE_TEMPORAIREMENT',
        'expires_at': '2026-09-19 18:30:00',
        'confirmed_at': null,
        'application_uuid': 'app-candidature-001',
        'application_status': 'SOUMISE',
        'campaign_code': 'CAM-STAGIA-001',
        'campaign_title': 'Campagne de stages professionnels 2026',
        'campaign_start': '2026-10-01',
        'campaign_end': '2027-01-31',
        'hospital_code': 'ENT-001',
        'hospital_name': 'Cliniques Universitaires de Kinshasa',
        'ville': 'Lemba',
        'province': 'Kinshasa',
        'frais_requis': false,
        'montant_frais': null,
        'devise': null,
        'admitted': false,
        'assignment_uuid': null,
        'assignment_status': null,
        'completion_status': null,
        'expired': false,
        'workflow_status': 'EN_ATTENTE_VALIDATION',
      },
    ],
    'stats': {
      'total': 1,
      'temporary': 1,
      'waiting_payment': 0,
      'confirmed': 0,
      'expired': 0,
    },
  };

  static const admission = <String, dynamic>{
    'items': [
      {
        'reservation': {
          'uuid': 'STG-RES-84920',
          'status': 'RESERVEE_TEMPORAIREMENT',
          'expires_at': '2026-09-19 18:30:00',
          'confirmed_at': null,
        },
        'application': {
          'uuid': 'app-candidature-001',
          'status': 'SOUMISE',
        },
        'admission': {
          'exists': false,
          'uuid': null,
          'status': null,
          'admitted_at': null,
          'observation': null,
        },
        'assignment': {
          'exists': false,
          'assigned_at': null,
          'ended_at': null,
          'observation': null,
          'unit': {'code': null, 'name': null},
        },
        'campaign': {
          'code': 'CAM-STAGIA-001',
          'name': 'Campagne de stages professionnels 2026',
        },
        'hospital': {
          'code': 'ENT-001',
          'name': 'Cliniques Universitaires de Kinshasa',
          'city': 'Lemba',
          'province': 'Kinshasa',
        },
        'completion': {
          'status': null,
          'attendance_rate': null,
          'final_score': null,
        },
        'workflow_status': 'RESERVATION_EN_COURS',
      },
    ],
    'stats': {
      'total': 1,
      'waiting_admission': 1,
      'admitted': 0,
      'waiting_assignment': 0,
      'assigned': 0,
      'active': 0,
      'completed': 0,
    },
  };

  static const documents = <String, dynamic>{
    'items': [
      {
        'uuid': 'doc-att-001',
        'reference': 'ATT-2026-STG-0030',
        'title': 'Attestation de Stage Clinique',
        'type_document': 'ATTESTATION_STAGE',
        'status': 'DISPONIBLE',
        'available': true,
        'generated_at': '2026-09-18 16:30:00',
        'cancelled_at': null,
        'cancellation_reason': null,
        'verification_url': 'https://stagia.cd/verify/doc-att-001',
        'pdf_endpoint': '/student/documents/doc-att-001/pdf',
        'stage': {
          'assignment_uuid': '6c049f97-408e-4fc2-bd59-11848000a714',
          'start_date': '2026-08-01',
          'end_date': '2026-09-30',
          'note_finale': 17.0,
          'taux_presence': 92.5,
          'validated_at': '2026-09-18 15:30:00',
        },
        'campaign': {
          'code': 'CAM-STAGIA-001',
          'name': 'Campagne de stages professionnels 2026',
        },
        'hospital': {
          'code': 'ENT-001',
          'name': 'Cliniques Universitaires de Kinshasa',
        },
        'university': {
          'code': 'UNIKIN',
          'name': 'Université de Kinshasa',
        },
        'unit': {
          'code': 'UN-001',
          'name': 'Service de Chirurgie Générale',
        },
      },
    ],
    'stats': {
      'total': 1,
      'attestations': 1,
      'certificates': 0,
      'available': 1,
      'cancelled': 0,
    },
  };

  static const presences = <String, dynamic>{
    'attendance_rate': 92.5,
    'present_days': 24,
    'absent_days': 0,
    'late_days': 1,
    'excused_days': 0,
    'total_days': 25,
    'items': [
      {
        'uuid': 'att-025',
        'date': '2026-09-18',
        'arrival_time': '07:28:00',
        'departure_time': '16:05:00',
        'time_in': '07:28:00',
        'time_out': '16:05:00',
        'status': 'PRESENT',
        'statut': 'PRESENT',
        'observation': 'Visite en salle commune et pansements.',
        'justified': true,
        'hospital_name': 'Cliniques Universitaires de Kinshasa',
        'unit_name': 'Service de Chirurgie Générale',
        'hospital': {
          'code': 'ENT-001',
          'name': 'Cliniques Universitaires de Kinshasa',
        },
        'unit': {
          'code': 'UN-001',
          'name': 'Service de Chirurgie Générale',
        },
      },
      {
        'uuid': 'att-024',
        'date': '2026-09-17',
        'arrival_time': '07:35:00',
        'departure_time': '16:00:00',
        'time_in': '07:35:00',
        'time_out': '16:00:00',
        'status': 'PRESENT',
        'statut': 'PRESENT',
        'observation': 'Assistance en bloc opératoire.',
        'justified': true,
        'hospital_name': 'Cliniques Universitaires de Kinshasa',
        'unit_name': 'Service de Chirurgie Générale',
        'hospital': {
          'code': 'ENT-001',
          'name': 'Cliniques Universitaires de Kinshasa',
        },
        'unit': {
          'code': 'UN-001',
          'name': 'Service de Chirurgie Générale',
        },
      },
      {
        'uuid': 'att-023',
        'date': '2026-09-16',
        'arrival_time': '08:12:00',
        'departure_time': '16:15:00',
        'time_in': '08:12:00',
        'time_out': '16:15:00',
        'status': 'RETARD',
        'statut': 'RETARD',
        'observation': 'Retard de transport signalé et pris en compte.',
        'justified': true,
        'hospital_name': 'Cliniques Universitaires de Kinshasa',
        'unit_name': 'Service de Chirurgie Générale',
        'hospital': {
          'code': 'ENT-001',
          'name': 'Cliniques Universitaires de Kinshasa',
        },
        'unit': {
          'code': 'UN-001',
          'name': 'Service de Chirurgie Générale',
        },
      },
      {
        'uuid': 'att-022',
        'date': '2026-09-15',
        'arrival_time': '07:25:00',
        'departure_time': '15:55:00',
        'time_in': '07:25:00',
        'time_out': '15:55:00',
        'status': 'PRESENT',
        'statut': 'PRESENT',
        'observation': 'Aide opératoire en hernie inguinale.',
        'justified': true,
        'hospital_name': 'Cliniques Universitaires de Kinshasa',
        'unit_name': 'Service de Chirurgie Générale',
        'hospital': {
          'code': 'ENT-001',
          'name': 'Cliniques Universitaires de Kinshasa',
        },
        'unit': {
          'code': 'UN-001',
          'name': 'Service de Chirurgie Générale',
        },
      },
    ],
    'stats': {
      'total': 25,
      'present': 24,
      'late': 1,
      'absent': 0,
      'excused': 0,
      'guard': 0,
      'effective_presence': 24,
      'attendance_rate': 92.5,
    },
  };

  static const journal = <String, dynamic>{
    'items': <Map<String, dynamic>>[],
    'stats': {'total': 0, 'validated': 0, 'activities': 0},
  };

  static const evaluations = <String, dynamic>{
    'items': [
      {
        'uuid': 'eval-001',
        'type': 'MI_ROTATION',
        'status': 'VALIDEE',
        'note': 17.0,
        'score': 17.0,
        'max_score': 20.0,
        'appreciation':
            'Très bon investissement clinique et régularité exemplaire.',
        'validated_at': '2026-09-18 15:30:00',
        'rotation_id': 1,
        'stage_uuid': '6c049f97-408e-4fc2-bd59-11848000a714',
        'assignment': {
          'assignment_uuid': '6c049f97-408e-4fc2-bd59-11848000a714',
        },
        'campaign': {
          'code': 'CAM-STAGIA-001',
          'name': 'Campagne de stages professionnels 2026',
        },
        'hospital': {
          'code': 'ENT-001',
          'name': 'Cliniques Universitaires de Kinshasa',
        },
        'unit': {
          'code': 'UN-001',
          'name': 'Service de Chirurgie Générale',
        },
        'hospital_name': 'Cliniques Universitaires de Kinshasa',
        'unit_name': 'Service de Chirurgie Générale',
        'evaluator_name': 'Dr. Jean Mukendi',
        'evaluated_at': '2026-09-18 15:30:00',
      },
    ],
    'stats': {
      'total': 1,
      'continuous': 0,
      'mid_rotation': 1,
      'final_rotation': 0,
      'average': 17.0,
    },
    'final_evaluation': null,
  };

  static const paiements = <String, dynamic>{
    'items': [
      {
        'uuid': 'inv-001',
        'reference': 'FAC-2026-00030',
        'amount': 0.0,
        'currency': 'USD',
        'status': 'PAYEE',
        'paid': true,
        'workflow_status': 'CONFIRMEE',
        'due_at': '2026-10-01 00:00:00',
        'created_at': '2026-09-15 10:00:00',
        'campaign': {
          'code': 'CAM-STAGIA-001',
          'name': 'Campagne de stages professionnels 2026',
        },
        'hospital': {
          'code': 'ENT-001',
          'name': 'Cliniques Universitaires de Kinshasa',
        },
        'payments': [
          {
            'uuid': 'pay-001',
            'reference': 'PAY-2026-00030',
            'amount': 0.0,
            'currency': 'USD',
            'method': 'GRATUIT',
            'status': 'VALIDE',
            'validated': true,
            'paid_at': '2026-09-15 10:05:00',
            'validated_at': '2026-09-15 10:05:00',
            'observation': 'Stage académique sans frais supplémentaires.',
          },
        ],
      },
    ],
    'stats': {
      'invoices': 1,
      'payments': 1,
      'validated_payments': 1,
      'pending_payments': 0,
      'total_paid': 0.0,
      'currency': 'USD',
    },
  };

  static const paiementCheckout = <String, dynamic>{
    'reservation_uuid': 'STG-RES-84920',
    'reservation_status': 'CONFIRMEE',
    'payment_required': false,
    'invoice': null,
    'hospital': {
      'code': 'ENT-001',
      'name': 'Cliniques Universitaires de Kinshasa',
    },
    'payment_gateway': {
      'integrated': false,
      'next_action': 'AWAIT_PAYMENT',
    },
  };

  static const paiementSync = <String, dynamic>{
    'reservation_uuid': 'STG-RES-84920',
    'reservation_status': 'CONFIRMEE',
    'payment_status': 'PAID',
    'invoice_status': 'PAYEE',
    'admission_id': 101,
    'admission_status': 'ATTENDU',
    'amount_required': 0.0,
    'amount_validated': 0.0,
    'amount_remaining': 0.0,
    'currency': 'USD',
    'hospital': {
      'code': 'ENT-001',
      'name': 'Cliniques Universitaires de Kinshasa',
    },
  };

  static const rattachements = <String, dynamic>{
    'enrollments': [
      {
        'enrollment_id': 33,
        'etablissement_id': 1,
        'matricule': 'UNIKIN-MED-2023-0491',
        'email_institutionnel': 'alfred.kalonji@unikin.ac.cd',
        'date_inscription': '2023-10-15',
        'statut': 'ACTIF',
        'etablissement_nom': 'Université de Kinshasa',
        'faculte': 'Faculté de Médecine',
        'promotion': 'Licence 3',
      },
    ],
  };

  static const parcoursAcademique = <String, dynamic>{
    'enrollment': {
      'id': 33,
      'etablissement_id': 1,
      'matricule': 'UNIKIN-MED-2023-0491',
      'statut': 'ACTIF',
      'etablissement_nom': 'Université de Kinshasa',
    },
    'academic_path': [
      {
        'id': 1,
        'statut': 'REUSSI',
        'date_debut': '2023-10-15',
        'date_fin': '2024-07-30',
        'annee_id': 1,
        'annee': '2023-2024',
        'promotion_id': 1,
        'promotion': 'Licence 1',
        'filiere_id': 1,
        'filiere': 'Médecine Générale',
        'faculte': 'Faculté de Médecine',
      },
      {
        'id': 2,
        'statut': 'REUSSI',
        'date_debut': '2024-10-15',
        'date_fin': '2025-07-30',
        'annee_id': 2,
        'annee': '2024-2025',
        'promotion_id': 2,
        'promotion': 'Licence 2',
        'filiere_id': 1,
        'filiere': 'Médecine Générale',
        'faculte': 'Faculté de Médecine',
      },
      {
        'id': 3,
        'statut': 'EN_COURS',
        'date_debut': '2025-10-15',
        'date_fin': '2026-07-30',
        'annee_id': 3,
        'annee': '2025-2026',
        'promotion_id': 3,
        'promotion': 'Licence 3',
        'filiere_id': 1,
        'filiere': 'Médecine Générale',
        'faculte': 'Faculté de Médecine',
      },
    ],
  };
}
