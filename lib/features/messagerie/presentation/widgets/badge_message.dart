import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class BadgeMessageCompteur extends StatelessWidget {
  const BadgeMessageCompteur({
    required this.compte,
    this.couleur = const Color(0xFFFF7417),
    super.key,
  });

  final int compte;
  final Color couleur;

  @override
  Widget build(BuildContext context) {
    if (compte <= 0) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      constraints: const BoxConstraints(minWidth: 20, minHeight: 20),
      decoration: BoxDecoration(
        color: couleur,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: couleur.withValues(alpha: 0.35),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Center(
        child: Text(
          compte > 99 ? '99+' : '$compte',
          textAlign: TextAlign.center,
          style: GoogleFonts.inter(
            color: Colors.white,
            fontSize: 10.5,
            fontWeight: FontWeight.w800,
            height: 1,
          ),
        ),
      ),
    );
  }
}
