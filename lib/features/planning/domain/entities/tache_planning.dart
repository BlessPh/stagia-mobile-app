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
}
