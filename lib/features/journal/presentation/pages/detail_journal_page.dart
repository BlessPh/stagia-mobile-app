import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class DetailJournalPage extends StatelessWidget {
  const DetailJournalPage({
    this.estValide = true,
    this.dateStage = '10 Janvier 2026',
    this.statutTexte = 'VALIDÉ',
    this.resumeApprentissages =
        'Suture et gestion de l\'asepsie clinique stricte en box de traumatologie de jour. Manipulation soignée du matériel chirurgical sous supervision.',
    this.difficultesEtSolutions =
        'Difficulté lors de la gestion d\'un grand nombre de blessés aux urgences. Solution : priorisation stricte selon le niveau de gravité.',
    this.superviseurNom = 'Dr. Marie Dupont — HGK Urgences',
    this.validationDateTexte = 'Validé le 12 Jan',
    this.commentaireSuperviseur =
        '"Très bon comportement clinique de l\'étudiant. Les gestes de suture ont été parfaits et l\'hygiène bien respectée."',
    this.activites = const [
      ActiviteRattachee(
        niveau: 'RÉALISATION AUTONOME',
        titre: 'Point de suture sur plaie du cuir chevelu — 3 points Nylon 3-0',
      ),
      ActiviteRattachee(
        niveau: 'RÉALISATION AUTONOME',
        titre: 'Pansement compressif et lavage de brûlure thermique',
      ),
    ],
    super.key,
  });

  final bool estValide;
  final String dateStage;
  final String statutTexte;
  final String resumeApprentissages;
  final String difficultesEtSolutions;
  final String superviseurNom;
  final String validationDateTexte;
  final String commentaireSuperviseur;
  final List<ActiviteRattachee> activites;

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
          'Détail du journal',
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
            // Bannière verte : Journal clinique validé
            if (estValide) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0FDF4),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFDCFCE7)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      CupertinoIcons.lock_shield,
                      color: Color(0xFF16A34A),
                      size: 22,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Journal clinique validé',
                            style: GoogleFonts.inter(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w800,
                              color: const Color(0xFF16A34A),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Ce document a été validé par le médecin et n\'est plus modifiable.',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: const Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
            ],

            // Date du stage + Badge statut
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Date du stage',
                      style: GoogleFonts.inter(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFF94A3B8),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      dateStage,
                      style: GoogleFonts.inter(
                        fontSize: 17,
                        fontWeight: FontWeight.w900,
                        color: const Color(0xFF0F172A),
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4.5),
                  decoration: BoxDecoration(
                    color: const Color(0xFFDCFCE7),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    statutTexte,
                    style: GoogleFonts.inter(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF16A34A),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),
            const Divider(height: 1, color: Color(0xFFE2E8F0)),
            const SizedBox(height: 16),

            // Résumé des apprentissages
            Text(
              'Résumé des apprentissages',
              style: GoogleFonts.inter(
                fontSize: 14.5,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              resumeApprentissages,
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF64748B),
                height: 1.4,
              ),
            ),

            const SizedBox(height: 16),

            // Difficultés et solutions
            Text(
              'Difficultés et solutions',
              style: GoogleFonts.inter(
                fontSize: 14.5,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              difficultesEtSolutions,
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF64748B),
                height: 1.4,
              ),
            ),

            const SizedBox(height: 18),

            // Bloc Feedback de l'encadreur (fond bleu doux)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF0F7FF),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE0F2FE)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text.rich(
                          TextSpan(
                            children: [
                              TextSpan(
                                text: '$superviseurNom • ',
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFF1D61F2),
                                ),
                              ),
                              TextSpan(
                                text: validationDateTexte,
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: const Color(0xFF64748B),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    commentaireSuperviseur,
                    style: GoogleFonts.inter(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF0F172A),
                      fontStyle: FontStyle.italic,
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 22),

            // Activités rattachées
            Text(
              'Activités rattachées (${activites.length})',
              style: GoogleFonts.inter(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 12),

            for (final act in activites)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF3E8FF),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          act.niveau,
                          style: GoogleFonts.inter(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF7E22CE),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        act.titre,
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF0F172A),
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class ActiviteRattachee {
  const ActiviteRattachee({required this.niveau, required this.titre});
  final String niveau;
  final String titre;
}
