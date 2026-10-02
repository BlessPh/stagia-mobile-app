import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/services/photo_profil_service.dart';
import '../../../../core/network/client_api_http.dart';
import '../../../../core/network/source_etudiant_distante.dart';
import '../../../messagerie/presentation/pages/messagerie_page.dart';
import '../../../notifications/presentation/pages/notifications_page.dart';

import 'dart:async';
import '../../../../core/services/sse_notifications_service.dart';

class EnTeteAccueil extends StatefulWidget implements PreferredSizeWidget {
  const EnTeteAccueil({required this.etudiant, super.key});

  final Map<String, dynamic> etudiant;

  @override
  Size get preferredSize => const Size.fromHeight(74);

  @override
  State<EnTeteAccueil> createState() => _EnTeteAccueilState();
}

class _EnTeteAccueilState extends State<EnTeteAccueil> {
  final _source = SourceEtudiantDistante(ClientApiHttp());
  Map<String, dynamic>? _counts;
  StreamSubscription? _sseSubscription;

  @override
  void initState() {
    super.initState();
    _chargerCounts();
    // Écoute temps réel des compteurs du flux SSE
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
    final nom = widget.etudiant['nom']?.toString().trim() ?? '';
    final prenom = widget.etudiant['prenom']?.toString().trim() ?? '';
    final modeSombre = Theme.of(context).brightness == Brightness.dark;

    final unreadMsgs =
        int.tryParse(_counts?['messages']?.toString() ?? '0') ?? 0;
    final unreadNotifs =
        int.tryParse(_counts?['notifications']?.toString() ?? '0') ?? 0;

    String nomComplet = [
      prenom,
      nom.toUpperCase(),
    ].where((e) => e.isNotEmpty).join(' ');
    if (nomComplet.isEmpty) {
      nomComplet = 'Étudiant';
    }

    return AppBar(
      automaticallyImplyLeading: false,
      toolbarHeight: widget.preferredSize.height,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      title: Row(
        children: [
          // Avatar étudiant
          AnimatedBuilder(
            animation: PhotoProfilService.instance,
            builder: (_, _) {
              final photo = PhotoProfilService.instance.cheminPhoto;
              final photoValide = photo != null && File(photo).existsSync();
              final avatarDistant =
                  widget.etudiant['avatar_url']?.toString().trim() ?? '';
              return CircleAvatar(
                radius: 23,
                backgroundColor: const Color(0xFFE2E8F0),
                backgroundImage: photoValide
                    ? FileImage(File(photo))
                    : avatarDistant.isNotEmpty
                    ? NetworkImage(avatarDistant)
                    : null,
                child: photoValide || avatarDistant.isNotEmpty
                    ? null
                    : const Icon(
                        Icons.person_rounded,
                        color: Color(0xFF64748B),
                        size: 26,
                      ),
              );
            },
          ),
          const SizedBox(width: 12),

          // Message Bonjour + Nom étudiant
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Text(
                      'Bonjour',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFF64748B),
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Text('👋', style: TextStyle(fontSize: 13)),
                  ],
                ),
                const SizedBox(height: 1),
                Text(
                  nomComplet,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: modeSombre ? Colors.white : const Color(0xFF0F172A),
                    letterSpacing: -0.2,
                  ),
                ),
              ],
            ),
          ),

          // Icône Messagerie / Chat avec badge réel
          Stack(
            clipBehavior: Clip.none,
            children: [
              IconButton(
                tooltip: 'Discussions',
                onPressed: () async {
                  await Navigator.of(context, rootNavigator: true).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const MessageriePage(),
                    ),
                  );
                  _chargerCounts();
                },
                icon: Icon(
                  CupertinoIcons.chat_bubble_2,
                  color: modeSombre ? Colors.white : const Color(0xFF0F172A),
                  size: 24,
                ),
                visualDensity: VisualDensity.compact,
              ),
              if (unreadMsgs > 0)
                Positioned(
                  top: 4,
                  right: 4,
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
          const SizedBox(width: 4),

          // Icône Notifications avec badge réel
          Stack(
            clipBehavior: Clip.none,
            children: [
              IconButton(
                tooltip: 'Notifications',
                onPressed: () async {
                  await Navigator.of(context, rootNavigator: true).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const NotificationsPage(),
                    ),
                  );
                  _chargerCounts();
                },
                icon: Icon(
                  CupertinoIcons.bell,
                  color: modeSombre ? Colors.white : const Color(0xFF0F172A),
                  size: 26,
                ),
                visualDensity: VisualDensity.compact,
              ),
              if (unreadNotifs > 0)
                Positioned(
                  top: 4,
                  right: 4,
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
          const SizedBox(width: 4),
        ],
      ),
    );
  }
}

class ErreurAccueil extends StatelessWidget {
  const ErreurAccueil({required this.onReessayer, super.key});

  final VoidCallback onReessayer;

  @override
  Widget build(BuildContext context) => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(
          Icons.cloud_off_outlined,
          size: 48,
          color: Color(0xFFFF7417),
        ),
        const SizedBox(height: 12),
        const Text('Impossible de charger les données.'),
        TextButton(onPressed: onReessayer, child: const Text('Réessayer')),
      ],
    ),
  );
}

Map<String, dynamic> mapApi(Object? valeur) =>
    valeur is Map ? Map<String, dynamic>.from(valeur) : <String, dynamic>{};

List<Map<String, dynamic>> listeApi(Object? valeur) => valeur is List
    ? valeur.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList()
    : <Map<String, dynamic>>[];

int entierApi(Object? valeur) => valeur is num
    ? valeur.toInt()
    : int.tryParse(valeur?.toString() ?? '') ?? 0;

class IndicateurStatistiqueAccueil extends StatelessWidget {
  const IndicateurStatistiqueAccueil({
    required this.cheminIcone,
    required this.valeur,
    required this.libelle,
    super.key,
  });

  final String cheminIcone;
  final String valeur;
  final String libelle;

  @override
  Widget build(BuildContext context) => Container(
    constraints: const BoxConstraints(minHeight: 110),
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 14),
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.surface,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(
        color: const Color(0xFFFF7417).withValues(alpha: 0.5),
        width: 1.2,
      ),
      boxShadow: const [
        BoxShadow(
          color: Color(0x0A000000),
          blurRadius: 10,
          offset: Offset(0, 4),
        ),
      ],
    ),
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Image.asset(
          cheminIcone,
          width: 32,
          height: 32,
          fit: BoxFit.contain,
          errorBuilder: (_, _, _) => const SizedBox(
            width: 32,
            height: 32,
            child: Icon(Icons.analytics_outlined, color: Color(0xFFFF7417)),
          ),
        ),
        const SizedBox(height: 7),
        Text(
          valeur,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: valeur.length > 4 ? 14 : 19,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          libelle,
          maxLines: 2,
          textAlign: TextAlign.center,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: Color(0xFF718096),
            fontSize: 11.5,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    ),
  );
}
