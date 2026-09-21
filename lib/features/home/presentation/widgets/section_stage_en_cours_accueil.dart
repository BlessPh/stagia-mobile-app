import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class SectionStageEnCoursAccueil extends StatelessWidget {
  const SectionStageEnCoursAccueil({
    this.titreCampagne = 'Campagne de Stage Clinique 2026',
    this.nomEtablissement = 'Hôpital Général de Kinshasa',
    this.joursEffectues = 45,
    this.totalJours = 90,
    this.servicesEffectues = 3,
    this.totalServices = 6,
    this.serviceActuel = 'Chirurgie Générale',
    this.joursRestantsService = 12,
    this.nomEncadreur = 'Dr. Marie Kabongo',
    this.photoEncadreur,
    this.onTap,
    super.key,
  });

  final String titreCampagne;
  final String nomEtablissement;
  final int joursEffectues;
  final int totalJours;
  final int servicesEffectues;
  final int totalServices;
  final String serviceActuel;
  final int joursRestantsService;
  final String nomEncadreur;
  final String? photoEncadreur;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final progression = totalJours > 0 ? (joursEffectues / totalJours).clamp(0.0, 1.0) : 0.0;
    final pourcentageTexte = (progression * 100).toInt();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // En-tête : Titre + Badge 1 campagne active
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Stage en cours',
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
                '1 campagne active',
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

        // Carte principale du stage en cours
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(20),
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFE2E8F0)),
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
                          titreCampagne,
                          style: GoogleFonts.inter(
                            fontSize: 17.5,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF0F172A),
                          ),
                        ),

                        const SizedBox(height: 10),

                        // Établissement avec icône hôpital
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF1F5F9),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Icon(
                                Icons.domain_rounded,
                                size: 18,
                                color: Color(0xFF3B82F6),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                nomEtablissement,
                                style: GoogleFonts.inter(
                                  fontSize: 14.5,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFF1E293B),
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 16),

                        // Progression du stage : Titre + Valeur
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Progression du stage',
                              style: GoogleFonts.inter(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w500,
                                color: const Color(0xFF64748B),
                              ),
                            ),
                            Text(
                              '$joursEffectues / $totalJours jours',
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                                color: const Color(0xFF0F172A),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 8),

                        // Barre de progression
                        ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: LinearProgressIndicator(
                            value: progression,
                            minHeight: 7,
                            backgroundColor: const Color(0xFFE2E8F0),
                            valueColor: const AlwaysStoppedAnimation<Color>(
                              Color(0xFF6366F1),
                            ),
                          ),
                        ),

                        const SizedBox(height: 6),

                        // Sous-titre progression
                        Text(
                          '$pourcentageTexte% du stage effectué',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: const Color(0xFF94A3B8),
                          ),
                        ),

                        const SizedBox(height: 14),

                        // 3/6 services avec icône rotation
                        Row(
                          children: [
                            const Icon(
                              Icons.sync_rounded,
                              size: 18,
                              color: Color(0xFF3B82F6),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '$servicesEffectues/$totalServices services',
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF0F172A),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 10),

                        // Service actuel
                        Row(
                          children: [
                            const Icon(
                              Icons.medical_services_outlined,
                              size: 18,
                              color: Color(0xFF3B82F6),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Service actuel : $serviceActuel',
                                style: GoogleFonts.inter(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFF0F172A),
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 10),

                        // Jours restants dans ce service
                        Row(
                          children: [
                            const Icon(
                              Icons.calendar_today_outlined,
                              size: 18,
                              color: Color(0xFF3B82F6),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '$joursRestantsService jours restants dans ce service',
                              style: GoogleFonts.inter(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF0F172A),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 16),

                        // Séparateur fin
                        const Divider(height: 1, color: Color(0xFFF1F5F9)),

                        const SizedBox(height: 12),

                        // Encadreur (avatar + infos)
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 17,
                              backgroundColor: const Color(0xFFE2E8F0),
                              backgroundImage: const AssetImage(
                                'assets/images/avatar_etudiant.jpg',
                              ),
                              child: const Icon(
                                Icons.person,
                                size: 18,
                                color: Color(0xFF64748B),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Encadreur',
                                  style: GoogleFonts.inter(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w500,
                                    color: const Color(0xFF94A3B8),
                                  ),
                                ),
                                Text(
                                  nomEncadreur,
                                  style: GoogleFonts.inter(
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.w700,
                                    color: const Color(0xFF0F172A),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
