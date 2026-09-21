import 'package:flutter/material.dart';
import '../../domain/entities/notification_item.dart';

abstract final class SourceNotificationsMock {
  static List<NotificationItem> obtenirNotifications() {
    final maintenant = DateTime.now();
    return [
      NotificationItem(
        id: 'notif_1',
        sujet: 'Affectation de stage confirmée',
        description:
            'Vous avez été affecté au service de Chirurgie Viscérale à l’Hôpital Général Provincial. Votre intégration débute le 1er du mois prochain.',
        date: maintenant.subtract(const Duration(minutes: 15)),
        type: TypeNotification.stage,
        icone: Icons.local_hospital_rounded,
        couleur: const Color(0xFF1D61F2),
        actionLabel: 'Voir mon affectation',
        cible: const CibleNotification(
          type: TypeCibleNotification.affectationStage,
          titre: 'Chirurgie Viscérale',
        ),
        lue: false,
      ),
      NotificationItem(
        id: 'notif_2',
        sujet: 'Nouveau message d’encadrement',
        description:
            'Dr. Patrick Mwamba vous a envoyé les observations cliniques concernant votre patiente de la chambre 204.',
        date: maintenant.subtract(const Duration(hours: 2, minutes: 10)),
        type: TypeNotification.message,
        icone: Icons.chat_bubble_outline_rounded,
        couleur: const Color(0xFFFF7417),
        actionLabel: 'Ouvrir la discussion',
        cible: const CibleNotification(
          type: TypeCibleNotification.discussionChat,
          identifiant: 'disc_mwamba',
          titre: 'Dr. Patrick Mwamba',
        ),
        lue: false,
      ),
      NotificationItem(
        id: 'notif_3',
        sujet: 'Campagne de stages ouverte',
        description:
            'La campagne officielle des stages hospitaliers pour votre promotion est désormais accessible. Réservez votre place dès maintenant.',
        date: maintenant.subtract(const Duration(hours: 5, minutes: 45)),
        type: TypeNotification.stage,
        icone: Icons.assignment_turned_in_rounded,
        couleur: const Color(0xFF10B981),
        actionLabel: 'Explorer les hôpitaux',
        cible: const CibleNotification(
          type: TypeCibleNotification.detailCampagne,
        ),
        lue: false,
      ),
      NotificationItem(
        id: 'notif_4',
        sujet: 'Rapport de stage validé',
        description:
            'Votre rapport hebdomadaire d’activités cliniques a été évalué et validé avec mention "Très bien" par votre maître de stage.',
        date: maintenant.subtract(const Duration(days: 1, hours: 3)),
        type: TypeNotification.journal,
        icone: Icons.verified_rounded,
        couleur: const Color(0xFF8B5CF6),
        actionLabel: 'Consulter le rapport',
        cible: const CibleNotification(
          type: TypeCibleNotification.journalTaches,
        ),
        lue: true,
      ),
      NotificationItem(
        id: 'notif_5',
        sujet: 'Rappel de garde clinique',
        description:
            'Votre tour de garde au service des Urgences commence demain à 08h00. Veuillez vous présenter auprès du chef de garde à l’heure.',
        date: maintenant.subtract(const Duration(days: 2)),
        type: TypeNotification.urgence,
        icone: Icons.schedule_rounded,
        couleur: const Color(0xFFEF4444),
        actionLabel: 'Voir les consignes',
        cible: const CibleNotification(
          type: TypeCibleNotification.generique,
        ),
        lue: true,
      ),
      NotificationItem(
        id: 'notif_6',
        sujet: 'Diffusion officielle Décanat',
        description:
            'Note de service N°038 : Protocole sanitaire renforcé et calendrier des évaluations cliniques de fin de semestre.',
        date: maintenant.subtract(const Duration(days: 3)),
        type: TypeNotification.academique,
        icone: Icons.campaign_rounded,
        couleur: const Color(0xFFF59E0B),
        actionLabel: 'Lire le communiqué',
        cible: const CibleNotification(
          type: TypeCibleNotification.discussionChat,
          identifiant: 'disc_diffusion',
          titre: 'Diffusion Décanat Santé',
        ),
        lue: true,
      ),
    ];
  }
}
