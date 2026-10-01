import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/widgets/contenu_adaptatif.dart';
import '../../../../core/services/sse_notifications_service.dart';
import '../../../messagerie/domain/entities/discussion.dart';
import '../../../messagerie/presentation/pages/chat_page.dart';
import '../../../stage/presentation/pages/mes_stages_page.dart';
import '../../../stage/presentation/pages/mon_stage_page.dart';
import '../../../../core/network/client_api_http.dart';
import '../../../../core/network/source_etudiant_distante.dart';
import '../../domain/entities/notification_item.dart';
import '../widgets/carte_notification.dart';
import '../widgets/filtres_notification.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  final _source = SourceEtudiantDistante(ClientApiHttp());
  List<NotificationItem> _notifications = [];
  FiltreNotification _filtreActuel = FiltreNotification.toutes;
  bool _chargement = true;
  StreamSubscription? _sseSubscription;

  @override
  void initState() {
    super.initState();
    _chargerNotifications();

    // Écoute SSE des nouvelles notifications en direct
    _sseSubscription = SseNotificationsService.instance.fluxNotifications
        .listen((notifMap) {
          final item = NotificationItem.fromJson(notifMap);
          if (mounted && !_notifications.any((n) => n.id == item.id)) {
            setState(() {
              _notifications.insert(0, item);
            });
          }
        });
  }

  @override
  void dispose() {
    _sseSubscription?.cancel();
    super.dispose();
  }

  Future<void> _chargerNotifications() async {
    setState(() => _chargement = true);
    try {
      final res = await _source.notifications();
      final items =
          (res['items'] as List?)
              ?.whereType<Map>()
              .map(
                (m) => NotificationItem.fromJson(Map<String, dynamic>.from(m)),
              )
              .toList() ??
          <NotificationItem>[];
      if (mounted) {
        setState(() {
          _notifications = items;
          _chargement = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _chargement = false);
      }
    }
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
    _source.marquerNotificationLue(id);
  }

  void _toutMarquerCommeLu() {
    setState(() {
      for (final n in _notifications) {
        if (!n.lue) {
          n.lue = true;
          _source.marquerNotificationLue(n.id);
        }
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
          MaterialPageRoute<void>(builder: (_) => const MonStagePage()),
        );
      case TypeCibleNotification.detailCampagne:
        Navigator.of(context).push<void>(
          MaterialPageRoute<void>(builder: (_) => const MesStagesPage()),
        );
      case TypeCibleNotification.discussionChat:
        final idDiscussion =
            notification.cible.identifiant ?? '01JQ0CONVERSATION000000001';
        final discussion = Discussion(
          id: idDiscussion,
          nom: notification.cible.titre ?? 'Discussion',
          roleOuService: 'Encadrement',
          dernierMessage: notification.sujet,
          date: notification.date,
          categorie: CategorieDiscussion.encadreurs,
        );

        Navigator.of(context).push<void>(
          MaterialPageRoute<void>(
            builder: (_) => ChatPage(discussion: discussion),
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
              child: _chargement
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFFFF7417),
                      ),
                    )
                  : RefreshIndicator(
                      color: const Color(0xFFFF7417),
                      onRefresh: _chargerNotifications,
                      child: listeFiltree.isEmpty
                          ? ListView(
                              children: [
                                const SizedBox(height: 120),
                                Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Container(
                                        width: 68,
                                        height: 68,
                                        decoration: BoxDecoration(
                                          color: const Color(
                                            0xFFFF7417,
                                          ).withValues(alpha: 0.1),
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
                                        _filtreActuel ==
                                                FiltreNotification.nonLues
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
                                ),
                              ],
                            )
                          : ListView.separated(
                              padding: const EdgeInsets.fromLTRB(
                                16,
                                10,
                                16,
                                28,
                              ),
                              itemCount: listeFiltree.length,
                              separatorBuilder: (_, _) =>
                                  const SizedBox(height: 12),
                              itemBuilder: (context, index) {
                                final notification = listeFiltree[index];
                                return CarteNotification(
                                  notification: notification,
                                  onAction: () =>
                                      _executerActionNotification(notification),
                                  onMarquerLue: () =>
                                      _marquerCommeLue(notification.id),
                                );
                              },
                            ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
