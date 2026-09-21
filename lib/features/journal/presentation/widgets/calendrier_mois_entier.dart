import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class CalendrierMoisEntier extends StatelessWidget {
  const CalendrierMoisEntier({
    required this.dateSelectionnee,
    required this.onDateSelectionnee,
    this.pointsCouleursParDate = const {},
    this.onMoisPrecedent,
    this.onMoisSuivant,
    this.moisAffiche,
    super.key,
  });

  final DateTime dateSelectionnee;
  final ValueChanged<DateTime> onDateSelectionnee;
  final Map<int, Color> pointsCouleursParDate;
  final VoidCallback? onMoisPrecedent;
  final VoidCallback? onMoisSuivant;
  final DateTime? moisAffiche;

  @override
  Widget build(BuildContext context) {
    final moisCourant = moisAffiche ?? DateTime(dateSelectionnee.year, dateSelectionnee.month);
    final premierJourMois = DateTime(moisCourant.year, moisCourant.month, 1);
    final nombreJoursMois = DateUtils.getDaysInMonth(moisCourant.year, moisCourant.month);
    
    // Décalage pour commencer le lundi (1 = lundi, 7 = dimanche)
    final premierJourSemaine = premierJourMois.weekday; // 1..7
    final casesVidesAvant = premierJourSemaine - 1;

    const nomsMois = [
      'Janvier', 'Février', 'Mars', 'Avril', 'Mai', 'Juin',
      'Juillet', 'Août', 'Septembre', 'Octobre', 'Novembre', 'Décembre'
    ];
    final titreMois = '${nomsMois[moisCourant.month - 1]} ${moisCourant.year}';
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
          // En-tête mois + flèches de navigation
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
                    onTap: onMoisPrecedent,
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
                    onTap: onMoisSuivant,
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

          // Ligne des en-têtes de colonnes (L M M J V S D)
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

          const SizedBox(height: 10),

          // Grille du mois
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: casesVidesAvant + nombreJoursMois,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              mainAxisSpacing: 6,
              crossAxisSpacing: 2,
              childAspectRatio: 0.95,
            ),
            itemBuilder: (context, index) {
              if (index < casesVidesAvant) {
                return const SizedBox.shrink();
              }
              final jour = index - casesVidesAvant + 1;
              final date = DateTime(moisCourant.year, moisCourant.month, jour);
              final estSelectionne = date.year == dateSelectionnee.year &&
                  date.month == dateSelectionnee.month &&
                  date.day == dateSelectionnee.day;
              final pointCouleur = pointsCouleursParDate[jour];

              return GestureDetector(
                onTap: () => onDateSelectionnee(date),
                behavior: HitTestBehavior.opaque,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: estSelectionne ? const Color(0xFF1D61F2) : Colors.transparent,
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        '$jour',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: estSelectionne ? FontWeight.w800 : FontWeight.w600,
                          color: estSelectionne ? Colors.white : const Color(0xFF0F172A),
                        ),
                      ),
                    ),
                    const SizedBox(height: 3),
                    Container(
                      width: 4.5,
                      height: 4.5,
                      decoration: BoxDecoration(
                        color: pointCouleur ?? Colors.transparent,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
