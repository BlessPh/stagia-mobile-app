import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../widgets/carousel_accueil.dart';
import '../widgets/section_stage_disponible_accueil.dart';
import '../widgets/section_taches_jour_accueil.dart';
import '../widgets/section_stage_en_cours_accueil.dart';
import 'home_shared_widgets.dart';

class HomePremiereConnexionPage extends StatelessWidget {
  const HomePremiereConnexionPage({
    required this.campagnes,
    required this.candidatures,
    required this.onVoirCampagnes,
    this.stats = const {},
    super.key,
  });

  final List<Map<String, dynamic>> campagnes;
  final List<Map<String, dynamic>> candidatures;
  final VoidCallback? onVoirCampagnes;
  final Map<String, dynamic> stats;

  @override
  Widget build(BuildContext context) {
    final marge = MediaQuery.sizeOf(context).width < 360 ? 14.0 : 18.0;
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: EdgeInsets.fromLTRB(marge, 12, marge, 28),
      children: [
        const CarouselAccueil(),
        const SizedBox(height: 20),
        const SectionTachesJourAccueil(),
        const SizedBox(height: 20),
        const SectionStageDisponibleAccueil(),
        const SizedBox(height: 20),
        SectionStageEnCoursAccueil(
          onTap: onVoirCampagnes,
        ),
        const SizedBox(height: 22),
        Text(
          'Vos indicateurs',
          style: GoogleFonts.inter(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: const Color(0xFF0F172A),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: IndicateurStatistiqueAccueil(
                cheminIcone: 'assets/icons/candidature.png',
                valeur: '${stats['applications'] ?? candidatures.length}',
                libelle: 'Candidatures',
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: IndicateurStatistiqueAccueil(
                cheminIcone: 'assets/icons/stage_en_cours.png',
                valeur: '${stats['active_reservations'] ?? 0}',
                libelle: 'Réservations',
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: IndicateurStatistiqueAccueil(
                cheminIcone: 'assets/icons/documents.png',
                valeur: '${stats['documents'] ?? 0}',
                libelle: 'Documents',
              ),
            ),
          ],
        ),
      ],
    );
  }
}
