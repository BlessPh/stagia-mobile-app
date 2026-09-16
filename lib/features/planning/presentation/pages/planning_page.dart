import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../data/datasources/source_planning_mock.dart';
import '../../domain/entities/tache_planning.dart';
import '../widgets/ajouter_tache_modal.dart';
import '../widgets/tache_detail_modal.dart';
import 'detail_tache_page.dart';

class PlanningPage extends StatefulWidget {
  const PlanningPage({
    this.dateInitiale,
    super.key,
  });

  final DateTime? dateInitiale;

  @override
  State<PlanningPage> createState() => _PlanningPageState();
}

class _PlanningPageState extends State<PlanningPage> {
  late DateTime _dateSelectionnee;
  late DateTime _moisAffiche;
  bool _voirToutesLesTaches = false;

  final List<String> _joursSemaine = const [
    'Lun',
    'Mar',
    'Mer',
    'Jeu',
    'Ven',
    'Sam',
    'Dim',
  ];

  @override
  void initState() {
    super.initState();
    // Par défaut, on initialise sur le 16 septembre 2026 ou la date demandée
    _dateSelectionnee = widget.dateInitiale ?? DateTime(2026, 9, 16);
    _moisAffiche = DateTime(_dateSelectionnee.year, _dateSelectionnee.month);
  }

  void _selectionnerDate(DateTime date) {
    setState(() {
      _dateSelectionnee = date;
      _voirToutesLesTaches = false;
    });
  }

  void _changerMois(int delta) {
    setState(() {
      _moisAffiche = DateTime(_moisAffiche.year, _moisAffiche.month + delta);
    });
  }

  String _nomMois(int mois) {
    const moisNoms = [
      'Janvier',
      'Février',
      'Mars',
      'Avril',
      'Mai',
      'Juin',
      'Juillet',
      'Août',
      'Septembre',
      'Octobre',
      'Novembre',
      'Décembre',
    ];
    return moisNoms[mois - 1];
  }

  @override
  Widget build(BuildContext context) {
    final taches = _voirToutesLesTaches
        ? SourcePlanningMock.toutesLesTaches()
        : SourcePlanningMock.obtenirTachesPourDate(_dateSelectionnee);

    return Scaffold(
      backgroundColor: const Color(0xFF2563EB),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          AjouterTacheModal.afficher(
            context,
            date: _dateSelectionnee,
            onAjouter: (nouvelleTache) {
              setState(() {
                SourcePlanningMock.ajouterTache(nouvelleTache);
              });
            },
          );
        },
        backgroundColor: const Color(0xFF2563EB),
        foregroundColor: Colors.white,
        elevation: 6,
        shape: const CircleBorder(),
        child: const Icon(Icons.add_rounded, size: 28),
      ),
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // 1. En-tête bleu avec titre et icônes
            _buildEnTete(context),

            const SizedBox(height: 12),

            // 2. Calendrier interactif sur fond bleu
            _buildCalendrier(),

            const SizedBox(height: 18),

            // 3. Section inférieure blanche (Tâches du jour)
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  color: Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
                ),
                child: CustomScrollView(
                  slivers: [
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              _voirToutesLesTaches
                                  ? 'Toutes les tâches'
                                  : 'Tâches du jour',
                              style: GoogleFonts.inter(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: const Color(0xFF0F172A),
                              ),
                            ),
                            InkWell(
                              onTap: () {
                                setState(() {
                                  _voirToutesLesTaches = !_voirToutesLesTaches;
                                });
                              },
                              borderRadius: BorderRadius.circular(8),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 4,
                                ),
                                child: Text(
                                  _voirToutesLesTaches
                                      ? 'Vue du jour'
                                      : 'Voir tout',
                                  style: GoogleFonts.inter(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: const Color(0xFF2563EB),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Liste des tâches
                    if (taches.isEmpty)
                      SliverFillRemaining(
                        hasScrollBody: false,
                        child: _buildEtatVide(),
                      )
                    else
                      SliverPadding(
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 90),
                        sliver: SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (context, index) {
                              final tache = taches[index];
                              return _buildCarteTache(tache);
                            },
                            childCount: taches.length,
                          ),
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

  Widget _buildEnTete(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(6, 4, 16, 4),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.maybePop(context),
            icon: const Icon(
              Icons.arrow_back_ios_new_rounded,
              color: Colors.white,
              size: 20,
            ),
            padding: const EdgeInsets.all(8),
            constraints: const BoxConstraints(),
            tooltip: 'Retour',
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Mon planning',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.inter(
                fontSize: 21,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(width: 8),
          // Sélecteur compact de mois
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                InkWell(
                  onTap: () => _changerMois(-1),
                  borderRadius: BorderRadius.circular(14),
                  child: const Padding(
                    padding: EdgeInsets.all(4),
                    child: Icon(
                      Icons.chevron_left_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Text(
                    '${_nomMois(_moisAffiche.month).substring(0, 4)}. ${_moisAffiche.year}',
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 12.5,
                    ),
                  ),
                ),
                InkWell(
                  onTap: () => _changerMois(1),
                  borderRadius: BorderRadius.circular(14),
                  child: const Padding(
                    padding: EdgeInsets.all(4),
                    child: Icon(
                      Icons.chevron_right_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCalendrier() {
    // Calculer les jours du mois affiché
    final premierJourDuMois = DateTime(_moisAffiche.year, _moisAffiche.month, 1);
    final dernierJourDuMois = DateTime(_moisAffiche.year, _moisAffiche.month + 1, 0);

    // Ajustement pour aligner le premier jour (1 = Lundi, 7 = Dimanche)
    final decallage = (premierJourDuMois.weekday - 1);
    final nombreDeJours = dernierJourDuMois.day;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: Column(
        children: [
          // Ligne 1 : En-têtes des jours de la semaine (Lun, Mar, ...)
          Row(
            children: List.generate(7, (index) {
              return Expanded(
                child: Center(
                  child: Text(
                    _joursSemaine[index],
                    style: GoogleFonts.inter(
                      color: Colors.white.withValues(alpha: 0.8),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 8),

          // Grille des dates du mois
          Table(
            defaultVerticalAlignment: TableCellVerticalAlignment.middle,
            children: _construireLignesCalendrier(decallage, nombreDeJours),
          ),
        ],
      ),
    );
  }

  List<TableRow> _construireLignesCalendrier(int decallage, int totalJours) {
    final lignes = <TableRow>[];
    var cellules = <Widget>[];

    // Espaces vides avant le premier jour
    for (var i = 0; i < decallage; i++) {
      cellules.add(const SizedBox(height: 52));
    }

    for (var jour = 1; jour <= totalJours; jour++) {
      final date = DateTime(_moisAffiche.year, _moisAffiche.month, jour);
      final estSelectionne = _dateSelectionnee.year == date.year &&
          _dateSelectionnee.month == date.month &&
          _dateSelectionnee.day == date.day;
      final aDesTaches = SourcePlanningMock.dateContientTaches(date);

      cellules.add(
        _buildCelluleJour(
          jour: jour,
          nomJour: _joursSemaine[date.weekday - 1],
          estSelectionne: estSelectionne,
          aDesTaches: aDesTaches,
          onTap: () => _selectionnerDate(date),
        ),
      );

      if (cellules.length == 7) {
        lignes.add(TableRow(children: cellules));
        cellules = [];
      }
    }

    // Compléter la dernière ligne si nécessaire
    if (cellules.isNotEmpty) {
      while (cellules.length < 7) {
        cellules.add(const SizedBox(height: 52));
      }
      lignes.add(TableRow(children: cellules));
    }

    return lignes;
  }

  Widget _buildCelluleJour({
    required int jour,
    required String nomJour,
    required bool estSelectionne,
    required bool aDesTaches,
    required VoidCallback onTap,
  }) {
    if (estSelectionne) {
      // Capsule blanche verticale pour le jour sélectionné (conforme à l'image)
      return InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 2, vertical: 3),
          padding: const EdgeInsets.symmetric(vertical: 6),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: const [
              BoxShadow(
                color: Color(0x2E000000),
                blurRadius: 8,
                offset: Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                nomJour,
                style: GoogleFonts.inter(
                  color: const Color(0xFF2563EB),
                  fontSize: 10.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '$jour',
                style: GoogleFonts.inter(
                  color: const Color(0xFF2563EB),
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 2),
              // Point indicateur
              Container(
                width: 4,
                height: 4,
                decoration: const BoxDecoration(
                  color: Color(0xFF2563EB),
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Jour normal non sélectionné
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 2, vertical: 3),
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '$jour',
              style: GoogleFonts.inter(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            // Point sous la date si elle contient une tâche
            Container(
              width: 4,
              height: 4,
              decoration: BoxDecoration(
                color: aDesTaches ? Colors.white : Colors.transparent,
                shape: BoxShape.circle,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCarteTache(TachePlanning tache) {
    // Couleurs adaptées au type de tâche
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

    final sousTitreLieu = tache.lieu ?? '${tache.service} • ${tache.departement}';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          onTap: () async {
            await Navigator.of(context).push<void>(
              MaterialPageRoute(
                builder: (_) => DetailTachePage(
                  tache: tache,
                  onTacheModifiee: (modifiee) {
                    setState(() {});
                  },
                ),
              ),
            );
            setState(() {});
          },
          borderRadius: BorderRadius.circular(18),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Colonne Heure (gauche)
                SizedBox(
                  width: 58,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
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

                // Séparateur vertical discret
                Container(
                  width: 1,
                  height: 40,
                  margin: const EdgeInsets.symmetric(horizontal: 10),
                  color: const Color(0xFFF1F5F9),
                ),

                // Colonne Contenu (droite)
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Badge + Lieu + Point indicateur
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
                              sousTitreLieu,
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
                          // Point coloré à droite comme sur la maquette
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

                      // Titre de la tâche
                      Text(
                        tache.titre,
                        style: GoogleFonts.inter(
                          fontSize: 15,
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

  Widget _buildEtatVide() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: const Color(0xFFEFF6FF),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(
                Icons.event_available_rounded,
                color: Color(0xFF2563EB),
                size: 32,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Aucune tâche pour cette date',
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Appuyez sur le bouton "+" pour ajouter une intervention, une garde ou une séance à votre planning.',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 13,
                color: const Color(0xFF64748B),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
