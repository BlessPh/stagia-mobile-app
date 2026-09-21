import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class SelecteurCalendrierSemaine extends StatelessWidget {
  const SelecteurCalendrierSemaine({
    required this.dateSelectionnee,
    required this.onDateSelectionnee,
    this.datesAvecIndicateurs = const {},
    this.pointsCouleursParDate = const {},
    this.onPrecedent,
    this.onSuivant,
    this.titreMois = 'Janvier 2026',
    super.key,
  });

  final DateTime dateSelectionnee;
  final ValueChanged<DateTime> onDateSelectionnee;
  final Set<int> datesAvecIndicateurs;
  final Map<int, Color> pointsCouleursParDate;
  final VoidCallback? onPrecedent;
  final VoidCallback? onSuivant;
  final String titreMois;

  @override
  Widget build(BuildContext context) {
    // Calcul de la semaine contenant la date sélectionnée (ou fixe 12 au 18 janvier comme sur la maquette)
    final debutSemaine = dateSelectionnee.subtract(Duration(days: dateSelectionnee.weekday - 1));
    final joursSemaine = List.generate(7, (index) => debutSemaine.add(Duration(days: index)));

    const nomsJours = ['L', 'M', 'M', 'J', 'V', 'S', 'D'];

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x05000000),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      child: Column(
        children: [
          // En-tête mois + flèches
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                titreMois,
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF0F172A),
                ),
              ),
              Row(
                children: [
                  GestureDetector(
                    onTap: onPrecedent,
                    child: Container(
                      width: 28,
                      height: 28,
                      decoration: const BoxDecoration(
                        color: Color(0xFFE0F2FE),
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: const Icon(
                        Icons.chevron_left_rounded,
                        size: 20,
                        color: Color(0xFF0284C7),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: onSuivant,
                    child: Container(
                      width: 28,
                      height: 28,
                      decoration: const BoxDecoration(
                        color: Color(0xFFE0F2FE),
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: const Icon(
                        Icons.chevron_right_rounded,
                        size: 20,
                        color: Color(0xFF0284C7),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 14),

          // Ligne des lettres des jours
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(7, (index) {
              return Expanded(
                child: Text(
                  nomsJours[index],
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF94A3B8),
                  ),
                ),
              );
            }),
          ),

          const SizedBox(height: 12),

          // Ligne des chiffres des jours
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: joursSemaine.map((date) {
              final estSelectionne = date.year == dateSelectionnee.year &&
                  date.month == dateSelectionnee.month &&
                  date.day == dateSelectionnee.day;
              final pointCouleur = pointsCouleursParDate[date.day];
              final aIndicateur = datesAvecIndicateurs.contains(date.day) || pointCouleur != null;

              return Expanded(
                child: GestureDetector(
                  onTap: () => onDateSelectionnee(date),
                  behavior: HitTestBehavior.opaque,
                  child: Column(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: estSelectionne ? const Color(0xFF1D61F2) : Colors.transparent,
                          shape: BoxShape.circle,
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          '${date.day}',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: estSelectionne ? FontWeight.w800 : FontWeight.w600,
                            color: estSelectionne ? Colors.white : const Color(0xFF0F172A),
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        width: 4.5,
                        height: 4.5,
                        decoration: BoxDecoration(
                          color: estSelectionne
                              ? (pointCouleur ?? Colors.white)
                              : (aIndicateur ? (pointCouleur ?? const Color(0xFFF97316)) : Colors.transparent),
                          shape: BoxShape.circle,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
