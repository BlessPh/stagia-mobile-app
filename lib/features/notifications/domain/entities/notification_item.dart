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
  obligationPaiement,
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
    final eventName = json['event']?.toString().toLowerCase() ?? '';
    final rawSubject = json['subject']?.toString() ?? '';

    TypeNotification notifType;
    IconData icone;
    Color couleur;

    final isStageEvent = rawType == 'internship' ||
        eventName.startsWith('stage.') ||
        eventName.startsWith('internship.');

    if (isStageEvent) {
      notifType = TypeNotification.stage;
      if (eventName.contains('rejected') || eventName.contains('cancelled') || eventName.contains('expired')) {
        icone = Icons.cancel_outlined;
        couleur = const Color(0xFFEF4444);
      } else if (eventName.contains('payment')) {
        icone = Icons.payment_rounded;
        couleur = const Color(0xFFFF7417);
      } else if (eventName.contains('rotation')) {
        icone = Icons.sync_alt_rounded;
        couleur = const Color(0xFF2563EB);
      } else if (eventName.contains('assignment')) {
        icone = Icons.assignment_turned_in_rounded;
        couleur = const Color(0xFF10B981);
      } else {
        icone = Icons.local_hospital_rounded;
        couleur = const Color(0xFF1D61F2);
      }
    } else {
      switch (rawType) {
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
    }

    final actionMap = json['action'] is Map ? json['action'] as Map<String, dynamic> : null;
    final actionTypeRaw = actionMap?['type']?.toString().toLowerCase() ?? json['action_type']?.toString().toLowerCase() ?? '';
    final targetId = actionMap?['target_id']?.toString() ?? json['target_id']?.toString() ?? json['assignment_id']?.toString() ?? json['assignment_uuid']?.toString();
    final actionLabel = actionMap?['label']?.toString() ?? 'Voir';
    final actionTitle = actionMap?['title']?.toString();
    final metadata = actionMap?['metadata'] is Map
        ? Map<String, dynamic>.from(actionMap!['metadata'] as Map)
        : (json['metadata'] is Map ? Map<String, dynamic>.from(json['metadata'] as Map) : <String, dynamic>{});

    // Compléter metadata avec les infos de rotation et affectation si présentes à la racine
    if (json['period'] != null) metadata['period'] = json['period'];
    if (json['service'] != null) metadata['service'] = json['service'];
    if (json['unit'] != null) metadata['unit'] = json['unit'];
    if (json['supervisor'] != null) metadata['supervisor'] = json['supervisor'];

    TypeCibleNotification cibleType;
    if (eventName.startsWith('stage.rotation.') || actionTypeRaw == 'rotation') {
      cibleType = TypeCibleNotification.affectationStage;
    } else if (eventName.startsWith('stage.assignment.') || actionTypeRaw == 'internship_assignment' || actionTypeRaw == 'assignment') {
      cibleType = TypeCibleNotification.affectationStage;
    } else if (eventName == 'stage.reservation.payment_required' || eventName.startsWith('financial.') || actionTypeRaw == 'payment' || actionTypeRaw == 'payment_obligation' || actionTypeRaw == 'obligation') {
      cibleType = TypeCibleNotification.obligationPaiement;
    } else if (eventName.startsWith('stage.reservation.') || eventName.startsWith('stage.placement.')) {
      cibleType = TypeCibleNotification.detailCampagne;
    } else {
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
        case 'payment_obligation':
        case 'obligation':
        case 'payment':
          cibleType = TypeCibleNotification.obligationPaiement;
          break;
        default:
          cibleType = TypeCibleNotification.generique;
          break;
      }
    }

    // Sujet attendu par défaut si absent ou vide
    String sujetCalcule = rawSubject;
    if (sujetCalcule.isEmpty) {
      switch (eventName) {
        case 'stage.reservation.approved':
          sujetCalcule = 'Réservation de stage approuvée';
          break;
        case 'stage.reservation.payment_required':
          sujetCalcule = 'Réservation approuvée — paiement requis';
          break;
        case 'stage.reservation.rejected':
          sujetCalcule = 'Réservation de stage refusée';
          break;
        case 'stage.reservation.expired':
          sujetCalcule = 'Réservation temporaire expirée';
          break;
        case 'stage.placement.confirmed':
          sujetCalcule = 'Placement de stage confirmé';
          break;
        case 'stage.placement.cancelled':
          sujetCalcule = 'Placement de stage annulé';
          break;
        case 'stage.assignment.created':
          sujetCalcule = 'Nouvelle affectation de stage';
          break;
        case 'stage.assignment.updated':
          sujetCalcule = 'Affectation de stage modifiée';
          break;
        case 'stage.rotation.created':
          sujetCalcule = 'Nouvelle rotation de stage';
          break;
        case 'stage.rotation.updated':
          sujetCalcule = 'Planification de rotation modifiée';
          break;
        case 'financial.obligation.created':
          sujetCalcule = 'Paiement requis';
          break;
        case 'financial.payment.succeeded':
          sujetCalcule = 'Paiement confirmé';
          break;
        case 'financial.payment.failed':
          sujetCalcule = 'Paiement non abouti';
          break;
        default:
          sujetCalcule = 'Notification';
          break;
      }
    }

    // Construction enrichie de la description si rotation
    String descCalculee = json['description']?.toString() ?? '';
    if (descCalculee.isEmpty && eventName.startsWith('stage.rotation.')) {
      final period = metadata['period'] as Map?;
      final service = metadata['service'] as Map?;
      final unit = metadata['unit'] as Map?;
      final supervisor = metadata['supervisor'] as Map?;

      final pStr = period != null ? 'Période : ${period['start_date'] ?? ''} au ${period['end_date'] ?? ''}' : '';
      final sStr = service != null ? (service['name'] ?? '') : '';
      final uStr = unit != null ? ' (${unit['name'] ?? ''})' : '';
      final supStr = supervisor != null ? ' • Superviseur : ${supervisor['name'] ?? ''}' : '';
      descCalculee = [if (sStr.isNotEmpty) '$sStr$uStr', if (pStr.isNotEmpty) pStr, if (supStr.isNotEmpty) supStr].join(' • ');
    }

    DateTime parsedDate;
    try {
      parsedDate = DateTime.parse(json['created_at']?.toString() ?? '');
    } catch (_) {
      parsedDate = DateTime.now();
    }

    return NotificationItem(
      id: json['id']?.toString() ?? json['uuid']?.toString() ?? DateTime.now().millisecondsSinceEpoch.toString(),
      sujet: sujetCalcule,
      description: descCalculee,
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
      lue: json['read_at'] != null || json['read'] == true,
    );
  }
}

