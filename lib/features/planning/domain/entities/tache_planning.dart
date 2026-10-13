import 'package:flutter/material.dart';

class TachePlanning {
  const TachePlanning({
    required this.id,
    required this.titre,
    required this.date,
    required this.heureDebut,
    required this.heureFin,
    required this.type,
    required this.service,
    required this.departement,
    required this.superviseur,
    required this.description,
    this.lieu,
    this.statut = 'À venir',
    this.noteRappel,
    this.couleur = const Color(0xFF2563EB),
  });

  final String id;
  final String titre;
  final DateTime date;
  final String heureDebut;
  final String heureFin;
  final String type;
  final String service;
  final String departement;
  final String superviseur;
  final String description;
  final String? lieu;
  final String statut;
  final String? noteRappel;
  final Color couleur;

  bool get completee =>
      statut.toLowerCase().contains('termin') ||
      statut.toLowerCase().contains('valid') ||
      statut.toLowerCase().contains('fait');

  TachePlanning copyWith({
    String? id,
    String? titre,
    DateTime? date,
    String? heureDebut,
    String? heureFin,
    String? type,
    String? service,
    String? departement,
    String? superviseur,
    String? description,
    String? lieu,
    String? statut,
    String? noteRappel,
    Color? couleur,
  }) {
    return TachePlanning(
      id: id ?? this.id,
      titre: titre ?? this.titre,
      date: date ?? this.date,
      heureDebut: heureDebut ?? this.heureDebut,
      heureFin: heureFin ?? this.heureFin,
      type: type ?? this.type,
      service: service ?? this.service,
      departement: departement ?? this.departement,
      superviseur: superviseur ?? this.superviseur,
      description: description ?? this.description,
      lieu: lieu ?? this.lieu,
      statut: statut ?? this.statut,
      noteRappel: noteRappel ?? this.noteRappel,
      couleur: couleur ?? this.couleur,
    );
  }

  factory TachePlanning.fromJson(Map<String, dynamic> json) {
    DateTime startsAt;
    try {
      startsAt = DateTime.parse(json['starts_at']?.toString() ?? '');
    } catch (_) {
      startsAt = DateTime.now();
    }

    DateTime endsAt;
    try {
      endsAt = DateTime.parse(json['ends_at']?.toString() ?? '');
    } catch (_) {
      endsAt = startsAt.add(const Duration(minutes: 60));
    }

    final hDebut =
        '${startsAt.hour.toString().padLeft(2, '0')}:${startsAt.minute.toString().padLeft(2, '0')}';
    final hFin =
        '${endsAt.hour.toString().padLeft(2, '0')}:${endsAt.minute.toString().padLeft(2, '0')}';

    final typeRaw = json['type']?.toString().toLowerCase() ?? 'stage';
    String typeLibelle = 'Stage';
    Color couleur = const Color(0xFF10B981);

    switch (typeRaw) {
      case 'reunion':
        typeLibelle = 'Chirurgie';
        couleur = const Color(0xFF2563EB);
        break;
      case 'convocation':
        typeLibelle = 'Garde';
        couleur = const Color(0xFFEF4444);
        break;
      case 'visite':
        typeLibelle = 'Stage';
        couleur = const Color(0xFF10B981);
        break;
      case 'evaluation':
        typeLibelle = 'Examen';
        couleur = const Color(0xFF8B5CF6);
        break;
      case 'echeance':
        typeLibelle = 'Projet';
        couleur = const Color(0xFFF97316);
        break;
      default:
        typeLibelle = json['type']?.toString() ?? 'Stage';
        couleur = const Color(0xFF3B82F6);
        break;
    }

    final status = json['status']?.toString() == 'termine'
        ? 'Terminé'
        : 'À venir';

    return TachePlanning(
      id: json['uuid']?.toString() ?? json['id']?.toString() ?? '',
      titre: json['title']?.toString() ?? 'Événement calendrier',
      date: startsAt,
      heureDebut: hDebut,
      heureFin: hFin,
      type: typeLibelle,
      service: json['service']?.toString() ?? 'Service Hospitalier',
      departement: json['departement']?.toString() ?? 'Département Médical',
      superviseur: json['superviseur']?.toString() ?? 'Superviseur de Stage',
      description: json['description']?.toString() ?? '',
      lieu: json['location']?.toString() ?? json['lieu']?.toString(),
      statut: status,
      noteRappel: json['note_rappel']?.toString(),
      couleur: couleur,
    );
  }

  factory TachePlanning.depuisTacheStage(Map<String, dynamic> json) {
    final echeance =
        DateTime.tryParse(
          (json['date_echeance'] ?? json['due_date'])?.toString() ?? '',
        ) ??
        DateTime.now();
    final statut = (json['statut'] ?? json['status'])?.toString() ?? '';

    return TachePlanning(
      id: json['uuid']?.toString() ?? json['id']?.toString() ?? '',
      titre: json['titre']?.toString() ?? json['title']?.toString() ?? '',
      date: echeance,
      heureDebut:
          '${echeance.day.toString().padLeft(2, '0')}/'
          '${echeance.month.toString().padLeft(2, '0')}',
      heureFin: '',
      type: 'Stage',
      service: json['unit_name']?.toString() ?? '',
      departement: json['host_name']?.toString() ?? '',
      superviseur: '',
      description: json['description']?.toString() ?? '',
      lieu: [json['unit_name']?.toString(), json['host_name']?.toString()]
          .whereType<String>()
          .where((value) => value.trim().isNotEmpty)
          .join(' • '),
      statut: statut.replaceAll('_', ' '),
      noteRappel: json['commentaire_encadreur']?.toString(),
      couleur: statut == 'TERMINEE' || statut == 'VALIDEE'
          ? const Color(0xFF16A34A)
          : const Color(0xFF2563EB),
    );
  }

  factory TachePlanning.depuisRotationStage(
    Map<String, dynamic> json, {
    String nomHopital = '',
    DateTime? dateAffichee,
  }) {
    final period = json['period'] is Map ? json['period'] as Map : const {};
    final service = json['service'] is Map ? json['service'] as Map : const {};
    final unit = json['unit'] is Map ? json['unit'] as Map : const {};
    final supervisor = json['supervisor'] is Map
        ? json['supervisor'] as Map
        : const {};

    final debut =
        DateTime.tryParse(
          (period['start_date'] ?? json['date_debut'])?.toString() ?? '',
        ) ??
        DateTime.now();
    final fin =
        DateTime.tryParse(
          (period['end_date'] ?? json['date_fin'])?.toString() ?? '',
        ) ??
        debut;

    final nomService =
        (service['name'] ?? json['service_name'] ?? json['unit_name'] ?? '')
            .toString();
    final nomUnite = unit['name']?.toString();
    final titreAffiche = nomUnite != null && nomUnite.isNotEmpty
        ? '$nomService ($nomUnite)'
        : nomService;

    final nomSuperviseur = (supervisor['name'] ?? json['supervisor_name'] ?? '')
        .toString();
    final objectifs = (json['objectives'] ?? json['objectifs'] ?? '')
        .toString();
    final statutRotation = (json['status'] ?? json['statut'])?.toString() ?? '';

    final estActif = statutRotation == 'ACTIVE' || statutRotation == 'EN_COURS';
    final estTermine = statutRotation == 'TERMINEE';

    return TachePlanning(
      id:
          json['uuid']?.toString() ??
          json['rotation_uuid']?.toString() ??
          json['rotation_id']?.toString() ??
          json['id']?.toString() ??
          '',
      titre: titreAffiche,
      date: dateAffichee ?? debut,
      heureDebut:
          '${debut.day.toString().padLeft(2, '0')}/${debut.month.toString().padLeft(2, '0')}',
      heureFin:
          '${fin.day.toString().padLeft(2, '0')}/${fin.month.toString().padLeft(2, '0')}',
      type: 'Stage',
      service: nomService,
      departement: nomHopital,
      superviseur: nomSuperviseur,
      description: objectifs,
      lieu: nomHopital.isEmpty ? titreAffiche : '$titreAffiche • $nomHopital',
      statut: estActif
          ? 'En cours'
          : (estTermine
                ? 'Terminée'
                : (statutRotation == 'PLANIFIEE'
                      ? 'Planifiée'
                      : statutRotation)),
      noteRappel: 'Du ${_dateCourte(debut)} au ${_dateCourte(fin)}',
      couleur: estActif
          ? const Color(0xFF2563EB)
          : (estTermine ? const Color(0xFF16A34A) : const Color(0xFFF59E0B)),
    );
  }

  static String _dateCourte(DateTime date) =>
      '${date.day.toString().padLeft(2, '0')}/'
      '${date.month.toString().padLeft(2, '0')}/${date.year}';
}
