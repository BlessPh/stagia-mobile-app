import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/network/configuration_api.dart';

class FicheEvaluationPage extends StatelessWidget {
  const FicheEvaluationPage({
    this.donneesEvaluation,
    this.scoreGlobal = 17.5,
    this.totalScore = 20,
    this.nomEvaluateur = 'Dr. Marie Dupont',
    this.fonctionEvaluateur = 'Médecin Chef Adjoint — HKG Urgences',
    this.initialesEvaluateur = 'MD',
    this.pointsForts = const [],
    this.axesAmelioration = const [],
    this.competences = const [],
    super.key,
  });

  final Map<String, dynamic>? donneesEvaluation;
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
    final donneesApi = donneesEvaluation != null;
    // Si donneesEvaluation est fourni depuis l'API, extraire les données dynamiques
    final score = donneesEvaluation != null
        ? (double.tryParse(
                (donneesEvaluation!['score'] ??
                        donneesEvaluation!['note'] ??
                        donneesEvaluation!['global_score'] ??
                        0)
                    .toString(),
              ) ??
              0)
        : scoreGlobal;

    final evaluator = donneesEvaluation?['evaluator'] is Map
        ? Map<String, dynamic>.from(donneesEvaluation!['evaluator'] as Map)
        : const <String, dynamic>{};
    final evalNom =
        evaluator['name']?.toString() ??
        donneesEvaluation?['evaluator_name']?.toString() ??
        donneesEvaluation?['supervisor']?.toString() ??
        (donneesApi ? '' : nomEvaluateur);

    final unit = donneesEvaluation?['unit'] is Map
        ? Map<String, dynamic>.from(donneesEvaluation!['unit'] as Map)
        : const <String, dynamic>{};
    final hospital = donneesEvaluation?['hospital'] is Map
        ? Map<String, dynamic>.from(donneesEvaluation!['hospital'] as Map)
        : const <String, dynamic>{};
    final evalFonction =
        evaluator['function']?.toString() ??
        donneesEvaluation?['evaluator_function']?.toString() ??
        unit['name']?.toString() ??
        hospital['name']?.toString() ??
        (donneesApi ? '' : fonctionEvaluateur);

    final evalInit = evalNom
        .split(' ')
        .where((e) => e.isNotEmpty && !e.startsWith('Dr.'))
        .map((e) => e[0])
        .take(2)
        .join();

    final appreciation =
        donneesEvaluation?['comment']?.toString() ??
        donneesEvaluation?['appreciation']?.toString() ??
        donneesEvaluation?['general_appreciation']?.toString();

    List<String> forts = pointsForts;
    if (forts.isEmpty) {
      final points = donneesEvaluation?['strengths']?.toString().trim() ?? '';
      if (points.isNotEmpty) {
        forts = [points];
      } else if (appreciation != null && appreciation.isNotEmpty) {
        forts = [appreciation];
      } else if (ConfigurationApi.utiliserDonneesMockees && !donneesApi) {
        forts = const [
          'Très rigoureux dans l\'application des protocoles sanitaires.',
          'Excellente communication avec les patients critiques et familles.',
        ];
      }
    }

    List<String> axes = axesAmelioration;
    if (axes.isEmpty) {
      final obs =
          donneesEvaluation?['improvement_areas']?.toString() ??
          donneesEvaluation?['observation']?.toString() ??
          donneesEvaluation?['improvement_points']?.toString();
      if (obs != null && obs.isNotEmpty) {
        axes = [obs];
      } else if (ConfigurationApi.utiliserDonneesMockees && !donneesApi) {
        axes = const [
          'Améliorer l\'organisation personnelle lors du rush des urgences pour éviter les retards dans la tenue du journal clinique.',
        ];
      }
    }

    List<CompetenceEvaluation> compList = competences;
    if (compList.isEmpty) {
      final donneesCompetences =
          donneesEvaluation?['scores'] ?? donneesEvaluation?['criteria'];
      if (donneesCompetences is List) {
        final bruts = donneesCompetences;
        compList = bruts.whereType<Map>().map((c) {
          final titre = (c['title'] ?? c['name'] ?? c['nom'] ?? '').toString();
          final note = double.tryParse(
            (c['note'] ?? c['score'] ?? '').toString(),
          );
          final noteMax = double.tryParse((c['note_max'] ?? '').toString());
          final val = note != null && noteMax != null && noteMax > 0
              ? ((note / noteMax) * 100).round()
              : (double.tryParse((c['percentage'] ?? 0).toString()) ?? 0)
                    .toInt();
          return CompetenceEvaluation(
            titre: titre,
            pourcentage: val,
            couleur: const Color(0xFF1D61F2),
            categorie: c['categorie']?.toString() ?? '',
            scoreTexte: note != null && noteMax != null
                ? '${_nombreCompact(note)} / ${_nombreCompact(noteMax)}'
                : null,
            commentaire: c['commentaire']?.toString(),
          );
        }).toList();
      }
    }

    if (compList.isEmpty &&
        ConfigurationApi.utiliserDonneesMockees &&
        !donneesApi) {
      compList = const [
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
      ];
    }

    final modeSombre = Theme.of(context).brightness == Brightness.dark;
    final fondPage = modeSombre
        ? const Color(0xFF0F172A)
        : const Color(0xFFF8FAFC);
    final fondCarte = modeSombre ? const Color(0xFF1E293B) : Colors.white;
    final bordureCouleur = modeSombre
        ? const Color(0xFF334155)
        : const Color(0xFFE2E8F0);
    final texteCouleur = modeSombre ? Colors.white : const Color(0xFF0F172A);
    final texteSecondaire = modeSombre
        ? const Color(0xFF94A3B8)
        : const Color(0xFF64748B);
    final separateurCouleur = modeSombre
        ? const Color(0xFF334155)
        : const Color(0xFFF1F5F9);

    final mentionAffichee = score >= 16
        ? 'Excellent'
        : (score >= 12 ? 'Bien' : 'Moyen');

    return Scaffold(
      backgroundColor: fondPage,
      appBar: AppBar(
        backgroundColor: fondPage,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: Icon(
            CupertinoIcons.chevron_left,
            color: texteCouleur,
            size: 24,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Fiche d\'évaluation',
          style: GoogleFonts.inter(
            fontSize: 18.5,
            fontWeight: FontWeight.w800,
            color: texteCouleur,
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
                color: fondCarte,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: bordureCouleur),
                boxShadow: [
                  BoxShadow(
                    color: modeSombre
                        ? const Color(0x30000000)
                        : const Color(0x06000000),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
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
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'SCORE GLOBAL',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF94A3B8),
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.baseline,
                            textBaseline: TextBaseline.alphabetic,
                            children: [
                              Text(
                                score.toStringAsFixed(1),
                                style: GoogleFonts.inter(
                                  fontSize: 32,
                                  fontWeight: FontWeight.w900,
                                  color: texteCouleur,
                                ),
                              ),
                              Text(
                                ' / $totalScore',
                                style: GoogleFonts.inter(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFF94A3B8),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: modeSombre
                              ? const Color(0xFF14532D)
                              : const Color(0xFFDCFCE7),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          mentionAffichee,
                          style: GoogleFonts.inter(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w800,
                            color: modeSombre
                                ? const Color(0xFF4ADE80)
                                : const Color(0xFF16A34A),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),
                  Divider(height: 1, color: separateurCouleur),
                  const SizedBox(height: 18),

                  // Évaluateur
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 22,
                        backgroundColor: modeSombre
                            ? const Color(0xFF1E3A8A).withValues(alpha: 0.5)
                            : const Color(0xFFEFF6FF),
                        child: Text(
                          evalInit.isNotEmpty ? evalInit : initialesEvaluateur,
                          style: GoogleFonts.inter(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF1D61F2),
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              evalNom,
                              style: GoogleFonts.inter(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: texteCouleur,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              evalFonction,
                              style: GoogleFonts.inter(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w500,
                                color: texteSecondaire,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 18),
                  Divider(height: 1, color: separateurCouleur),
                  const SizedBox(height: 16),

                  // Points Forts
                  Text(
                    'Points Forts',
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: texteCouleur,
                    ),
                  ),
                  const SizedBox(height: 8),
                  for (final point in forts)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Text(
                        '- $point',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: texteSecondaire,
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
                      color: texteCouleur,
                    ),
                  ),
                  const SizedBox(height: 8),
                  for (final axe in axes)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Text(
                        '- $axe',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: texteSecondaire,
                          height: 1.35,
                        ),
                      ),
                    ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Compétences
            Text(
              'Compétences évaluées',
              style: GoogleFonts.inter(
                fontSize: 16.5,
                fontWeight: FontWeight.w800,
                color: texteCouleur,
              ),
            ),
            const SizedBox(height: 12),

            for (final comp in compList)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: fondCarte,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: bordureCouleur),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              comp.titre,
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: texteCouleur,
                              ),
                            ),
                          ),
                          Text(
                            comp.scoreTexte ?? '${comp.pourcentage}%',
                            style: GoogleFonts.inter(
                              fontSize: 14.5,
                              fontWeight: FontWeight.w800,
                              color: comp.couleur,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      if (comp.categorie.isNotEmpty) ...[
                        Text(
                          comp.categorie.replaceAll('_', ' '),
                          style: GoogleFonts.inter(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF94A3B8),
                          ),
                        ),
                        const SizedBox(height: 8),
                      ],
                      ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: LinearProgressIndicator(
                          value: comp.pourcentage / 100,
                          minHeight: 8,
                          backgroundColor: modeSombre
                              ? const Color(0xFF334155)
                              : const Color(0xFFF1F5F9),
                          valueColor: AlwaysStoppedAnimation<Color>(
                            comp.couleur,
                          ),
                        ),
                      ),
                      if ((comp.commentaire ?? '').trim().isNotEmpty) ...[
                        const SizedBox(height: 10),
                        Text(
                          comp.commentaire!.trim(),
                          style: GoogleFonts.inter(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w500,
                            color: texteSecondaire,
                            height: 1.3,
                          ),
                        ),
                      ],
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

class CompetenceEvaluation {
  const CompetenceEvaluation({
    required this.titre,
    required this.pourcentage,
    required this.couleur,
    this.categorie = '',
    this.scoreTexte,
    this.commentaire,
  });

  final String titre;
  final int pourcentage;
  final Color couleur;
  final String categorie;
  final String? scoreTexte;
  final String? commentaire;
}

String _nombreCompact(double valeur) => valeur == valeur.roundToDouble()
    ? valeur.toInt().toString()
    : valeur.toStringAsFixed(1);
