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

  factory NotificationItem.fromJson(Map<String, dynamic> json) {
    final rawType = json['type']?.toString().toLowerCase() ?? '';
    TypeNotification notifType;
    IconData icone;
    Color couleur;

    switch (rawType) {
      case 'internship':
        notifType = TypeNotification.stage;
        icone = Icons.local_hospital_rounded;
        couleur = const Color(0xFF1D61F2);
        break;
      case 'message':
        notifType = TypeNotification.message;
        icone = Icons.chat_bubble_outline_rounded;
        couleur = const Color(0xFFFF7417);
        break;
      case 'logbook':
        notifType = TypeNotification.journal;
        icone = Icons.verified_rounded;
        couleur = const Color(0xFF8B5CF6);
        break;
      case 'urgent':
        notifType = TypeNotification.urgence;
        icone = Icons.warning_amber_rounded;
        couleur = const Color(0xFFEF4444);
        break;
      case 'academic':
      default:
        notifType = TypeNotification.academique;
        icone = Icons.campaign_rounded;
        couleur = const Color(0xFFF59E0B);
        break;
    }

    final actionMap = json['action'] is Map ? json['action'] as Map<String, dynamic> : null;
    final actionTypeRaw = actionMap?['type']?.toString().toLowerCase() ?? '';
    final targetId = actionMap?['target_id']?.toString();
    final actionLabel = actionMap?['label']?.toString() ?? 'Voir';
    final actionTitle = actionMap?['title']?.toString();
    final metadata = actionMap?['metadata'] is Map
        ? Map<String, dynamic>.from(actionMap!['metadata'] as Map)
        : <String, dynamic>{};

    TypeCibleNotification cibleType;
    switch (actionTypeRaw) {
      case 'internship_assignment':
        cibleType = TypeCibleNotification.affectationStage;
        break;
      case 'campaign':
        cibleType = TypeCibleNotification.detailCampagne;
        break;
      case 'conversation':
        cibleType = TypeCibleNotification.discussionChat;
        break;
      case 'logbook':
      case 'task':
        cibleType = TypeCibleNotification.journalTaches;
        break;
      default:
        cibleType = TypeCibleNotification.generique;
        break;
    }

    DateTime parsedDate;
    try {
      parsedDate = DateTime.parse(json['created_at']?.toString() ?? '');
    } catch (_) {
      parsedDate = DateTime.now();
    }

    return NotificationItem(
      id: json['id']?.toString() ?? '',
      sujet: json['subject']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      date: parsedDate,
      type: notifType,
      icone: icone,
      couleur: couleur,
      actionLabel: actionLabel,
      cible: CibleNotification(
        type: cibleType,
        identifiant: targetId,
        titre: actionTitle,
        donneesSupplementaires: metadata,
      ),
      lue: json['read_at'] != null,
    );
  }
}

