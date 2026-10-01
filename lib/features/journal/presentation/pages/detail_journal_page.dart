import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/network/configuration_api.dart';

class DetailJournalPage extends StatelessWidget {
  const DetailJournalPage({
    this.donneesJournal,
    this.estValide = true,
    this.dateStage = '10 Janvier 2026',
    this.statutTexte = 'VALIDÉ',
    this.resumeApprentissages =
        'Suture et gestion de l\'asepsie clinique stricte en box de traumatologie de jour. Manipulation soignée du matériel chirurgical sous supervision.',
    this.difficultesEtSolutions =
        'Difficulté lors de la gestion d\'un grand nombre de blessés aux urgences. Solution : priorisation stricte selon le niveau de gravité.',
    this.superviseurNom = 'Dr. Marie Dupont — HGK Urgences',
    this.validationDateTexte = 'Validé',
    this.commentaireSuperviseur =
        '"Très bon comportement clinique de l\'étudiant. Les gestes de suture ont été parfaits et l\'hygiène bien respectée."',
    this.activites = const [],
    super.key,
  });

  final Map<String, dynamic>? donneesJournal;
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
    final donneesApi = donneesJournal != null;
    // Si donneesJournal est fourni (depuis l'API ou le mock dynamique), extraire ses champs
    final statutReel =
        (donneesJournal?['statut'] ??
                donneesJournal?['status'] ??
                (donneesApi ? '' : statutTexte))
            .toString()
            .toUpperCase();
    final bool estValideReel = statutReel == 'VALIDE' || statutReel == 'VALIDÉ';

    final dateReelle =
        donneesJournal?['date']?.toString() ?? (donneesApi ? '' : dateStage);
    final resumeReel =
        donneesJournal?['summary']?.toString() ??
        donneesJournal?['learning']?.toString() ??
        (donneesApi ? '' : resumeApprentissages);
    final difficultesReelles =
        donneesJournal?['difficulties']?.toString() ??
        (donneesApi ? '' : difficultesEtSolutions);
    final superviseurReel =
        donneesJournal?['supervisor_name']?.toString() ??
        donneesJournal?['evaluator_name'] ??
        (donneesApi ? '' : superviseurNom);
    final commentaireReel =
        donneesJournal?['validator_comment']?.toString() ??
        donneesJournal?['comment']?.toString() ??
        donneesJournal?['feedback']?.toString() ??
        (donneesApi ? '' : commentaireSuperviseur);

    // Extraire les activités réelles
    List<ActiviteRattachee> listeActivites = activites;
    if (donneesJournal != null && donneesJournal!['activities'] is List) {
      final brutes = donneesJournal!['activities'] as List;
      if (brutes.isNotEmpty) {
        listeActivites = brutes.whereType<Map>().map((m) {
          final niveau =
              (m['involvement_level'] ?? m['category'] ?? m['level'] ?? '')
                  .toString()
                  .toUpperCase();
          final titre = (m['activity'] ?? m['title'] ?? '').toString();
          final obs = m['observation'] != null ? ' (${m['observation']})' : '';
          return ActiviteRattachee(niveau: niveau, titre: '$titre$obs');
        }).toList();
      }
    }

    if (listeActivites.isEmpty &&
        ConfigurationApi.utiliserDonneesMockees &&
        !donneesApi) {
      listeActivites = const [
        ActiviteRattachee(
          niveau: 'RÉALISATION AUTONOME',
          titre:
              'Point de suture sur plaie du cuir chevelu — 3 points Nylon 3-0',
        ),
        ActiviteRattachee(
          niveau: 'RÉALISATION AUTONOME',
          titre: 'Pansement compressif et lavage de brûlure thermique',
        ),
      ];
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF8FAFC),
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(
            CupertinoIcons.chevron_left,
            color: Color(0xFF0F172A),
            size: 24,
          ),
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
            if (estValideReel) ...[
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
                              color: const Color(0xFF15803D),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Carte Date + Statut
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Date du stage',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFF94A3B8),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        dateReelle,
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF0F172A),
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4.5,
                    ),
                    decoration: BoxDecoration(
                      color: estValideReel
                          ? const Color(0xFFDCFCE7)
                          : const Color(0xFFE0F2FE),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      statutReel,
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: estValideReel
                            ? const Color(0xFF16A34A)
                            : const Color(0xFF0284C7),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Bloc Résumé des apprentissages
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        CupertinoIcons.doc_text,
                        size: 18,
                        color: Color(0xFF1D61F2),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Résumé & Apprentissages',
                        style: GoogleFonts.inter(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF0F172A),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    resumeReel,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF334155),
                      height: 1.45,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Bloc Difficultés rencontrées & Solutions
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        CupertinoIcons.lightbulb,
                        size: 18,
                        color: Color(0xFFEA580C),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Difficultés & Solutions',
                        style: GoogleFonts.inter(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF0F172A),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    difficultesReelles,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF334155),
                      height: 1.45,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Bloc Validation du superviseur
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        CupertinoIcons.check_mark_circled,
                        size: 18,
                        color: Color(0xFF16A34A),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Validation du superviseur',
                        style: GoogleFonts.inter(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF0F172A),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 18,
                        backgroundColor: const Color(0xFFE2E8F0),
                        child: const Icon(
                          Icons.person,
                          size: 20,
                          color: Color(0xFF64748B),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              superviseurReel,
                              style: GoogleFonts.inter(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF0F172A),
                              ),
                            ),
                            Text(
                              validationDateTexte,
                              style: GoogleFonts.inter(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w500,
                                color: const Color(0xFF94A3B8),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFF1F5F9)),
                    ),
                    child: Text(
                      commentaireReel,
                      style: GoogleFonts.inter(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w500,
                        fontStyle: FontStyle.italic,
                        color: const Color(0xFF475569),
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Titre Activités rattachées
            Text(
              'Activités rattachées (${listeActivites.length})',
              style: GoogleFonts.inter(
                fontSize: 16.5,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF0F172A),
              ),
            ),

            const SizedBox(height: 12),

            // Cartes d'activités rattachées
            for (final act in listeActivites)
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
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3.5,
                        ),
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
