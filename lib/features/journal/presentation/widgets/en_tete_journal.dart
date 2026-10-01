import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/network/client_api_http.dart';
import '../../../../core/network/source_etudiant_distante.dart';

import 'dart:async';
import '../../../../core/services/sse_notifications_service.dart';

class EnTeteJournal extends StatefulWidget implements PreferredSizeWidget {
  const EnTeteJournal({
    required this.onOuvrirChat,
    required this.onOuvrirNotifications,
    required this.onOuvrirTaches,
    this.nombreTachesAujourdhui = 0,
    super.key,
  });

  final VoidCallback onOuvrirChat;
  final VoidCallback onOuvrirNotifications;
  final VoidCallback onOuvrirTaches;
  final int nombreTachesAujourdhui;

  @override
  Size get preferredSize => const Size.fromHeight(60);

  @override
  State<EnTeteJournal> createState() => _EnTeteJournalState();
}

class _EnTeteJournalState extends State<EnTeteJournal> {
  final _source = SourceEtudiantDistante(ClientApiHttp());
  Map<String, dynamic>? _counts;
  StreamSubscription? _sseSubscription;

  @override
  void initState() {
    super.initState();
    _chargerCounts();
    // Écoute SSE en temps réel des compteurs
    _sseSubscription = SseNotificationsService.instance.fluxCompteurs.listen((
      counts,
    ) {
      if (mounted) {
        setState(() => _counts = counts);
      }
    });
  }

  @override
  void dispose() {
    _sseSubscription?.cancel();
    super.dispose();
  }

  Future<void> _chargerCounts() async {
    try {
      final res = await _source.notificationCounts();
      if (mounted) {
        setState(() => _counts = res);
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final unreadMsgs =
        int.tryParse(_counts?['messages']?.toString() ?? '0') ?? 0;
    final unreadNotifs =
        int.tryParse(_counts?['notifications']?.toString() ?? '0') ?? 0;

    return AppBar(
      automaticallyImplyLeading: false,
      backgroundColor: const Color(0xFFF8FAFC),
      elevation: 0,
      surfaceTintColor: Colors.transparent,
      title: Text(
        'Mon journal',
        style: GoogleFonts.inter(
          fontSize: 22,
          fontWeight: FontWeight.w800,
          color: const Color(0xFF0F172A),
          letterSpacing: -0.3,
        ),
      ),
      actions: [
        // Bouton Chat avec badge réel
        Stack(
          clipBehavior: Clip.none,
          children: [
            IconButton(
              tooltip: 'Messages',
              onPressed: () {
                widget.onOuvrirChat();
                _chargerCounts();
              },
              icon: const Icon(
                CupertinoIcons.chat_bubble_2,
                color: Color(0xFF0F172A),
                size: 24,
              ),
            ),
            if (unreadMsgs > 0)
              Positioned(
                top: 8,
                right: 6,
                child: Container(
                  padding: const EdgeInsets.all(3),
                  decoration: const BoxDecoration(
                    color: Color(0xFFEF4444),
                    shape: BoxShape.circle,
                  ),
                  constraints: const BoxConstraints(
                    minWidth: 16,
                    minHeight: 16,
                  ),
                  child: Text(
                    '$unreadMsgs',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 9.5,
                      fontWeight: FontWeight.w800,
                      height: 1,
                    ),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(width: 2),

        // Bouton Notifications avec badge réel
        Stack(
          clipBehavior: Clip.none,
          children: [
            IconButton(
              tooltip: 'Notifications',
              onPressed: () {
                widget.onOuvrirNotifications();
                _chargerCounts();
              },
              icon: const Icon(
                CupertinoIcons.bell,
                color: Color(0xFF0F172A),
                size: 25,
              ),
            ),
            if (unreadNotifs > 0)
              Positioned(
                top: 8,
                right: 6,
                child: Container(
                  padding: const EdgeInsets.all(3),
                  decoration: const BoxDecoration(
                    color: Color(0xFFEF4444),
                    shape: BoxShape.circle,
                  ),
                  constraints: const BoxConstraints(
                    minWidth: 16,
                    minHeight: 16,
                  ),
                  child: Text(
                    '$unreadNotifs',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 9.5,
                      fontWeight: FontWeight.w800,
                      height: 1,
                    ),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(width: 2),

        // Bouton Tâches du jour (Calendrier avec compteur de tâches)
        Stack(
          clipBehavior: Clip.none,
          children: [
            IconButton(
              tooltip: 'Tâches du jour',
              onPressed: widget.onOuvrirTaches,
              icon: const Icon(
                CupertinoIcons.calendar,
                color: Color(0xFF0F172A),
                size: 24,
              ),
            ),
            if (widget.nombreTachesAujourdhui > 0)
              Positioned(
                top: 8,
                right: 6,
                child: Container(
                  padding: const EdgeInsets.all(3),
                  decoration: const BoxDecoration(
                    color: Color(0xFF1D61F2),
                    shape: BoxShape.circle,
                  ),
                  constraints: const BoxConstraints(
                    minWidth: 16,
                    minHeight: 16,
                  ),
                  child: Text(
                    '${widget.nombreTachesAujourdhui}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 9.5,
                      fontWeight: FontWeight.w800,
                      height: 1,
                    ),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(width: 8),
      ],
    );
  }
}
