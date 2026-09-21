import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/widgets/contenu_adaptatif.dart';
import '../../../messagerie/data/datasources/source_messagerie_mock.dart';
import '../../../messagerie/presentation/pages/chat_page.dart';
import '../../../stage/presentation/pages/detail_campagne_page.dart';
import '../../../stage/presentation/pages/hopitaux_disponibles_page.dart';
import '../../data/datasources/source_notifications_mock.dart';
import '../../domain/entities/notification_item.dart';
import '../widgets/carte_notification.dart';
import '../widgets/filtres_notification.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  late List<NotificationItem> _notifications;
  FiltreNotification _filtreActuel = FiltreNotification.toutes;

  @override
  void initState() {
    super.initState();
    _notifications = SourceNotificationsMock.obtenirNotifications();
  }

  int get _compteNonLues {
    return _notifications.where((n) => !n.lue).length;
  }

  List<NotificationItem> get _notificationsFiltrees {
    switch (_filtreActuel) {
      case FiltreNotification.nonLues:
        return _notifications.where((n) => !n.lue).toList();
      case FiltreNotification.stages:
        return _notifications
            .where((n) => n.type == TypeNotification.stage)
            .toList();
      case FiltreNotification.messages:
        return _notifications
            .where((n) => n.type == TypeNotification.message)
            .toList();
      case FiltreNotification.toutes:
        return _notifications;
    }
  }

  void _marquerCommeLue(String id) {
    setState(() {
      final index = _notifications.indexWhere((n) => n.id == id);
      if (index != -1) {
        _notifications[index].lue = true;
      }
    });
  }

  void _toutMarquerCommeLu() {
    setState(() {
      for (final n in _notifications) {
        n.lue = true;
      }
    });
  }

  void _executerActionNotification(NotificationItem notification) {
    // Marque comme lue
    _marquerCommeLue(notification.id);

    // Navigation vers la page cible demandée
    switch (notification.cible.type) {
      case TypeCibleNotification.affectationStage:
        Navigator.of(context).push<void>(
          MaterialPageRoute<void>(
            builder: (_) => const DetailCampagnePage(),
          ),
        );
      case TypeCibleNotification.detailCampagne:
        Navigator.of(context).push<void>(
          MaterialPageRoute<void>(
            builder: (_) => const HopitauxDisponiblesPage(),
          ),
        );
      case TypeCibleNotification.discussionChat:
        final idDiscussion = notification.cible.identifiant ?? 'disc_mwamba';
        final discussions = SourceMessagerieMock.obtenirDiscussions();
        final discussionTrouvee = discussions.firstWhere(
          (d) => d.id == idDiscussion,
          orElse: () => discussions.first,
        );

        Navigator.of(context).push<void>(
          MaterialPageRoute<void>(
            builder: (_) => ChatPage(discussion: discussionTrouvee),
          ),
        );
      case TypeCibleNotification.journalTaches:
      case TypeCibleNotification.generique:
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Redirection vers le document : ${notification.sujet}',
            ),
            duration: const Duration(seconds: 2),
            action: SnackBarAction(
              label: 'Fermer',
              textColor: const Color(0xFFFF7417),
              onPressed: () {},
            ),
          ),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final modeSombre = Theme.of(context).brightness == Brightness.dark;
    final nonLues = _compteNonLues;
    final listeFiltree = _notificationsFiltrees;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        surfaceTintColor: Colors.transparent,
        leading: Navigator.canPop(context)
            ? IconButton(
                icon: Icon(
                  Icons.arrow_back_ios_new_rounded,
                  size: 20,
                  color: modeSombre ? Colors.white : const Color(0xFF0F172A),
                ),
                onPressed: () => Navigator.pop(context),
              )
            : null,
        title: Row(
          children: [
            Text(
              'Notifications',
              style: GoogleFonts.inter(
                fontSize: 20,
                fontWeight: FontWeight.w900,
                color: modeSombre ? Colors.white : const Color(0xFF0F172A),
                letterSpacing: -0.4,
              ),
            ),
            if (nonLues > 0) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFFF7417),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '$nonLues',
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ],
        ),
        actions: [
          if (nonLues > 0)
            TextButton(
              onPressed: _toutMarquerCommeLu,
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFFFF7417),
              ),
              child: Text(
                'Tout lire',
                style: GoogleFonts.inter(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          const SizedBox(width: 4),
        ],
      ),
      body: ContenuAdaptatif(
        largeurMaximale: 820,
        enfant: Column(
          children: [
            // Barre de filtres en puces horizontales
            FiltresNotificationBar(
              filtreActuel: _filtreActuel,
              compteNonLues: nonLues,
              onChangerFiltre: (nouveauFiltre) {
                setState(() => _filtreActuel = nouveauFiltre);
              },
            ),

            // Liste des notifications
            Expanded(
              child: listeFiltree.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 68,
                            height: 68,
                            decoration: BoxDecoration(
                              color: const Color(0xFFFF7417).withValues(alpha: 0.1),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.notifications_none_rounded,
                              color: Color(0xFFFF7417),
                              size: 34,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            _filtreActuel == FiltreNotification.nonLues
                                ? 'Toutes vos notifications sont lues 🎉'
                                : 'Aucune notification disponible.',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.inter(
                              fontSize: 14.5,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 10, 16, 28),
                      itemCount: listeFiltree.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final notification = listeFiltree[index];
                        return CarteNotification(
                          notification: notification,
                          onAction: () => _executerActionNotification(notification),
                          onMarquerLue: () => _marquerCommeLue(notification.id),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
