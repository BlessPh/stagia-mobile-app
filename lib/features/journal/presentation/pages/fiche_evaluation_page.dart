import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class FicheEvaluationPage extends StatelessWidget {
  const FicheEvaluationPage({
    this.scoreGlobal = 17.5,
    this.totalScore = 20,
    this.nomEvaluateur = 'Dr. Marie Dupont',
    this.fonctionEvaluateur = 'Médecin Chef Adjoint — HKG Urgences',
    this.initialesEvaluateur = 'MD',
    this.pointsForts = const [
      'Très rigoureux dans l\'application des protocoles sanitaires.',
      'Excellente communication avec les patients critiques et familles.',
    ],
    this.axesAmelioration = const [
      'Améliorer l\'organisation personnelle lors du rush des urgences pour éviter les retards dans la tenue du journal clinique.',
    ],
    this.competences = const [
      CompetenceEvaluation(
        titre: 'Gestes Techniques Cliniques',
        pourcentage: 85,
        couleur: Color(0xFF1D61F2),
      ),
      CompetenceEvaluation(
        titre: 'Diagnostic & Raisonnement',
        pourcentage: 90,
        couleur: Color(0xFF16A34A),
      ),
      CompetenceEvaluation(
        titre: 'Relation patient & Éthique',
        pourcentage: 95,
        couleur: Color(0xFF8B5CF6),
      ),
      CompetenceEvaluation(
        titre: 'Assiduité & Ponctualité',
        pourcentage: 100,
        couleur: Color(0xFFF97316),
      ),
    ],
    super.key,
  });

  final double scoreGlobal;
  final int totalScore;
  final String nomEvaluateur;
  final String fonctionEvaluateur;
  final String initialesEvaluateur;
  final List<String> pointsForts;
  final List<String> axesAmelioration;
  final List<CompetenceEvaluation> competences;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF8FAFC),
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(CupertinoIcons.chevron_left, color: Color(0xFF0F172A), size: 24),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Fiche d\'Évaluation',
          style: GoogleFonts.inter(
            fontSize: 18.5,
            fontWeight: FontWeight.w800,
            color: const Color(0xFF0F172A),
          ),
        ),
      ),
      body: SafeArea(
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
          children: [
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: const Color(0xFFE2E8F0)),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x06000000),
                    blurRadius: 16,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Ligne Score Global
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Score Global de Rotation',
                        style: GoogleFonts.inter(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFF64748B),
                        ),
                      ),
                      Text(
                        '${scoreGlobal.toStringAsFixed(1)} / $totalScore',
                        style: GoogleFonts.inter(
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                          color: const Color(0xFF1D61F2),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),
                  const Divider(height: 1, color: Color(0xFFF1F5F9)),
                  const SizedBox(height: 16),

                  // Évaluateur
                  Row(
                    children: [
                      Container(
                        width: 46,
                        height: 46,
                        decoration: const BoxDecoration(
                          color: Color(0xFFE0F2FE),
                          shape: BoxShape.circle,
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          initialesEvaluateur,
                          style: GoogleFonts.inter(
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF0284C7),
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              nomEvaluateur,
                              style: GoogleFonts.inter(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: const Color(0xFF0F172A),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              fonctionEvaluateur,
                              style: GoogleFonts.inter(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w500,
                                color: const Color(0xFF64748B),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 18),
                  const Divider(height: 1, color: Color(0xFFF1F5F9)),
                  const SizedBox(height: 16),

                  // Points Forts
                  Text(
                    'Points Forts',
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 8),
                  for (final point in pointsForts)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Text(
                        '- $point',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFF64748B),
                          height: 1.35,
                        ),
                      ),
                    ),

                  const SizedBox(height: 14),

                  // Axes d'Amélioration
                  Text(
                    'Axes d\'Amélioration',
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 8),
                  for (final axe in axesAmelioration)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Text(
                        '- $axe',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFF64748B),
                          height: 1.35,
                        ),
                      ),
                    ),

                  const SizedBox(height: 18),
                  const Divider(height: 1, color: Color(0xFFF1F5F9)),
                  const SizedBox(height: 16),

                  // Détail des compétences
                  Text(
                    'Détail des compétences',
                    style: GoogleFonts.inter(
                      fontSize: 15.5,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 14),

                  for (final comp in competences)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                comp.titre,
                                style: GoogleFonts.inter(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFF0F172A),
                                ),
                              ),
                              Text(
                                '${comp.pourcentage}%',
                                style: GoogleFonts.inter(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w800,
                                  color: const Color(0xFF0F172A),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: comp.pourcentage / 100,
                              minHeight: 6,
                              backgroundColor: const Color(0xFFF1F5F9),
                              valueColor: AlwaysStoppedAnimation<Color>(comp.couleur),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class CompetenceEvaluation {
  const CompetenceEvaluation({
    required this.titre,
    required this.pourcentage,
    required this.couleur,
  });

  final String titre;
  final int pourcentage;
  final Color couleur;
}
