import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/network/client_api_http.dart';
import '../../../../core/network/configuration_api.dart';
import '../../../../core/network/source_etudiant_distante.dart';
import '../../../../core/services/sse_notifications_service.dart';
import '../../data/datasources/source_planning_mock.dart';
import '../../domain/entities/tache_planning.dart';
import '../widgets/ajouter_tache_modal.dart';
import 'detail_tache_page.dart';

class PlanningPage extends StatefulWidget {
  const PlanningPage({this.dateInitiale, super.key});

  final DateTime? dateInitiale;

  @override
  State<PlanningPage> createState() => _PlanningPageState();
}

class _PlanningPageState extends State<PlanningPage>
    with SingleTickerProviderStateMixin {
  final _source = SourceEtudiantDistante(ClientApiHttp());
  late DateTime _dateSelectionnee;
  late DateTime _moisAffiche;
  late TabController _tabController;

  // Filtres tâches
  bool _voirToutesLesTaches = false;
  String _filtreStatutTaches = 'toutes'; // 'toutes', 'a_venir', 'terminees'

  // Données
  List<TachePlanning> _evenementsDistants = [];
  List<Map<String, dynamic>> _rotationsDistantes = [];
  bool _chargementRotations = false;
  StreamSubscription? _sseSubscription;

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
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (mounted) setState(() {});
    });

    _dateSelectionnee =
        widget.dateInitiale ??
        (ConfigurationApi.utiliserDonneesMockees
            ? DateTime(2026, 9, 16)
            : DateTime.now());
    _moisAffiche = DateTime(_dateSelectionnee.year, _dateSelectionnee.month);
    _chargerDonnees();

    // Écoute SSE des invitations de calendrier en direct
    _sseSubscription = SseNotificationsService.instance.fluxCalendrier.listen((
      evtMap,
    ) {
      final evt = TachePlanning.fromJson(evtMap);
      if (mounted && !_evenementsDistants.any((e) => e.id == evt.id)) {
        setState(() {
          _evenementsDistants.add(evt);
        });
      }
    });
  }

  @override
  void dispose() {
    _sseSubscription?.cancel();
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _chargerDonnees() async {
    setState(() => _chargementRotations = true);
    final evenements = <TachePlanning>[];
    final rotationsList = <Map<String, dynamic>>[];

    try {
      final calendrier = await _source.calendrier();
      evenements.addAll(
        (calendrier['items'] as List? ?? const []).whereType<Map>().map(
          (m) => TachePlanning.fromJson(Map<String, dynamic>.from(m)),
        ),
      );
    } catch (_) {}

    try {
      final stages = await _source.stages();
      for (final stageBrut in (stages['items'] as List? ?? const [])) {
        if (stageBrut is! Map) continue;
        final stage = Map<String, dynamic>.from(stageBrut);
        final hopitalMap = stage['hospital'] as Map?;
        final nomHopital =
            (hopitalMap != null ? hopitalMap['name']?.toString() : null) ??
            stage['hospital_name']?.toString() ??
            '';

        final planningMap = stage['planning'] as Map?;
        final listeRotationsBrutes =
            (planningMap != null && planningMap['rotations'] is List)
            ? planningMap['rotations'] as List
            : (stage['rotations'] as List? ?? const []);

        for (final rotationBrute in listeRotationsBrutes) {
          if (rotationBrute is! Map) continue;
          final rotation = Map<String, dynamic>.from(rotationBrute);
          rotation['hospital_name'] = nomHopital;
          rotationsList.add(rotation);

          // Ajouter aussi les dates de rotations dans le calendrier
          final periodMap = rotation['period'] as Map?;
          final debutStr = periodMap != null
              ? periodMap['start_date']?.toString()
              : rotation['date_debut']?.toString();
          final finStr = periodMap != null
              ? periodMap['end_date']?.toString()
              : rotation['date_fin']?.toString();

          final debut = DateTime.tryParse(debutStr ?? '');
          final fin = DateTime.tryParse(finStr ?? '');
          if (debut != null && fin != null && !fin.isBefore(debut)) {
            for (
              var date = DateTime(debut.year, debut.month, debut.day);
              !date.isAfter(DateTime(fin.year, fin.month, fin.day));
              date = date.add(const Duration(days: 1))
            ) {
              evenements.add(
                TachePlanning.depuisRotationStage(
                  rotation,
                  nomHopital: nomHopital,
                  dateAffichee: date,
                ),
              );
            }
          }
        }
      }
    } catch (_) {}

    // Tri des rotations par séquence ou date de début
    rotationsList.sort((a, b) {
      final seqA = (a['sequence'] as num?)?.toInt() ?? 999;
      final seqB = (b['sequence'] as num?)?.toInt() ?? 999;
      if (seqA != seqB) return seqA.compareTo(seqB);

      final perA = a['period'] as Map?;
      final perB = b['period'] as Map?;
      final startA =
          perA?['start_date']?.toString() ?? a['date_debut']?.toString() ?? '';
      final startB =
          perB?['start_date']?.toString() ?? b['date_debut']?.toString() ?? '';
      return startA.compareTo(startB);
    });

    if (mounted) {
      setState(() {
        _evenementsDistants = evenements;
        _rotationsDistantes = rotationsList;
        _chargementRotations = false;
      });
    }
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

  List<TachePlanning> get _toutesLesTachesCombine {
    if (!ConfigurationApi.utiliserDonneesMockees) {
      return _evenementsDistants;
    }
    return _evenementsDistants.isNotEmpty
        ? _evenementsDistants
        : SourcePlanningMock.toutesLesTaches();
  }

  List<TachePlanning> _tachesPourDate(DateTime date) {
    final list = _toutesLesTachesCombine.where((t) {
      return t.date.year == date.year &&
          t.date.month == date.month &&
          t.date.day == date.day;
    }).toList();

    return _appliquerFiltreStatut(list);
  }

  List<TachePlanning> _appliquerFiltreStatut(List<TachePlanning> list) {
    if (_filtreStatutTaches == 'terminees') {
      return list.where((t) => t.completee).toList();
    } else if (_filtreStatutTaches == 'a_venir') {
      return list.where((t) => !t.completee).toList();
    }
    return list;
  }

  bool _dateContientTaches(DateTime date) {
    return _toutesLesTachesCombine.any((t) {
      return t.date.year == date.year &&
          t.date.month == date.month &&
          t.date.day == date.day;
    });
  }

  bool _dateContientRotation(DateTime date) {
    for (final rot in _rotationsDistantes) {
      final per = rot['period'] as Map?;
      final dStr =
          per?['start_date']?.toString() ?? rot['date_debut']?.toString();
      final fStr = per?['end_date']?.toString() ?? rot['date_fin']?.toString();
      final d = DateTime.tryParse(dStr ?? '');
      final f = DateTime.tryParse(fStr ?? '');
      if (d != null && f != null) {
        final start = DateTime(d.year, d.month, d.day);
        final end = DateTime(f.year, f.month, f.day);
        final target = DateTime(date.year, date.month, date.day);
        if (!target.isBefore(start) && !target.isAfter(end)) {
          return true;
        }
      }
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final tachesFiltrees = _voirToutesLesTaches
        ? _appliquerFiltreStatut(_toutesLesTachesCombine)
        : _tachesPourDate(_dateSelectionnee);

    // Filtrer les rotations pour la date sélectionnée si on ne regarde pas tout
    final rotationsAffichees = _rotationsDistantes.where((rot) {
      if (_voirToutesLesTaches) return true;
      final per = rot['period'] as Map?;
      final dStr =
          per?['start_date']?.toString() ?? rot['date_debut']?.toString();
      final fStr = per?['end_date']?.toString() ?? rot['date_fin']?.toString();
      final d = DateTime.tryParse(dStr ?? '');
      final f = DateTime.tryParse(fStr ?? '');
      if (d == null || f == null) return false;
      final start = DateTime(d.year, d.month, d.day);
      final end = DateTime(f.year, f.month, f.day);
      final cur = DateTime(
        _dateSelectionnee.year,
        _dateSelectionnee.month,
        _dateSelectionnee.day,
      );
      return !cur.isBefore(start) && !cur.isAfter(end);
    }).toList();

    return Scaffold(
      backgroundColor: const Color(0xFF2563EB),
      floatingActionButton: _tabController.index == 0
          ? FloatingActionButton(
              onPressed: () {
                AjouterTacheModal.afficher(
                  context,
                  date: _dateSelectionnee,
                  onAjouter: (nouvelleTache) async {
                    setState(() {
                      _evenementsDistants.add(nouvelleTache);
                      if (ConfigurationApi.utiliserDonneesMockees) {
                        SourcePlanningMock.ajouterTache(nouvelleTache);
                      }
                    });
                    try {
                      await _source.creerEvenementCalendrier(
                        title: nouvelleTache.titre,
                        startsAt: nouvelleTache.date,
                        endsAt: nouvelleTache.date.add(
                          const Duration(minutes: 60),
                        ),
                        participantUserIds:
                            ConfigurationApi.utiliserDonneesMockees
                            ? [101]
                            : const [],
                        type: 'reunion',
                        description: nouvelleTache.description,
                        location: nouvelleTache.lieu,
                      );
                    } catch (_) {}
                  },
                );
              },
              backgroundColor: const Color(0xFF2563EB),
              foregroundColor: Colors.white,
              elevation: 6,
              shape: const CircleBorder(),
              child: const Icon(Icons.add_rounded, size: 28),
            )
          : null,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // 1. En-tête bleu avec titre et sélecteur de mois
            _buildEnTete(context),

            const SizedBox(height: 10),

            // 2. Calendrier interactif sur fond bleu
            _buildCalendrier(),

            const SizedBox(height: 16),

            // 3. Section inférieure blanche/sombre avec TabBar
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF0F172A)
                      : const Color(0xFFF8FAFC),
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(28),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 10,
                      offset: const Offset(0, -3),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // Barre d'onglets (Mes tâches & Mes rotations)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                      child: Container(
                        height: 46,
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: isDark
                              ? const Color(0xFF1E293B)
                              : const Color(0xFFEEF2F6),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: TabBar(
                          controller: _tabController,
                          indicatorSize: TabBarIndicatorSize.tab,
                          indicator: BoxDecoration(
                            color: isDark
                                ? const Color(0xFF2563EB)
                                : Colors.white,
                            borderRadius: BorderRadius.circular(10),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.06),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          labelColor: isDark
                              ? Colors.white
                              : const Color(0xFF2563EB),
                          unselectedLabelColor: isDark
                              ? const Color(0xFF94A3B8)
                              : const Color(0xFF64748B),
                          labelStyle: GoogleFonts.inter(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w700,
                          ),
                          unselectedLabelStyle: GoogleFonts.inter(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w600,
                          ),
                          tabs: [
                            Tab(
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(
                                    Icons.check_circle_outline_rounded,
                                    size: 17,
                                  ),
                                  const SizedBox(width: 6),
                                  Text('Mes tâches (${tachesFiltrees.length})'),
                                ],
                              ),
                            ),
                            Tab(
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.sync_alt_rounded, size: 17),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Mes rotations (${rotationsAffichees.length})',
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Contenu selon l'onglet actif
                    Expanded(
                      child: TabBarView(
                        controller: _tabController,
                        children: [
                          // ONGLET 1 : Mes tâches
                          _buildOngletTaches(tachesFiltrees, isDark),

                          // ONGLET 2 : Mes rotations
                          _buildOngletRotations(rotationsAffichees, isDark),
                        ],
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

  Widget _buildOngletTaches(List<TachePlanning> taches, bool isDark) {
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _voirToutesLesTaches
                          ? 'Toutes les tâches'
                          : 'Tâches du jour (${_dateSelectionnee.day}/${_dateSelectionnee.month})',
                      style: GoogleFonts.inter(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
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
                          _voirToutesLesTaches ? 'Vue du jour' : 'Voir tout',
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
                const SizedBox(height: 10),
                // Chips de filtres pour les tâches
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildFiltreChip(
                        label: 'Toutes',
                        actif: _filtreStatutTaches == 'toutes',
                        onTap: () =>
                            setState(() => _filtreStatutTaches = 'toutes'),
                        isDark: isDark,
                      ),
                      const SizedBox(width: 8),
                      _buildFiltreChip(
                        label: 'À venir',
                        actif: _filtreStatutTaches == 'a_venir',
                        onTap: () =>
                            setState(() => _filtreStatutTaches = 'a_venir'),
                        isDark: isDark,
                      ),
                      const SizedBox(width: 8),
                      _buildFiltreChip(
                        label: 'Faites / Terminées',
                        actif: _filtreStatutTaches == 'terminees',
                        onTap: () =>
                            setState(() => _filtreStatutTaches = 'terminees'),
                        isDark: isDark,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),

        if (taches.isEmpty)
          SliverFillRemaining(
            hasScrollBody: false,
            child: _buildEtatVide(
              titre: 'Aucune tâche trouvée',
              description: _voirToutesLesTaches
                  ? 'Aucune tâche ne correspond à vos filtres actuels.'
                  : 'Aucune tâche pour cette date. Appuyez sur "+" pour en ajouter une.',
              isDark: isDark,
            ),
          )
        else
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 90),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate((context, index) {
                final tache = taches[index];
                return _buildCarteTache(tache, isDark);
              }, childCount: taches.length),
            ),
          ),
      ],
    );
  }

  Widget _buildOngletRotations(
    List<Map<String, dynamic>> rotations,
    bool isDark,
  ) {
    if (_chargementRotations) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFF2563EB)),
      );
    }

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    _voirToutesLesTaches
                        ? 'Toutes les rotations ordonnées'
                        : 'Rotations actives au ${_dateSelectionnee.day}/${_dateSelectionnee.month}',
                    style: GoogleFonts.inter(
                      fontSize: 16.5,
                      fontWeight: FontWeight.w800,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                    ),
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
                      _voirToutesLesTaches ? 'Vue du jour' : 'Voir tout',
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

        if (rotations.isEmpty)
          SliverFillRemaining(
            hasScrollBody: false,
            child: _buildEtatVide(
              titre: 'Aucune rotation pour cette sélection',
              description: _voirToutesLesTaches
                  ? 'Aucune rotation de stage n\'a été trouvée.'
                  : 'Aucune rotation ne couvre cette date. Sélectionnez une autre date sur le calendrier ou appuyez sur "Voir tout".',
              isDark: isDark,
              icone: Icons.sync_disabled_rounded,
            ),
          )
        else
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 90),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate((context, index) {
                final rot = rotations[index];
                return _buildCarteRotation(rot, index + 1, isDark);
              }, childCount: rotations.length),
            ),
          ),
      ],
    );
  }

  Widget _buildFiltreChip({
    required String label,
    required bool actif,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: actif
              ? const Color(0xFF2563EB)
              : (isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0)),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: actif ? FontWeight.w700 : FontWeight.w500,
            color: actif
                ? Colors.white
                : (isDark ? const Color(0xFF94A3B8) : const Color(0xFF475569)),
          ),
        ),
      ),
    );
  }

  Widget _buildCarteRotation(
    Map<String, dynamic> rot,
    int numero,
    bool isDark,
  ) {
    final sequence = rot['sequence'] ?? numero;
    final statut = rot['status']?.toString().toUpperCase() ?? '';

    final periodMap = rot['period'] as Map?;
    final debut = periodMap != null
        ? periodMap['start_date']?.toString()
        : rot['date_debut']?.toString();
    final fin = periodMap != null
        ? periodMap['end_date']?.toString()
        : rot['date_fin']?.toString();

    final serviceMap = rot['service'] as Map?;
    final nomService =
        (serviceMap != null ? serviceMap['name']?.toString() : null) ??
        rot['service_name']?.toString() ??
        '';

    final unitMap = rot['unit'] as Map?;
    final nomUnite = unitMap != null
        ? unitMap['name']?.toString()
        : rot['unit_name']?.toString();

    final supervisorMap = rot['supervisor'] as Map?;
    final nomSuperviseur = supervisorMap != null
        ? supervisorMap['name']?.toString()
        : rot['supervisor_name']?.toString();

    final objectives = rot['objectives']?.toString().trim() ?? '';
    final hopitalNom = rot['hospital_name']?.toString() ?? '';

    final estEnCours = statut == 'ACTIVE' || statut == 'EN_COURS';
    final estTermine = statut == 'TERMINEE' || statut == 'VALIDEE';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: estEnCours
              ? const Color(0xFF2563EB).withValues(alpha: 0.5)
              : (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
          width: estEnCours ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Ligne en-tête avec badge rotation et statut
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF2563EB).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'Rotation #$sequence',
                        style: GoogleFonts.inter(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF2563EB),
                        ),
                      ),
                    ),
                    if (hopitalNom.isNotEmpty) ...[
                      const SizedBox(width: 8),
                      Text(
                        hopitalNom,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: isDark
                              ? const Color(0xFF94A3B8)
                              : const Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: estTermine
                        ? const Color(0xFF16A34A).withValues(alpha: 0.12)
                        : (estEnCours
                              ? const Color(0xFF2563EB).withValues(alpha: 0.12)
                              : (isDark
                                    ? const Color(0xFF334155)
                                    : const Color(0xFFF1F5F9))),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    statut,
                    style: GoogleFonts.inter(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w700,
                      color: estTermine
                          ? const Color(0xFF16A34A)
                          : (estEnCours
                                ? const Color(0xFF2563EB)
                                : (isDark
                                      ? const Color(0xFF94A3B8)
                                      : const Color(0xFF64748B))),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Service et unité
            Text(
              nomService,
              style: GoogleFonts.inter(
                fontSize: 15.5,
                fontWeight: FontWeight.w800,
                color: isDark ? Colors.white : const Color(0xFF0F172A),
              ),
            ),
            if (nomUnite != null && nomUnite.isNotEmpty) ...[
              const SizedBox(height: 2),
              Text(
                'Unité : $nomUnite',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: isDark
                      ? const Color(0xFF94A3B8)
                      : const Color(0xFF64748B),
                ),
              ),
            ],

            if ((debut ?? '').isNotEmpty || (fin ?? '').isNotEmpty) ...[
              const SizedBox(height: 10),
              Row(
                children: [
                  Icon(
                    Icons.calendar_today_rounded,
                    size: 14,
                    color: isDark
                        ? const Color(0xFF94A3B8)
                        : const Color(0xFF64748B),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    [
                      if ((debut ?? '').isNotEmpty) debut!,
                      if ((fin ?? '').isNotEmpty) fin!,
                    ].join(' au '),
                    style: GoogleFonts.inter(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: isDark
                          ? const Color(0xFFCBD5E1)
                          : const Color(0xFF334155),
                    ),
                  ),
                ],
              ),
            ],

            // Superviseur
            if (nomSuperviseur != null && nomSuperviseur.isNotEmpty) ...[
              const SizedBox(height: 6),
              Row(
                children: [
                  Icon(
                    Icons.person_outline_rounded,
                    size: 15,
                    color: isDark
                        ? const Color(0xFF94A3B8)
                        : const Color(0xFF64748B),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Superviseur : $nomSuperviseur',
                    style: GoogleFonts.inter(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w500,
                      color: isDark
                          ? const Color(0xFFCBD5E1)
                          : const Color(0xFF475569),
                    ),
                  ),
                ],
              ),
            ],

            // Objectifs pédagogiques
            if (objectives.isNotEmpty) ...[
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF0F172A)
                      : const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Objectifs clés :',
                      style: GoogleFonts.inter(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        color: isDark
                            ? const Color(0xFF94A3B8)
                            : const Color(0xFF475569),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      objectives,
                      style: GoogleFonts.inter(
                        fontSize: 11.5,
                        color: isDark
                            ? const Color(0xFFCBD5E1)
                            : const Color(0xFF334155),
                      ),
                    ),
                  ],
                ),
              ),
            ],
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
    final premierJourDuMois = DateTime(
      _moisAffiche.year,
      _moisAffiche.month,
      1,
    );
    final dernierJourDuMois = DateTime(
      _moisAffiche.year,
      _moisAffiche.month + 1,
      0,
    );

    final decallage = (premierJourDuMois.weekday - 1);
    final nombreDeJours = dernierJourDuMois.day;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: Column(
        children: [
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

    for (var i = 0; i < decallage; i++) {
      cellules.add(const SizedBox(height: 52));
    }

    for (var jour = 1; jour <= totalJours; jour++) {
      final date = DateTime(_moisAffiche.year, _moisAffiche.month, jour);
      final estSelectionne =
          _dateSelectionnee.year == date.year &&
          _dateSelectionnee.month == date.month &&
          _dateSelectionnee.day == date.day;

      // Points selon l'onglet ou les deux
      final aDesTaches = _dateContientTaches(date);
      final aUneRotation = _dateContientRotation(date);

      cellules.add(
        _buildCelluleJour(
          jour: jour,
          nomJour: _joursSemaine[date.weekday - 1],
          estSelectionne: estSelectionne,
          aDesTaches: aDesTaches,
          aUneRotation: aUneRotation,
          onTap: () => _selectionnerDate(date),
        ),
      );

      if (cellules.length == 7) {
        lignes.add(TableRow(children: cellules));
        cellules = [];
      }
    }

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
    required bool aUneRotation,
    required VoidCallback onTap,
  }) {
    if (estSelectionne) {
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
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 4,
                    height: 4,
                    decoration: const BoxDecoration(
                      color: Color(0xFF2563EB),
                      shape: BoxShape.circle,
                    ),
                  ),
                  if (aUneRotation) ...[
                    const SizedBox(width: 2),
                    Container(
                      width: 4,
                      height: 4,
                      decoration: const BoxDecoration(
                        color: Color(0xFFF59E0B),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      );
    }

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
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (aDesTaches)
                  Container(
                    width: 4,
                    height: 4,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                  ),
                if (aUneRotation) ...[
                  if (aDesTaches) const SizedBox(width: 2),
                  Container(
                    width: 4,
                    height: 4,
                    decoration: const BoxDecoration(
                      color: Color(0xFFFBBF24),
                      shape: BoxShape.circle,
                    ),
                  ),
                ],
                if (!aDesTaches && !aUneRotation)
                  const SizedBox(width: 4, height: 4),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCarteTache(TachePlanning tache, bool isDark) {
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

    if (isDark) {
      fondBadge = fondBadge.withValues(alpha: 0.15);
    }

    final sousTitreLieu =
        tache.lieu ?? '${tache.service} • ${tache.departement}';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
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
                          color: isDark
                              ? Colors.white
                              : const Color(0xFF0F172A),
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
                Container(
                  width: 1,
                  height: 40,
                  margin: const EdgeInsets.symmetric(horizontal: 10),
                  color: isDark
                      ? const Color(0xFF334155)
                      : const Color(0xFFF1F5F9),
                ),
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
                              sousTitreLieu,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: isDark
                                    ? const Color(0xFF94A3B8)
                                    : const Color(0xFF64748B),
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
                        style: GoogleFonts.inter(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: isDark
                              ? Colors.white
                              : const Color(0xFF0F172A),
                          decoration: tache.completee
                              ? TextDecoration.lineThrough
                              : null,
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

  Widget _buildEtatVide({
    required String titre,
    required String description,
    required bool isDark,
    IconData icone = Icons.event_available_rounded,
  }) {
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
                color: isDark
                    ? const Color(0xFF1E293B)
                    : const Color(0xFFEFF6FF),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(icone, color: const Color(0xFF2563EB), size: 32),
            ),
            const SizedBox(height: 16),
            Text(
              titre,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white : const Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              description,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 13,
                color: isDark
                    ? const Color(0xFF94A3B8)
                    : const Color(0xFF64748B),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
