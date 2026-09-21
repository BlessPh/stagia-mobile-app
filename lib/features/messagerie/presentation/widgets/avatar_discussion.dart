import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AvatarDiscussion extends StatelessWidget {
  const AvatarDiscussion({
    required this.nom,
    this.estEnLigne = false,
    this.estGroupe = false,
    this.estDiffusion = false,
    this.rayon = 24,
    super.key,
  });

  final String nom;
  final bool estEnLigne;
  final bool estGroupe;
  final bool estDiffusion;
  final double rayon;

  String get _initiales {
    final mots = nom.trim().split(RegExp(r'\s+'));
    if (mots.isEmpty) return 'ST';
    if (mots.length == 1) {
      return mots[0].substring(0, mots[0].length >= 2 ? 2 : 1).toUpperCase();
    }
    return (mots[0][0] + mots[1][0]).toUpperCase();
  }

  Color get _couleurFond {
    if (estDiffusion) return const Color(0xFFF59E0B);
    if (estGroupe) return const Color(0xFF8B5CF6);
    final hash = nom.codeUnits.fold(0, (prev, elem) => prev + elem);
    const palettes = [
      Color(0xFF1D61F2),
      Color(0xFF10B981),
      Color(0xFFE85D00),
      Color(0xFF0EA5E9),
      Color(0xFF6366F1),
    ];
    return palettes[hash % palettes.length];
  }

  @override
  Widget build(BuildContext context) {
    final diametre = rayon * 2;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: diametre,
          height: diametre,
          decoration: BoxDecoration(
            color: _couleurFond.withValues(alpha: 0.15),
            shape: BoxShape.circle,
            border: Border.all(
              color: _couleurFond.withValues(alpha: 0.3),
              width: 1.5,
            ),
          ),
          child: Center(
            child: estDiffusion
                ? Icon(
                    Icons.campaign_rounded,
                    color: _couleurFond,
                    size: rayon * 1.1,
                  )
                : estGroupe
                ? Icon(
                    Icons.group_rounded,
                    color: _couleurFond,
                    size: rayon * 1.1,
                  )
                : Text(
                    _initiales,
                    style: GoogleFonts.inter(
                      fontSize: rayon * 0.72,
                      fontWeight: FontWeight.w800,
                      color: _couleurFond,
                    ),
                  ),
          ),
        ),
        if (estEnLigne)
          Positioned(
            right: 0,
            bottom: 0,
            child: Container(
              width: rayon * 0.55,
              height: rayon * 0.55,
              decoration: BoxDecoration(
                color: const Color(0xFF10B981),
                shape: BoxShape.circle,
                border: Border.all(
                  color: Theme.of(context).scaffoldBackgroundColor,
                  width: 2,
                ),
              ),
            ),
          ),
      ],
    );
  }
}
