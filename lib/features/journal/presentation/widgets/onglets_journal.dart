import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class OngletsJournal extends StatelessWidget {
  const OngletsJournal({
    required this.indexActif,
    required this.onChangementOnglet,
    super.key,
  });

  final int indexActif;
  final ValueChanged<int> onChangementOnglet;

  @override
  Widget build(BuildContext context) {
    final modeSombre = Theme.of(context).brightness == Brightness.dark;
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildOnglet(index: 0, titre: 'Mes tâches', actif: indexActif == 0, modeSombre: modeSombre),
          const SizedBox(width: 6),
          _buildOnglet(index: 1, titre: 'Présences', actif: indexActif == 1, modeSombre: modeSombre),
          const SizedBox(width: 6),
          _buildOnglet(index: 2, titre: 'Evaluations', actif: indexActif == 2, modeSombre: modeSombre),
          const SizedBox(width: 6),
          _buildOnglet(index: 3, titre: 'Journal', actif: indexActif == 3, modeSombre: modeSombre),
        ],
      ),
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

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => onChangementOnglet(index),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 11),
              child: Text(
                titre,
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: actif ? FontWeight.w700 : FontWeight.w500,
                  color: actif ? couleurActive : couleurInactive,
                ),
              ),
            ),
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              height: 3,
              width: actif ? 38 : 0,
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
