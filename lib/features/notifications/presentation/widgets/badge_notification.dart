import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class PastilleNonLue extends StatelessWidget {
  const PastilleNonLue({this.taille = 8, super.key});

  final double taille;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: taille,
      height: taille,
      decoration: const BoxDecoration(
        color: Color(0xFFFF7417),
        shape: BoxShape.circle,
      ),
    );
  }
}

class BadgeCompteurNotification extends StatelessWidget {
  const BadgeCompteurNotification({required this.compte, super.key});

  final int compte;

  @override
  Widget build(BuildContext context) {
    if (compte <= 0) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: const Color(0xFFFF7417),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        compte > 99 ? '99+' : '$compte',
        style: GoogleFonts.inter(
          color: Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class TagCategorieNotification extends StatelessWidget {
  const TagCategorieNotification({
    required this.label,
    required this.couleur,
    super.key,
  });

  final String label;
  final Color couleur;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: couleur.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: GoogleFonts.inter(
          color: couleur,
          fontSize: 11,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.2,
        ),
      ),
    );
  }
}
