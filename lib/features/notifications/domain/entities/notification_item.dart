import 'package:flutter/material.dart';

enum TypeNotification {
  stage,
  journal,
  message,
  urgence,
  academique,
}

enum TypeCibleNotification {
  affectationStage,
  discussionChat,
  detailCampagne,
  journalTaches,
  generique,
}

class CibleNotification {
  const CibleNotification({
    required this.type,
    this.identifiant,
    this.titre,
    this.donneesSupplementaires = const {},
  });

  final TypeCibleNotification type;
  final String? identifiant;
  final String? titre;
  final Map<String, dynamic> donneesSupplementaires;
}

class NotificationItem {
  NotificationItem({
    required this.id,
    required this.sujet,
    required this.description,
    required this.date,
    required this.type,
    required this.icone,
    required this.couleur,
    required this.actionLabel,
    required this.cible,
    this.lue = false,
  });

  final String id;
  final String sujet;
  final String description;
  final DateTime date;
  final TypeNotification type;
  final IconData icone;
  final Color couleur;
  final String actionLabel;
  final CibleNotification cible;
  bool lue;

  String get tempsRelatif {
    final difference = DateTime.now().difference(date);
    if (difference.inMinutes < 1) {
      return "À l'instant";
    } else if (difference.inMinutes < 60) {
      return 'Il y a ${difference.inMinutes} min';
    } else if (difference.inHours < 24) {
      final minute = date.minute.toString().padLeft(2, '0');
      final heure = date.hour.toString().padLeft(2, '0');
      return "Aujourd'hui · $heure:$minute";
    } else if (difference.inDays == 1) {
      final minute = date.minute.toString().padLeft(2, '0');
      final heure = date.hour.toString().padLeft(2, '0');
      return 'Hier · $heure:$minute';
    } else {
      final jour = date.day.toString().padLeft(2, '0');
      final mois = _nomMois(date.month);
      return '$jour $mois';
    }
  }

  static String _nomMois(int mois) {
    const moisNoms = [
      'janv.',
      'févr.',
      'mars',
      'avr.',
      'mai',
      'juin',
      'juil.',
      'août',
      'sept.',
      'oct.',
      'nov.',
      'déc.',
    ];
    if (mois >= 1 && mois <= 12) {
      return moisNoms[mois - 1];
    }
    return '';
  }

  NotificationItem copyWith({
    String? id,
    String? sujet,
    String? description,
    DateTime? date,
    TypeNotification? type,
    IconData? icone,
    Color? couleur,
    String? actionLabel,
    CibleNotification? cible,
    bool? lue,
  }) {
    return NotificationItem(
      id: id ?? this.id,
      sujet: sujet ?? this.sujet,
      description: description ?? this.description,
      date: date ?? this.date,
      type: type ?? this.type,
      icone: icone ?? this.icone,
      couleur: couleur ?? this.couleur,
      actionLabel: actionLabel ?? this.actionLabel,
      cible: cible ?? this.cible,
      lue: lue ?? this.lue,
    );
  }
}
