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
    return Row(
      children: [
        _buildOnglet(index: 0, titre: 'Mes tâches', actif: indexActif == 0),
        _buildOnglet(index: 1, titre: 'Présences', actif: indexActif == 1),
        _buildOnglet(index: 2, titre: 'Evaluations', actif: indexActif == 2),
        _buildOnglet(index: 3, titre: 'Journal', actif: indexActif == 3),
      ],
    );
  }

  Widget _buildOnglet({
    required int index,
    required String titre,
    required bool actif,
  }) {
    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => onChangementOnglet(index),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 11),
              child: Text(
                titre,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: actif ? FontWeight.w700 : FontWeight.w500,
                  color: actif ? const Color(0xFF1D61F2) : const Color(0xFF64748B),
                ),
              ),
            ),
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              height: 3,
              width: actif ? 38 : 0,
              decoration: BoxDecoration(
                color: actif ? const Color(0xFF1D61F2) : Colors.transparent,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
