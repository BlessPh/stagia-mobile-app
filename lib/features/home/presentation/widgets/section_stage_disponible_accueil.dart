import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../stage/data/datasources/source_campagne_mock.dart';
import '../../../stage/domain/entities/campagne_stage.dart';
import '../../../stage/presentation/pages/detail_campagne_page.dart';

class SectionStageDisponibleAccueil extends StatelessWidget {
  const SectionStageDisponibleAccueil({
    this.campagne,
    this.onVoirDetails,
    super.key,
  });

  final CampagneStage? campagne;
  final VoidCallback? onVoirDetails;

  @override
  Widget build(BuildContext context) {
    final infoCampagne = campagne ?? SourceCampagneMock.obtenirCampagneOuverte();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // En-tête : Titre + Badge 1 campagne ouverte
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Stage disponible',
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF0F172A),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4.5),
              decoration: BoxDecoration(
                color: const Color(0xFFE0F2FE),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '1 campagne ouverte',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF0284C7),
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 12),

        // Carte de la campagne ouverte
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFF1F5F9)),
            boxShadow: const [
              BoxShadow(
                color: Color(0x0A000000),
                blurRadius: 16,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Ligne supérieure en dégradé bleu / violet
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
                child: Container(
                  height: 4.5,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [
                        Color(0xFF1D61F2),
                        Color(0xFF8B5CF6),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),

              Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Titre de la campagne
                    Text(
                      infoCampagne.titre,
                      style: GoogleFonts.inter(
                        fontSize: 17.5,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF0F172A),
                      ),
                    ),

                    const SizedBox(height: 14),

                    // Ligne à 2 colonnes : Date et Indemnité
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Colonne Date
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Date',
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: const Color(0xFF94A3B8),
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                '01 Oct 2026 - 31 Jan\n2027',
                                style: GoogleFonts.inter(
                                  fontSize: 14.5,
                                  fontWeight: FontWeight.w800,
                                  color: const Color(0xFF0F172A),
                                  height: 1.25,
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Colonne Indemnité
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Indemnité',
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: const Color(0xFF94A3B8),
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                infoCampagne.indemnite,
                                style: GoogleFonts.inter(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w800,
                                  color: const Color(0xFF0F172A),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 14),

                    // Badge Inscriptions ouvertes + Hôpitaux disponibles
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4.5,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFDCFCE7),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            infoCampagne.statut,
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF15803D),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          '${infoCampagne.nombreHopitaux} hôpitaux disponibles',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: const Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    // Coche Vous êtes éligible
                    Row(
                      children: [
                        const Icon(
                          Icons.check_circle_rounded,
                          color: Color(0xFF16A34A),
                          size: 18,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Vous êtes éligible',
                          style: GoogleFonts.inter(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF16A34A),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // Bouton bleu "Voir les détails"
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: FilledButton(
                        onPressed: () {
                          if (onVoirDetails != null) {
                            onVoirDetails!();
                          } else {
                            Navigator.of(context, rootNavigator: true).push(
                              MaterialPageRoute<void>(
                                builder: (_) => DetailCampagnePage(
                                  campagne: infoCampagne,
                                ),
                              ),
                            );
                          }
                        },
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFF1D61F2),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                        child: Text(
                          'Voir les détails',
                          style: GoogleFonts.inter(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
