import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../planning/data/datasources/source_planning_mock.dart';
import '../../../planning/domain/entities/tache_planning.dart';
import '../../../planning/presentation/pages/detail_tache_page.dart';
import '../../../planning/presentation/pages/planning_page.dart';

class SectionTachesJourAccueil extends StatelessWidget {
  const SectionTachesJourAccueil({
    this.date,
    this.tachesPersonnalisees,
    super.key,
  });

  final DateTime? date;
  final List<TachePlanning>? tachesPersonnalisees;

  DateTime _determinerDateReference() {
    if (date != null) {
      return DateTime(date!.year, date!.month, date!.day);
    }
    if (tachesPersonnalisees != null && tachesPersonnalisees!.isNotEmpty) {
      final premiere = tachesPersonnalisees!.first.date;
      return DateTime(premiere.year, premiere.month, premiere.day);
    }
    final now = DateTime.now();
    final dateNow = DateTime(now.year, now.month, now.day);
    if (now.year == 2026 && now.month == 9) {
      return dateNow;
    }
    if (SourcePlanningMock.dateContientTaches(dateNow)) {
      return dateNow;
    }
    // Date de référence par défaut dans la période mockée
    return DateTime(2026, 9, 17);
  }

  bool _memeJour(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  String _formaterDateCourte(DateTime date) {
    const jours = ['Lun', 'Mar', 'Mer', 'Jeu', 'Ven', 'Sam', 'Dim'];
    const mois = [
      'Jan', 'Fév', 'Mar', 'Avr', 'Mai', 'Juin',
      'Juil', 'Août', 'Sep', 'Oct', 'Nov', 'Déc',
    ];
    final j = jours[date.weekday - 1];
    final m = mois[date.month - 1];
    return '$j ${date.day} $m';
  }

  @override
  Widget build(BuildContext context) {
    final aujourdHui = _determinerDateReference();
    final demain = aujourdHui.add(const Duration(days: 1));
    final apresDemain = aujourdHui.add(const Duration(days: 2));

    String titreSection;
    List<TachePlanning> tachesAffichees;
    DateTime dateCible = aujourdHui;
    bool estTachesAVenir = false;

    // 1. Vérifier d'abord s'il y a des tâches pour aujourd'hui
    final List<TachePlanning> tachesAujourdHui;
    if (tachesPersonnalisees != null) {
      tachesAujourdHui = tachesPersonnalisees!
          .where((t) => _memeJour(t.date, aujourdHui))
          .toList();
    } else {
      tachesAujourdHui = SourcePlanningMock.obtenirTachesPourDate(aujourdHui);
    }

    if (tachesAujourdHui.isNotEmpty) {
      titreSection = 'Tâches du jour';
      tachesAffichees = tachesAujourdHui.take(2).toList();
      dateCible = aujourdHui;
    } else {
      // 2. Pas de tâche aujourd'hui -> Vérifier les tâches de demain
      final List<TachePlanning> tachesDemain;
      if (tachesPersonnalisees != null) {
        tachesDemain = tachesPersonnalisees!
            .where((t) => _memeJour(t.date, demain))
            .toList();
      } else {
        tachesDemain = SourcePlanningMock.obtenirTachesPourDate(demain);
      }

      if (tachesDemain.isNotEmpty) {
        titreSection = 'Tâches de demain';
        tachesAffichees = tachesDemain.take(2).toList();
        dateCible = demain;
      } else {
        // 3. Pas de tâche demain -> Tâches à venir (après demain)
        final List<TachePlanning> poolTaches = tachesPersonnalisees ??
            SourcePlanningMock.toutesLesTaches();

        final tachesFutures = poolTaches.where((t) {
          final d = DateTime(t.date.year, t.date.month, t.date.day);
          return !d.isBefore(apresDemain);
        }).toList()
          ..sort((a, b) {
            final compDate = a.date.compareTo(b.date);
            if (compDate != 0) return compDate;
            return a.heureDebut.compareTo(b.heureDebut);
          });

        if (tachesFutures.isNotEmpty) {
          titreSection = 'Tâches à venir';
          tachesAffichees = tachesFutures.take(2).toList();
          dateCible = tachesFutures.first.date;
          estTachesAVenir = true;
        } else if (poolTaches.isNotEmpty) {
          titreSection = 'Tâches à venir';
          tachesAffichees = poolTaches.take(2).toList();
          dateCible = tachesAffichees.first.date;
          estTachesAVenir = true;
        } else {
          return const SizedBox.shrink();
        }
      }
    }

    if (tachesAffichees.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // En-tête : Titre dynamique et action "Voir tout"
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              titreSection,
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF0F172A),
              ),
            ),
            InkWell(
              onTap: () {
                Navigator.of(context, rootNavigator: true).push(
                  MaterialPageRoute<void>(
                    builder: (_) => PlanningPage(dateInitiale: dateCible),
                  ),
                );
              },
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                child: Text(
                  'Voir tout',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF2563EB),
                  ),
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 12),

        // Cartes des tâches (maximum 2)
        ...tachesAffichees.map(
          (tache) => _buildCarteTache(
            context,
            tache,
            afficherDate: estTachesAVenir,
          ),
        ),
      ],
    );
  }

  Widget _buildCarteTache(
    BuildContext context,
    TachePlanning tache, {
    bool afficherDate = false,
  }) {
    Color fondBadge;
    Color texteBadge;

    switch (tache.type) {
      case 'Chirurgie':
        fondBadge = const Color(0xFFEFF6FF);
        texteBadge = const Color(0xFF2563EB);
        break;
      case 'Projet':
        fondBadge = const Color(0xFFFAF5FF);
        texteBadge = const Color(0xFF9333EA);
        break;
      case 'Examen':
        fondBadge = const Color(0xFFFFF7ED);
        texteBadge = const Color(0xFFEA580C);
        break;
      case 'Garde':
        fondBadge = const Color(0xFFFEF2F2);
        texteBadge = const Color(0xFFDC2626);
        break;
      case 'Cours':
        fondBadge = const Color(0xFFEFF6FF);
        texteBadge = const Color(0xFF3B82F6);
        break;
      case 'Stage':
      default:
        fondBadge = const Color(0xFFF0FDF4);
        texteBadge = const Color(0xFF16A34A);
        break;
    }

    final datePrefix = afficherDate ? '${_formaterDateCourte(tache.date)} • ' : '';
    final lieuTexte =
        '$datePrefix${tache.lieu ?? '${tache.service} • ${tache.departement}'}';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Color(0x08000000),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: () {
            Navigator.of(context, rootNavigator: true).push(
              MaterialPageRoute<void>(
                builder: (_) => DetailTachePage(tache: tache),
              ),
            );
          },
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Heure de début et de fin
                SizedBox(
                  width: 58,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        tache.heureDebut,
                        style: GoogleFonts.inter(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        tache.heureFin,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFF94A3B8),
                        ),
                      ),
                    ],
                  ),
                ),

                // Séparateur vertical
                Container(
                  width: 1,
                  height: 38,
                  margin: const EdgeInsets.symmetric(horizontal: 12),
                  color: const Color(0xFFF1F5F9),
                ),

                // Contenu : Badge, Lieu et Titre
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: fondBadge,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              tache.type,
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: texteBadge,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              lieuTexte,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: const Color(0xFF64748B),
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: tache.couleur,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        tache.titre,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF0F172A),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
