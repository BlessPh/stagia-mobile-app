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
    return Row(
      children: [
        _buildOnglet(
          index: 0,
          titre: 'En cours',
          actif: indexActif == 0,
        ),
        _buildOnglet(
          index: 1,
          titre: 'Explorer',
          actif: indexActif == 1,
        ),
        _buildOnglet(
          index: 2,
          titre: 'Candidatures',
          actif: indexActif == 2,
        ),
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
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Text(
                titre,
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 15,
                  fontWeight: actif ? FontWeight.w700 : FontWeight.w500,
                  color: actif ? const Color(0xFF1D61F2) : const Color(0xFF64748B),
                ),
              ),
            ),
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              height: 3,
              width: actif ? 42 : 0,
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
