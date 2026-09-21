import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

enum OptionPieceJointe {
  document,
  camera,
  galerie,
  ficheStage,
}

class FeuillePiecesJointes extends StatelessWidget {
  const FeuillePiecesJointes({
    required this.onOptionChoisie,
    super.key,
  });

  final ValueChanged<OptionPieceJointe> onOptionChoisie;

  @override
  Widget build(BuildContext context) {
    final modeSombre = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
      decoration: BoxDecoration(
        color: modeSombre ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Barre de poignée
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFCBD5E1),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 18),

          Text(
            'Partager un fichier ou document',
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: modeSombre ? Colors.white : const Color(0xFF0F172A),
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 18),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _ElementOption(
                icone: Icons.description_rounded,
                label: 'Document',
                couleur: const Color(0xFF1D61F2),
                onTap: () {
                  Navigator.pop(context);
                  onOptionChoisie(OptionPieceJointe.document);
                },
              ),
              _ElementOption(
                icone: Icons.camera_alt_rounded,
                label: 'Caméra',
                couleur: const Color(0xFF10B981),
                onTap: () {
                  Navigator.pop(context);
                  onOptionChoisie(OptionPieceJointe.camera);
                },
              ),
              _ElementOption(
                icone: Icons.photo_library_rounded,
                label: 'Galerie',
                couleur: const Color(0xFF8B5CF6),
                onTap: () {
                  Navigator.pop(context);
                  onOptionChoisie(OptionPieceJointe.galerie);
                },
              ),
              _ElementOption(
                icone: Icons.assignment_turned_in_rounded,
                label: 'Fiche Stage',
                couleur: const Color(0xFFFF7417),
                onTap: () {
                  Navigator.pop(context);
                  onOptionChoisie(OptionPieceJointe.ficheStage);
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ElementOption extends StatelessWidget {
  const _ElementOption({
    required this.icone,
    required this.label,
    required this.couleur,
    required this.onTap,
  });

  final IconData icone;
  final String label;
  final Color couleur;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final modeSombre = Theme.of(context).brightness == Brightness.dark;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        child: Column(
          children: [
            Container(
              width: 54,
              height: 54,
              decoration: BoxDecoration(
                color: couleur.withValues(alpha: 0.12),
                shape: BoxShape.circle,
                border: Border.all(
                  color: couleur.withValues(alpha: 0.25),
                  width: 1.5,
                ),
              ),
              child: Icon(icone, color: couleur, size: 26),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: modeSombre
                    ? const Color(0xFFE2E8F0)
                    : const Color(0xFF334155),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
