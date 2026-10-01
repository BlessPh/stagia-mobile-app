import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

/// Composant de base Shimmer pour créer des blocs d'animation personnalisés
class ShimmerBloc extends StatelessWidget {
  const ShimmerBloc({
    required this.width,
    required this.height,
    this.borderRadius = 8,
    this.shape = BoxShape.rectangle,
    super.key,
  });

  const ShimmerBloc.cercle({
    required double diametre,
    super.key,
  })  : width = diametre,
        height = diametre,
        borderRadius = 0,
        shape = BoxShape.circle;

  final double? width;
  final double height;
  final double borderRadius;
  final BoxShape shape;

  @override
  Widget build(BuildContext context) {
    final modeSombre = Theme.of(context).brightness == Brightness.dark;
    final baseColor = modeSombre ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0);
    final highlightColor = modeSombre ? const Color(0xFF334155) : const Color(0xFFF8FAFC);

    return Shimmer.fromColors(
      baseColor: baseColor,
      highlightColor: highlightColor,
      period: const Duration(milliseconds: 1400),
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: baseColor,
          shape: shape,
          borderRadius: shape == BoxShape.circle ? null : BorderRadius.circular(borderRadius),
        ),
      ),
    );
  }
}

/// En-tête Shimmer reproduisant l'avatar circulaire, le nom et les 2 boutons d'action
class EnTeteAccueilSkeleton extends StatelessWidget implements PreferredSizeWidget {
  const EnTeteAccueilSkeleton({super.key});

  @override
  Size get preferredSize => const Size.fromHeight(74);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      automaticallyImplyLeading: false,
      toolbarHeight: preferredSize.height,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      title: Row(
        children: [
          // Avatar circulaire
          const ShimmerBloc.cercle(diametre: 46),
          const SizedBox(width: 12),
          // Texte : Bonjour + Nom
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: const [
                ShimmerBloc(width: 60, height: 12, borderRadius: 4),
                SizedBox(height: 6),
                ShimmerBloc(width: 130, height: 16, borderRadius: 6),
              ],
            ),
          ),
          // Bouton chat avec badge
          const ShimmerBloc(width: 38, height: 38, borderRadius: 12),
          const SizedBox(width: 8),
          // Bouton notification avec badge
          const ShimmerBloc(width: 38, height: 38, borderRadius: 12),
        ],
      ),
    );
  }
}

/// Skeleton du Carousel d'accueil avec indicateurs de points
class CarouselAccueilSkeleton extends StatelessWidget {
  const CarouselAccueilSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const ShimmerBloc(
          width: double.infinity,
          height: 195,
          borderRadius: 20,
        ),
        const SizedBox(height: 10),
        // Points de pagination
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            ShimmerBloc.cercle(diametre: 7),
            SizedBox(width: 5),
            ShimmerBloc.cercle(diametre: 7),
            SizedBox(width: 5),
            ShimmerBloc.cercle(diametre: 7),
          ],
        ),
      ],
    );
  }
}

/// Skeleton de la section "Tâches du jour" (en-tête + 2 cartes avec heure, séparateur, badge, titre)
class SectionTachesAccueilSkeleton extends StatelessWidget {
  const SectionTachesAccueilSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // En-tête : Titre + Action
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: const [
            ShimmerBloc(width: 130, height: 18, borderRadius: 6),
            ShimmerBloc(width: 60, height: 14, borderRadius: 6),
          ],
        ),
        const SizedBox(height: 12),
        _buildCarteTacheSkeleton(context),
        const SizedBox(height: 12),
        _buildCarteTacheSkeleton(context),
      ],
    );
  }

  Widget _buildCarteTacheSkeleton(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF1F5F9)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x06000000),
            blurRadius: 10,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Colonne heure début & fin
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              ShimmerBloc(width: 44, height: 16, borderRadius: 4),
              SizedBox(height: 4),
              ShimmerBloc(width: 36, height: 12, borderRadius: 4),
            ],
          ),
          // Séparateur vertical
          Container(
            width: 1,
            height: 38,
            margin: const EdgeInsets.symmetric(horizontal: 14),
            color: const Color(0xFFF1F5F9),
          ),
          // Colonne droite : Badge + Lieu + Titre
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: const [
                    ShimmerBloc(width: 55, height: 18, borderRadius: 6),
                    SizedBox(width: 8),
                    Expanded(child: ShimmerBloc(width: null, height: 12, borderRadius: 4)),
                    SizedBox(width: 8),
                    ShimmerBloc.cercle(diametre: 8),
                  ],
                ),
                const SizedBox(height: 8),
                const ShimmerBloc(width: double.infinity, height: 15, borderRadius: 4),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Skeleton de la section "Stage disponible" (en-tête + carte détaillée)
class SectionStageDisponibleSkeleton extends StatelessWidget {
  const SectionStageDisponibleSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // En-tête : Titre + Badge
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: const [
            ShimmerBloc(width: 140, height: 18, borderRadius: 6),
            ShimmerBloc(width: 120, height: 18, borderRadius: 12),
          ],
        ),
        const SizedBox(height: 12),
        // Carte du stage disponible
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFF1F5F9)),
            boxShadow: const [
              BoxShadow(
                color: Color(0x06000000),
                blurRadius: 10,
                offset: Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Ligne décorative supérieure
              const ShimmerBloc(width: double.infinity, height: 4.5, borderRadius: 4),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Titre
                    const ShimmerBloc(width: 220, height: 18, borderRadius: 6),
                    const SizedBox(height: 14),
                    // Date & Indemnité
                    Row(
                      children: const [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              ShimmerBloc(width: 40, height: 12, borderRadius: 4),
                              SizedBox(height: 6),
                              ShimmerBloc(width: 110, height: 14, borderRadius: 4),
                            ],
                          ),
                        ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              ShimmerBloc(width: 60, height: 12, borderRadius: 4),
                              SizedBox(height: 6),
                              ShimmerBloc(width: 90, height: 14, borderRadius: 4),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    // Badges (Inscriptions ouvertes + Hôpitaux)
                    Row(
                      children: const [
                        ShimmerBloc(width: 110, height: 22, borderRadius: 6),
                        SizedBox(width: 8),
                        ShimmerBloc(width: 130, height: 22, borderRadius: 6),
                      ],
                    ),
                    const SizedBox(height: 14),
                    // Spécialités avec petit icône
                    Row(
                      children: const [
                        ShimmerBloc.cercle(diametre: 16),
                        SizedBox(width: 8),
                        ShimmerBloc(width: 140, height: 14, borderRadius: 4),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // Bouton d'action complet "Voir les détails"
                    const ShimmerBloc(width: double.infinity, height: 46, borderRadius: 14),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Skeleton de la section "Stage en cours" (en-tête + carte de progression et informations du service)
class SectionStageEnCoursSkeleton extends StatelessWidget {
  const SectionStageEnCoursSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // En-tête : Titre + Badge
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: const [
            ShimmerBloc(width: 130, height: 18, borderRadius: 6),
            ShimmerBloc(width: 110, height: 18, borderRadius: 12),
          ],
        ),
        const SizedBox(height: 12),
        // Carte du stage en cours
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFF1F5F9)),
            boxShadow: const [
              BoxShadow(
                color: Color(0x06000000),
                blurRadius: 10,
                offset: Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Ligne décorative supérieure
              const ShimmerBloc(width: double.infinity, height: 4.5, borderRadius: 4),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Titre campagne
                    const ShimmerBloc(width: 230, height: 18, borderRadius: 6),
                    const SizedBox(height: 12),
                    // Établissement
                    Row(
                      children: const [
                        ShimmerBloc.cercle(diametre: 16),
                        SizedBox(width: 8),
                        ShimmerBloc(width: 180, height: 14, borderRadius: 4),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // Progression : Libellé & Jours
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: const [
                        ShimmerBloc(width: 110, height: 13, borderRadius: 4),
                        ShimmerBloc(width: 70, height: 13, borderRadius: 4),
                      ],
                    ),
                    const SizedBox(height: 8),
                    // Barre de progression
                    const ShimmerBloc(width: double.infinity, height: 7, borderRadius: 4),
                    const SizedBox(height: 6),
                    const ShimmerBloc(width: 120, height: 12, borderRadius: 4),
                    const SizedBox(height: 14),
                    // Services effectués
                    Row(
                      children: const [
                        ShimmerBloc.cercle(diametre: 16),
                        SizedBox(width: 8),
                        ShimmerBloc(width: 120, height: 14, borderRadius: 4),
                      ],
                    ),
                    const SizedBox(height: 10),
                    // Service actuel
                    Row(
                      children: const [
                        ShimmerBloc.cercle(diametre: 16),
                        SizedBox(width: 8),
                        ShimmerBloc(width: 160, height: 14, borderRadius: 4),
                      ],
                    ),
                    const SizedBox(height: 10),
                    // Jours restants service
                    Row(
                      children: const [
                        ShimmerBloc.cercle(diametre: 16),
                        SizedBox(width: 8),
                        ShimmerBloc(width: 170, height: 14, borderRadius: 4),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Divider(height: 1, color: Color(0xFFF1F5F9)),
                    const SizedBox(height: 12),
                    // Encadreur (avatar + infos)
                    Row(
                      children: const [
                        ShimmerBloc.cercle(diametre: 34),
                        SizedBox(width: 10),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ShimmerBloc(width: 60, height: 11, borderRadius: 4),
                            SizedBox(height: 4),
                            ShimmerBloc(width: 110, height: 13, borderRadius: 4),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Skeleton complet de la page d'accueil reproduisant exactement le modèle
class HomeSkeletonPage extends StatelessWidget {
  const HomeSkeletonPage({super.key});

  @override
  Widget build(BuildContext context) {
    final marge = MediaQuery.sizeOf(context).width < 360 ? 14.0 : 18.0;

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: EdgeInsets.fromLTRB(marge, 12, marge, 28),
      children: const [
        CarouselAccueilSkeleton(),
        SizedBox(height: 20),
        SectionTachesAccueilSkeleton(),
        SizedBox(height: 20),
        SectionStageDisponibleSkeleton(),
        SizedBox(height: 20),
        SectionStageEnCoursSkeleton(),
      ],
    );
  }
}
