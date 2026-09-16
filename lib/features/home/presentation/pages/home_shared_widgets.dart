import 'dart:io';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:skeletonizer/skeletonizer.dart';
import '../../../../core/services/photo_profil_service.dart';
import '../../../notifications/presentation/pages/notifications_page.dart';
import '../../../messagerie/presentation/messages_page.dart';

class EnTeteAccueil extends StatelessWidget implements PreferredSizeWidget {
  const EnTeteAccueil({
    required this.etudiant,
    this.superviseur,
    this.chargement = false,
    super.key,
  });

  final Map<String, dynamic> etudiant;
  final Map<String, String>? superviseur;
  final bool chargement;

  @override
  Size get preferredSize => const Size.fromHeight(76);

  @override
  Widget build(BuildContext context) {
    final nom = etudiant['nom']?.toString() ?? '';
    final prenom = etudiant['prenom']?.toString() ?? '';
    final modeSombre = Theme.of(context).brightness == Brightness.dark;
    final nomComplet = [
      prenom,
      nom,
    ].where((element) => element.isNotEmpty).join(' ');

    if (chargement) {
      return AppBar(
        automaticallyImplyLeading: false,
        toolbarHeight: preferredSize.height,
        backgroundColor: Theme.of(context).colorScheme.surface,
        surfaceTintColor: Colors.transparent,
        title: Skeletonizer.zone(
          enabled: true,
          effect: _effetChargement(context),
          child: const Row(
            children: [
              Bone.circle(size: 52),
              SizedBox(width: 12),
              Expanded(child: Bone.text(width: 145, fontSize: 18)),
              Bone.iconButton(size: 40),
              SizedBox(width: 4),
              Bone.iconButton(size: 40),
            ],
          ),
        ),
      );
    }

    return AppBar(
      automaticallyImplyLeading: false,
      toolbarHeight: preferredSize.height,
      backgroundColor: Theme.of(context).colorScheme.surface,
      surfaceTintColor: Colors.transparent,
      title: Row(
        children: [
          AnimatedBuilder(
            animation: PhotoProfilService.instance,
            builder: (_, _) {
              final photo = PhotoProfilService.instance.cheminPhoto;
              final photoValide = photo != null && File(photo).existsSync();
              return CircleAvatar(
                radius: 26,
                backgroundColor: modeSombre
                    ? Colors.black
                    : const Color(0xFFE5E7EB),
                backgroundImage: photoValide ? FileImage(File(photo)) : null,
                child: !photoValide
                    ? const FaIcon(
                        FontAwesomeIcons.user,
                        color: Color(0xFF9CA3AF),
                        size: 24,
                      )
                    : null,
              );
            },
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              nomComplet.isEmpty ? 'Étudiant' : nomComplet,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
            ),
          ),
          IconButton(
            tooltip: 'Messages',
            onPressed: () => Navigator.of(context, rootNavigator: true).push(
              MaterialPageRoute<void>(
                builder: (_) => MessagesPage(
                  compte:
                      (etudiant['uuid'] ??
                              etudiant['stagia_code'] ??
                              etudiant['matricule'] ??
                              etudiant['email'] ??
                              'local')
                          .toString(),
                  superviseurId: superviseur?['id'],
                  superviseurNom: superviseur?['nom'],
                ),
              ),
            ),
            icon: FaIcon(
              FontAwesomeIcons.message,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            iconSize: 20,
          ),
          IconButton(
            tooltip: 'Notifications',
            onPressed: () => Navigator.of(context, rootNavigator: true).push(
              MaterialPageRoute<void>(
                builder: (_) => const NotificationsPage(),
              ),
            ),
            icon: FaIcon(
              FontAwesomeIcons.bell,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            iconSize: 20,
          ),
        ],
      ),
    );
  }
}

class ChargementAccueil extends StatelessWidget {
  const ChargementAccueil({super.key});

  @override
  Widget build(BuildContext context) {
    final marge = MediaQuery.sizeOf(context).width < 360 ? 14.0 : 18.0;
    return Skeletonizer.zone(
      enabled: true,
      effect: _effetChargement(context),
      child: ListView(
        physics: const NeverScrollableScrollPhysics(),
        padding: EdgeInsets.fromLTRB(marge, 16, marge, 28),
        children: const [
          Bone(height: 170, width: double.infinity, uniRadius: 22),
          SizedBox(height: 22),
          Bone.text(width: 210, fontSize: 20),
          SizedBox(height: 14),
          _LigneIndicateursChargement(),
          SizedBox(height: 20),
          Bone(height: 92, width: double.infinity, uniRadius: 20),
          SizedBox(height: 12),
          Bone(height: 92, width: double.infinity, uniRadius: 20),
          SizedBox(height: 12),
          Bone(height: 92, width: double.infinity, uniRadius: 20),
        ],
      ),
    );
  }
}

class ChargementPremiereConnexion extends StatelessWidget {
  const ChargementPremiereConnexion({super.key});

  @override
  Widget build(BuildContext context) {
    final marge = MediaQuery.sizeOf(context).width < 360 ? 14.0 : 18.0;
    return Skeletonizer.zone(
      enabled: true,
      effect: _effetChargement(context),
      child: ListView(
        physics: const NeverScrollableScrollPhysics(),
        padding: EdgeInsets.fromLTRB(marge, 16, marge, 28),
        children: const [
          Bone(height: 170, width: double.infinity, uniRadius: 22),
          SizedBox(height: 22),
          Bone.text(width: 220, fontSize: 20),
          SizedBox(height: 14),
          Bone(height: 330, width: double.infinity, uniRadius: 22),
        ],
      ),
    );
  }
}

ShimmerEffect _effetChargement(BuildContext context) {
  final sombre = Theme.of(context).brightness == Brightness.dark;
  return ShimmerEffect(
    baseColor: sombre ? const Color(0xFF303030) : const Color(0xFFD7DCE2),
    highlightColor: sombre ? const Color(0xFF5A5A5A) : const Color(0xFFF7F8FA),
    duration: const Duration(milliseconds: 900),
  );
}

class _LigneIndicateursChargement extends StatelessWidget {
  const _LigneIndicateursChargement();

  @override
  Widget build(BuildContext context) => const Row(
    children: [
      Expanded(child: Bone(height: 134, uniRadius: 20)),
      SizedBox(width: 10),
      Expanded(child: Bone(height: 134, uniRadius: 20)),
      SizedBox(width: 10),
      Expanded(child: Bone(height: 134, uniRadius: 20)),
    ],
  );
}

class ErreurAccueil extends StatelessWidget {
  const ErreurAccueil({required this.onReessayer, super.key});

  final VoidCallback onReessayer;

  @override
  Widget build(BuildContext context) => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const FaIcon(
          FontAwesomeIcons.cloudArrowDown,
          color: Color(0xFF718096),
          size: 40,
        ),
        const SizedBox(height: 12),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 28),
          child: Text(
            'Connexion impossible. Vérifiez votre connexion Internet puis réessayez.',
            textAlign: TextAlign.center,
          ),
        ),
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
