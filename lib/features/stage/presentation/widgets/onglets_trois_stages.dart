import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class OngletsTroisStages extends StatelessWidget {
  const OngletsTroisStages({
    required this.indexActif,
    required this.onChangementOnglet,
    super.key,
  });

  final int indexActif;
  final ValueChanged<int> onChangementOnglet;

  @override
  Widget build(BuildContext context) {
    final modeSombre = Theme.of(context).brightness == Brightness.dark;
    return Row(
      children: [
        _buildOnglet(
          index: 0,
          titre: 'En cours',
          actif: indexActif == 0,
          modeSombre: modeSombre,
        ),
        _buildOnglet(
          index: 1,
          titre: 'Explorer',
          actif: indexActif == 1,
          modeSombre: modeSombre,
        ),
        _buildOnglet(
          index: 2,
          titre: 'Candidatures',
          actif: indexActif == 2,
          modeSombre: modeSombre,
        ),
      ],
    );
  }

  Widget _buildOnglet({
    required int index,
    required String titre,
    required bool actif,
    required bool modeSombre,
  }) {
    final couleurActive = modeSombre ? const Color(0xFF38BDF8) : const Color(0xFF1D61F2);
    final couleurInactive = modeSombre ? const Color(0xFF94A3B8) : const Color(0xFF64748B);

    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => onChangementOnglet(index),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Text(
                titre,
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 15,
                  fontWeight: actif ? FontWeight.w700 : FontWeight.w500,
                  color: actif ? couleurActive : couleurInactive,
                ),
              ),
            ),
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              height: 3,
              width: actif ? 42 : 0,
              decoration: BoxDecoration(
                color: actif ? couleurActive : Colors.transparent,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
