import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class EnTeteJournal extends StatelessWidget implements PreferredSizeWidget {
  const EnTeteJournal({
    required this.onOuvrirChat,
    required this.onOuvrirNotifications,
    required this.onOuvrirTaches,
    this.nombreTachesAujourdhui = 5,
    super.key,
  });

  final VoidCallback onOuvrirChat;
  final VoidCallback onOuvrirNotifications;
  final VoidCallback onOuvrirTaches;
  final int nombreTachesAujourdhui;

  @override
  Size get preferredSize => const Size.fromHeight(60);

  @override
  Widget build(BuildContext context) {
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
        // Bouton Chat avec badge 3
        Stack(
          clipBehavior: Clip.none,
          children: [
            IconButton(
              tooltip: 'Messages',
              onPressed: onOuvrirChat,
              icon: const Icon(
                CupertinoIcons.chat_bubble_2,
                color: Color(0xFF0F172A),
                size: 24,
              ),
            ),
            Positioned(
              top: 8,
              right: 6,
              child: Container(
                padding: const EdgeInsets.all(3),
                decoration: const BoxDecoration(
                  color: Color(0xFFEF4444),
                  shape: BoxShape.circle,
                ),
                constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                child: const Text(
                  '3',
                  textAlign: TextAlign.center,
                  style: TextStyle(
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

        // Bouton Notifications avec badge 5
        Stack(
          clipBehavior: Clip.none,
          children: [
            IconButton(
              tooltip: 'Notifications',
              onPressed: onOuvrirNotifications,
              icon: const Icon(
                CupertinoIcons.bell,
                color: Color(0xFF0F172A),
                size: 25,
              ),
            ),
            Positioned(
              top: 8,
              right: 6,
              child: Container(
                padding: const EdgeInsets.all(3),
                decoration: const BoxDecoration(
                  color: Color(0xFFEF4444),
                  shape: BoxShape.circle,
                ),
                constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                child: const Text(
                  '5',
                  textAlign: TextAlign.center,
                  style: TextStyle(
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
              onPressed: onOuvrirTaches,
              icon: const Icon(
                CupertinoIcons.calendar,
                color: Color(0xFF0F172A),
                size: 24,
              ),
            ),
            if (nombreTachesAujourdhui > 0)
              Positioned(
                top: 8,
                right: 6,
                child: Container(
                  padding: const EdgeInsets.all(3),
                  decoration: const BoxDecoration(
                    color: Color(0xFF1D61F2),
                    shape: BoxShape.circle,
                  ),
                  constraints:
                      const BoxConstraints(minWidth: 16, minHeight: 16),
                  child: Text(
                    '$nombreTachesAujourdhui',
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
