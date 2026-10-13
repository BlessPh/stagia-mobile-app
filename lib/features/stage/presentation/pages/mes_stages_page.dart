import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';
import '../../../../core/mocks/depot_mock_etudiant.dart';
import '../../../../core/mocks/scenario_etudiant_ui.dart';
import '../../../../core/network/client_api_http.dart';
import '../../../../core/network/configuration_api.dart';
import '../../../../core/network/source_etudiant_distante.dart';
import '../../../../core/services/suivi_stage_service.dart';
import '../../../journal/presentation/pages/journal_page.dart';
import '../../../messagerie/presentation/pages/messagerie_page.dart';
import '../../../notifications/presentation/pages/notifications_page.dart';
import '../../data/datasources/source_stage_distante.dart';
import '../../data/datasources/source_campagne_mock.dart';
import '../../data/mappers/mappeur_campagne_stage_api.dart';
import '../../data/mappers/mappeur_affectation_stage_api.dart';
import '../../domain/entities/campagne_stage.dart';
import '../../domain/entities/suivi_candidature_stage.dart';
import '../../../home/presentation/widgets/section_stage_en_cours_accueil.dart';
import '../routes/routes_stage.dart';
import 'detail_campagne_page.dart';
import 'mon_stage_page.dart';
import '../widgets/barre_recherche_stages.dart';
import '../widgets/carte_candidature_moderne.dart';
import '../widgets/carte_stage_explorer.dart';
import '../widgets/onglets_trois_stages.dart';

import 'dart:async';
import '../../../../core/services/sse_notifications_service.dart';

class MesStagesPage extends StatefulWidget {
  const MesStagesPage({super.key});

  @override
  State<MesStagesPage> createState() => _MesStagesPageState();
}

class _MesStagesPageState extends State<MesStagesPage> {
  final _sourceEtudiant = SourceEtudiantDistante(ClientApiHttp());
  final _sourceStages = SourceStageDistante(ClientApiHttp());

  int _ongletActif = 0;
  final TextEditingController _rechercheController = TextEditingController();
  String _filtreCategorie = 'Tous';
  String _filtreCandidature = 'Toutes';

  late Future<List<Map<String, dynamic>>> _chargement;
  Map<String, dynamic>? _counts;
  StreamSubscription? _sseSubscription;

  @override
  void initState() {
    super.initState();
    _chargement = _charger();
    _chargerCounts();
    _sseSubscription = SseNotificationsService.instance.fluxCompteurs.listen((
      counts,
    ) {
      if (mounted) setState(() => _counts = counts);
    });
    if (ConfigurationApi.utiliserDonneesMockees) {
      DepotMockEtudiant.changements.addListener(_onChangementDonnees);
      ScenarioEtudiantUi.changements.addListener(_onChangementDonnees);
    }
    SuiviStageService.ongletStagesDemande.addListener(_ouvrirOngletDemande);
    _ouvrirOngletDemande();
  }

  Future<void> _chargerCounts() async {
    try {
      final res = await _sourceEtudiant.notificationCounts();
      if (mounted) {
        setState(() => _counts = res);
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _sseSubscription?.cancel();
    if (ConfigurationApi.utiliserDonneesMockees) {
      DepotMockEtudiant.changements.removeListener(_onChangementDonnees);
      ScenarioEtudiantUi.changements.removeListener(_onChangementDonnees);
    }
    SuiviStageService.ongletStagesDemande.removeListener(_ouvrirOngletDemande);
    _rechercheController.dispose();
    super.dispose();
  }

  void _onChangementDonnees() {
    if (mounted) {
      setState(() {
        _chargement = _charger();
      });
    }
  }

  void _ouvrirOngletDemande() {
    final index = SuiviStageService.ongletStagesDemande.value;
    if (index == null || index < 0 || index > 2) return;
    if (mounted && _ongletActif != index) {
      setState(() => _ongletActif = index);
    }
  }

  Future<List<Map<String, dynamic>>> _charger() => Future.wait([
    _sourceEtudiant.stages(),
    _sourceStages.campagnes(),
    _sourceEtudiant.candidatures().catchError((_) => <String, dynamic>{}),
    _sourceEtudiant.admissions().catchError((_) => <String, dynamic>{}),
    _sourceEtudiant.reservations().catchError((_) => <String, dynamic>{}),
  ]);

  Future<void> _actualiser() async {
    final futur = _charger();
    setState(() => _chargement = futur);
    await futur;
  }

  @override
  Widget build(BuildContext context) {
    final modeSombre = Theme.of(context).brightness == Brightness.dark;
    final couleurFondPage = modeSombre
        ? const Color(0xFF0F172A)
        : const Color(0xFFF8FAFC);
    final separateurCouleur = modeSombre
        ? const Color(0xFF334155)
        : const Color(0xFFE2E8F0);

    return Scaffold(
      backgroundColor: couleurFondPage,
      appBar: _buildAppBar(context, modeSombre),
      body: SafeArea(
        child: Column(
          children: [
            // Barre de recherche
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              child: BarreRechercheStages(
                controller: _rechercheController,
                onChanged: (_) => setState(() {}),
              ),
            ),

            // TabBar à 3 onglets (En cours, Explorer, Candidatures)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: OngletsTroisStages(
                indexActif: _ongletActif,
                onChangementOnglet: (index) {
                  setState(() => _ongletActif = index);
                },
              ),
            ),
            Divider(height: 1, color: separateurCouleur),

            // Corps principal selon l'onglet
            Expanded(
              child: FutureBuilder<List<Map<String, dynamic>>>(
                future: _chargement,
                builder: (context, snapshot) {
                  final donneesStages = snapshot.data?.isNotEmpty == true
                      ? snapshot.data![0]
                      : const <String, dynamic>{};
                  final donneesCampagnes =
                      snapshot.data != null && snapshot.data!.length > 1
                      ? snapshot.data![1]
                      : const <String, dynamic>{};
                  final donneesCandidatures =
                      snapshot.data != null && snapshot.data!.length > 2
                      ? snapshot.data![2]
                      : const <String, dynamic>{};
                  final donneesAdmissions =
                      snapshot.data != null && snapshot.data!.length > 3
                      ? snapshot.data![3]
                      : const <String, dynamic>{};
                  final donneesReservations =
                      snapshot.data != null && snapshot.data!.length > 4
                      ? snapshot.data![4]
                      : const <String, dynamic>{};

                  final stagesListe =
                      (donneesStages['items'] as List?)
                          ?.whereType<Map>()
                          .map(Map<String, dynamic>.from)
                          .toList() ??
                      [];
                  Map<String, dynamic>? stageActif;
                  for (final stage in stagesListe) {
                    if (MappeurAffectationStageApi.estActive(stage)) {
                      stageActif = stage;
                      break;
                    }
                  }

                  return RefreshIndicator(
                    color: const Color(0xFF1D61F2),
                    onRefresh: _actualiser,
                    child: switch (_ongletActif) {
                      0 => _buildOngletEnCours(stageActif, modeSombre),
                      1 => _buildOngletExplorer(donneesCampagnes, modeSombre),
                      2 => _buildOngletCandidatures(
                        donneesCandidatures,
                        donneesAdmissions,
                        donneesReservations,
                        donneesCampagnes,
                        modeSombre,
                      ),
                      _ => const SizedBox.shrink(),
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context, bool modeSombre) {
    final couleurTexte = modeSombre ? Colors.white : const Color(0xFF0F172A);
    final couleurIcone = modeSombre
        ? const Color(0xFFE2E8F0)
        : const Color(0xFF0F172A);
    final couleurFond = modeSombre
        ? const Color(0xFF0F172A)
        : const Color(0xFFF8FAFC);

    final unreadMsgs =
        int.tryParse(_counts?['messages']?.toString() ?? '0') ?? 0;
    final unreadNotifs =
        int.tryParse(_counts?['notifications']?.toString() ?? '0') ?? 0;

    return AppBar(
      automaticallyImplyLeading: false,
      backgroundColor: couleurFond,
      elevation: 0,
      surfaceTintColor: Colors.transparent,
      title: Text(
        'Mes stages',
        style: GoogleFonts.inter(
          fontSize: 22,
          fontWeight: FontWeight.w800,
          color: couleurTexte,
          letterSpacing: -0.3,
        ),
      ),
      actions: [
        // Bouton Chat avec badge dynamique
        Stack(
          clipBehavior: Clip.none,
          children: [
            IconButton(
              tooltip: 'Messages',
              onPressed: () async {
                await Navigator.of(context, rootNavigator: true).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const MessageriePage(),
                  ),
                );
                _chargerCounts();
              },
              icon: Icon(Iconsax.message, color: couleurIcone, size: 24),
            ),
            if (unreadMsgs > 0)
              Positioned(
                top: 8,
                right: 6,
                child: Container(
                  padding: const EdgeInsets.all(3),
                  decoration: const BoxDecoration(
                    color: Color(0xFFEF4444),
                    shape: BoxShape.circle,
                  ),
                  constraints: const BoxConstraints(
                    minWidth: 16,
                    minHeight: 16,
                  ),
                  child: Text(
                    '$unreadMsgs',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 9.5,
                      fontWeight: FontWeight.w800,
                      height: 1,
                    ),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(width: 4),

        // Bouton Notifications avec badge dynamique
        Stack(
          clipBehavior: Clip.none,
          children: [
            IconButton(
              tooltip: 'Notifications',
              onPressed: () async {
                await Navigator.of(context, rootNavigator: true).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const NotificationsPage(),
                  ),
                );
                _chargerCounts();
              },
              icon: Icon(CupertinoIcons.bell, color: couleurIcone, size: 25),
            ),
            if (unreadNotifs > 0)
              Positioned(
                top: 8,
                right: 6,
                child: Container(
                  padding: const EdgeInsets.all(3),
                  decoration: const BoxDecoration(
                    color: Color(0xFFEF4444),
                    shape: BoxShape.circle,
                  ),
                  constraints: const BoxConstraints(
                    minWidth: 16,
                    minHeight: 16,
                  ),
                  child: Text(
                    '$unreadNotifs',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 9.5,
                      fontWeight: FontWeight.w800,
                      height: 1,
                    ),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  // ==========================================
  // ONGLET 1 : EN COURS (Fidèle à l'Image 2)
  // ==========================================
  Widget _buildOngletEnCours(Map<String, dynamic>? stage, bool modeSombre) {
    final couleurCarte = modeSombre ? const Color(0xFF1E293B) : Colors.white;
    final couleurBordure = modeSombre
        ? const Color(0xFF334155)
        : const Color(0xFFE2E8F0);
    final textePrincipal = modeSombre ? Colors.white : const Color(0xFF0F172A);
    final texteSecondaire = modeSombre
        ? const Color(0xFF94A3B8)
        : const Color(0xFF64748B);

    if (stage == null) {
      return LayoutBuilder(
        builder: (context, constraints) => SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        color: modeSombre
                            ? const Color(0xFF1E293B)
                            : const Color(0xFFF1F5F9),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Iconsax.briefcase,
                        size: 30,
                        color: modeSombre
                            ? const Color(0xFF64748B)
                            : const Color(0xFF94A3B8),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      "Vous n'avez aucun stage en cours.",
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: texteSecondaire,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    }

    // Extraction enrichie selon GET /api/v1/student/stages
    final hospital = stage['hospital'] is Map
        ? stage['hospital'] as Map
        : const {};
    final department = stage['department'] is Map
        ? stage['department'] as Map
        : const {};
    final campaign = stage['campaign'] is Map
        ? stage['campaign'] as Map
        : const {};
    final period = stage['period'] is Map ? stage['period'] as Map : const {};
    final planning = stage['planning'] is Map
        ? stage['planning'] as Map
        : const {};
    final rotationsList =
        (planning['rotations'] as List? ?? stage['rotations'] as List? ?? [])
            .whereType<Map>()
            .map(Map<String, dynamic>.from)
            .toList();
    final currentRotation = planning['current_rotation'] is Map
        ? Map<String, dynamic>.from(planning['current_rotation'] as Map)
        : null;
    final departmentIntegrity = stage['department_integrity'] is Map
        ? Map<String, dynamic>.from(stage['department_integrity'] as Map)
        : const <String, dynamic>{};
    final anomalieIntegrite =
        departmentIntegrity['valid'] == false ||
        rotationsList.any(
          (rotation) =>
              rotation['integrity'] is Map &&
              (rotation['integrity'] as Map)['valid'] == false,
        );

    final titreCampagne =
        (campaign['title'] ?? stage['campaign_title'] ?? stage['titre'])
            ?.toString() ??
        '';
    final nomHopital =
        (hospital['name'] ?? stage['hospital_name'])?.toString() ?? '';
    final nomDepartement =
        (department['name'] ?? stage['department_name'])?.toString() ?? '';

    // Service de la rotation active
    final serviceMap =
        currentRotation != null && currentRotation['service'] is Map
        ? currentRotation['service'] as Map
        : const {};
    final unitMap = currentRotation != null && currentRotation['unit'] is Map
        ? currentRotation['unit'] as Map
        : const {};
    final nomService =
        (serviceMap['name'] ?? currentRotation?['service_name'])?.toString() ??
        '';
    final nomUnite = unitMap['name']?.toString();

    // Superviseur
    final supervisorMap =
        currentRotation != null && currentRotation['supervisor'] is Map
        ? currentRotation['supervisor'] as Map
        : const {};
    final nomEncadreur =
        (supervisorMap['name'] ?? currentRotation?['supervisor_name'])
            ?.toString() ??
        '';
    final fonctionEncadreur =
        (supervisorMap['function'] ?? currentRotation?['supervisor_function'])
            ?.toString() ??
        '';

    // Dates
    final dateDebutStr = (period['start_date'] ?? stage['date_debut'])
        ?.toString();
    final dateFinStr = (period['end_date'] ?? stage['date_fin'])?.toString();
    final dateDebut = DateTime.tryParse(dateDebutStr ?? '');
    final dateFin = DateTime.tryParse(dateFinStr ?? '');
    final totalJours = dateDebut != null && dateFin != null
        ? dateFin.difference(dateDebut).inDays.abs() + 1
        : 0;
    final joursEffectues = dateDebut != null
        ? DateTime.now().difference(dateDebut).inDays.clamp(0, totalJours)
        : 0;

    // Rotations et jours restants dans le service
    final totalRotations = planning['total'] is int
        ? planning['total'] as int
        : rotationsList.length;
    final rotationsEffectuees = rotationsList
        .where((r) => r['status'] == 'TERMINEE')
        .length;

    final rotFinStr =
        (currentRotation?['period'] is Map
                ? currentRotation!['period']['end_date']
                : currentRotation?['date_fin'])
            ?.toString();
    final rotFin = DateTime.tryParse(rotFinStr ?? '');
    final joursRestantsService = rotFin != null
        ? rotFin.difference(DateTime.now()).inDays.clamp(0, 999)
        : (totalJours - joursEffectues).clamp(0, 999);

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
      children: [
        // Composant d'accueil réutilisé fidèlement
        SectionStageEnCoursAccueil(
          titreCampagne: titreCampagne,
          nomEtablissement: nomHopital,
          joursEffectues: joursEffectues,
          totalJours: totalJours,
          servicesEffectues: rotationsEffectuees,
          totalServices: totalRotations,
          serviceActuel: [
            nomService,
            if (nomUnite != null && nomUnite.isNotEmpty) nomUnite,
          ].where((valeur) => valeur.isNotEmpty).join(' • '),
          joursRestantsService: joursRestantsService,
          nomEncadreur: nomEncadreur,
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => MonStagePage(
                assignmentReference: stage['assignment_uuid']?.toString(),
              ),
            ),
          ),
        ),

        const SizedBox(height: 18),

        // Détails supplémentaires des rotations ordonnées (GET /api/v1/student/stages)
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: couleurCarte,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: couleurBordure),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Rotations planifiées ($totalRotations)',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: textePrincipal,
                    ),
                  ),
                  if (anomalieIntegrite)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: modeSombre
                            ? const Color(0xFF7F1D1D).withValues(alpha: 0.45)
                            : const Color(0xFFFEF2F2),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'Anomalie signalée',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: modeSombre
                              ? const Color(0xFFFCA5A5)
                              : const Color(0xFFDC2626),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              if (rotationsList.isEmpty)
                Text(
                  'Aucune rotation enregistrée pour ce stage.',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: texteSecondaire,
                  ),
                )
              else
                ...rotationsList.map((rot) {
                  final rotPeriod = rot['period'] is Map
                      ? rot['period'] as Map
                      : const {};
                  final rService = rot['service'] is Map
                      ? rot['service'] as Map
                      : const {};
                  final rUnit = rot['unit'] is Map
                      ? rot['unit'] as Map
                      : const {};
                  final rSup = rot['supervisor'] is Map
                      ? rot['supervisor'] as Map
                      : const {};
                  final nomR =
                      (rService['name'] ?? rot['service_name'])?.toString() ??
                      '';
                  final uniteR = rUnit['name']?.toString();
                  final statutR =
                      (rot['status'] ?? rot['statut'])
                          ?.toString()
                          .toUpperCase() ??
                      '';
                  final estActif = statutR == 'ACTIVE' || statutR == 'EN_COURS';
                  final estTermine = statutR == 'TERMINEE';
                  final estAnnule = statutR == 'ANNULEE';
                  final debR =
                      rotPeriod['start_date'] ?? rot['date_debut'] ?? '';
                  final finR = rotPeriod['end_date'] ?? rot['date_fin'] ?? '';

                  return Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: estActif
                          ? (modeSombre
                                ? const Color(0xFF1E3A8A).withValues(alpha: 0.3)
                                : const Color(0xFFEFF6FF))
                          : (modeSombre
                                ? const Color(0xFF0F172A)
                                : const Color(0xFFF8FAFC)),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: estActif
                            ? const Color(0xFF3B82F6)
                            : (modeSombre
                                  ? const Color(0xFF334155)
                                  : const Color(0xFFE2E8F0)),
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: estActif
                                ? const Color(0xFF2563EB)
                                : (estTermine
                                      ? const Color(0xFF16A34A)
                                      : (modeSombre
                                            ? const Color(0xFF334155)
                                            : const Color(0xFFCBD5E1))),
                            shape: BoxShape.circle,
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            '${rot['sequence'] ?? rot['position'] ?? rotationsList.indexOf(rot) + 1}',
                            style: GoogleFonts.inter(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                uniteR != null ? '$nomR • $uniteR' : nomR,
                                style: GoogleFonts.inter(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: textePrincipal,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                'Du $debR au $finR',
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  color: texteSecondaire,
                                ),
                              ),
                              if (rSup['name'] != null ||
                                  rot['supervisor_name'] != null) ...[
                                const SizedBox(height: 3),
                                Text(
                                  'Encadreur : ${rSup['name'] ?? rot['supervisor_name']}',
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    color: const Color(0xFF3B82F6),
                                  ),
                                ),
                              ],
                              if (rot['objectives'] != null &&
                                  rot['objectives'].toString().isNotEmpty) ...[
                                const SizedBox(height: 4),
                                Text(
                                  'Objectif : ${rot['objectives']}',
                                  style: GoogleFonts.inter(
                                    fontSize: 11.5,
                                    fontStyle: FontStyle.italic,
                                    color: texteSecondaire,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: estActif
                                ? (modeSombre
                                      ? const Color(
                                          0xFF14532D,
                                        ).withValues(alpha: 0.65)
                                      : const Color(0xFFDCFCE7))
                                : (estTermine
                                      ? (modeSombre
                                            ? const Color(0xFF334155)
                                            : const Color(0xFFF1F5F9))
                                      : (modeSombre
                                            ? const Color(
                                                0xFF78350F,
                                              ).withValues(alpha: 0.65)
                                            : const Color(0xFFFEF3C7))),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            estActif
                                ? 'En cours'
                                : estTermine
                                ? 'Terminée'
                                : estAnnule
                                ? 'Annulée'
                                : 'Planifiée',
                            style: GoogleFonts.inter(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w700,
                              color: estActif
                                  ? (modeSombre
                                        ? const Color(0xFF4ADE80)
                                        : const Color(0xFF16A34A))
                                  : (estTermine
                                        ? (modeSombre
                                              ? const Color(0xFFCBD5E1)
                                              : const Color(0xFF64748B))
                                        : (modeSombre
                                              ? const Color(0xFFFBBF24)
                                              : const Color(0xFFD97706))),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // Détails Superviseur, Hôpital et Département
        Row(
          children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: couleurCarte,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: couleurBordure),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Superviseur',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: const Color(0xFF94A3B8),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      nomEncadreur,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: textePrincipal,
                      ),
                    ),
                    Text(
                      fonctionEncadreur,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                        fontSize: 11.5,
                        color: texteSecondaire,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: couleurCarte,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: couleurBordure),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Département',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: const Color(0xFF94A3B8),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      nomDepartement,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: textePrincipal,
                      ),
                    ),
                    Text(
                      nomHopital,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                        fontSize: 11.5,
                        color: texteSecondaire,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 22),

        // Titre Outils de suivi
        Text(
          'Outils de suivi',
          style: GoogleFonts.inter(
            fontSize: 17,
            fontWeight: FontWeight.w800,
            color: textePrincipal,
          ),
        ),

        const SizedBox(height: 12),

        // 3 boutons d'outils : Journal de bord, Rapport, Évaluations
        Row(
          children: [
            Expanded(
              child: _buildCarteOutilSuivi(
                icone: CupertinoIcons.book,
                couleurIcone: const Color(0xFF1D61F2),
                titre: 'Journal de bord',
                modeSombre: modeSombre,
                onTap: () => Navigator.of(context, rootNavigator: true).push(
                  MaterialPageRoute<void>(builder: (_) => const JournalPage()),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildCarteOutilSuivi(
                icone: CupertinoIcons.doc_text,
                couleurIcone: const Color(0xFF1D61F2),
                titre: 'Rapport',
                modeSombre: modeSombre,
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Module Rapports disponible prochainement'),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildCarteOutilSuivi(
                icone: CupertinoIcons.star,
                couleurIcone: const Color(0xFF1D61F2),
                titre: 'Évaluations',
                modeSombre: modeSombre,
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Module Évaluations disponible prochainement',
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCarteOutilSuivi({
    required IconData icone,
    required Color couleurIcone,
    required String titre,
    required bool modeSombre,
    required VoidCallback onTap,
  }) {
    final couleurCarte = modeSombre ? const Color(0xFF1E293B) : Colors.white;
    final couleurBordure = modeSombre
        ? const Color(0xFF334155)
        : const Color(0xFFE2E8F0);
    final textePrincipal = modeSombre ? Colors.white : const Color(0xFF0F172A);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          height: 90,
          decoration: BoxDecoration(
            color: couleurCarte,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: couleurBordure),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icone, color: couleurIcone, size: 24),
              const SizedBox(height: 6),
              Text(
                titre,
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: textePrincipal,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ==========================================
  // ONGLET 2 : EXPLORER (Fidèle à l'Image 3)
  // ==========================================
  Widget _buildOngletExplorer(
    Map<String, dynamic> campagnesData,
    bool modeSombre,
  ) {
    final campaignsApi =
        (campagnesData['campaigns'] as List?)
            ?.whereType<Map>()
            .map(Map<String, dynamic>.from)
            .toList() ??
        [];

    final texteSecondaire = modeSombre
        ? const Color(0xFF94A3B8)
        : const Color(0xFF64748B);

    if (campaignsApi.isEmpty && !ConfigurationApi.utiliserDonneesMockees) {
      return LayoutBuilder(
        builder: (context, constraints) => SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        color: modeSombre
                            ? const Color(0xFF1E293B)
                            : const Color(0xFFF1F5F9),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Iconsax.search_normal,
                        size: 30,
                        color: modeSombre
                            ? const Color(0xFF64748B)
                            : const Color(0xFF94A3B8),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Aucune campagne de stage disponible.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: texteSecondaire,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    }

    final List<Map<String, dynamic>> listeStagesExplorer =
        campaignsApi.isNotEmpty
        ? campaignsApi.map((c) {
            final titre = c['title']?.toString() ?? '';
            final programme = c['program']?.toString() ?? '';
            final stageType = c['stage_type'] is Map
                ? Map<String, dynamic>.from(c['stage_type'] as Map)
                : const <String, dynamic>{};
            final dateFin = c['end_date']?.toString() ?? '';
            final hopitaux =
                (c['hospitals'] as List?)?.whereType<Map>().toList() ?? [];
            final hopitauxDisponibles = hopitaux.where((item) {
              final disponible = item['available'];
              final places = item['available_places'];
              final nombrePlaces = places is num
                  ? places.toInt()
                  : int.tryParse(places?.toString() ?? '') ?? 0;
              return disponible == true && nombrePlaces > 0;
            }).toList();
            final mode = c['mode'] is Map
                ? Map<String, dynamic>.from(c['mode'] as Map)
                : const <String, dynamic>{};
            final autoriseReservationAutonome =
                mode['self_reservation_allowed'] != false;
            final totalPlaces = hopitauxDisponibles.fold<int>(0, (total, item) {
              final valeur = item['available_places'];
              return total +
                  (valeur is num
                      ? valeur.toInt()
                      : int.tryParse(valeur?.toString() ?? '') ?? 0);
            });
            final nbPlaces = totalPlaces > 0
                ? '$totalPlaces places'
                : 'Complet';
            final premierHopital = hopitauxDisponibles.isNotEmpty
                ? (hopitauxDisponibles.first['hospital'] is Map
                      ? hopitauxDisponibles.first['hospital']['name']
                            ?.toString()
                      : null)
                : null;
            final entreprise = premierHopital ?? '';
            final ville =
                hopitauxDisponibles.isNotEmpty &&
                    hopitauxDisponibles.first['hospital'] is Map
                ? (hopitauxDisponibles.first['hospital']['city']?.toString() ??
                      '')
                : '';

            return {
              'initiale': entreprise.isNotEmpty
                  ? entreprise[0].toUpperCase()
                  : '?',
              'bg': const Color(0xFFDCFCE7),
              'textColor': const Color(0xFF16A34A),
              'entreprise': entreprise,
              'ville': ville,
              'titre': titre,
              'domaine': programme,
              'duree': nbPlaces,
              'dateLimite': dateFin,
              'categorie': stageType['label']?.toString() ?? programme,
              'libelleAction': autoriseReservationAutonome && totalPlaces > 0
                  ? 'Postuler'
                  : 'Voir détails',
              'campagneJson': c,
            };
          }).toList()
        : [
            {
              'initiale': 'V',
              'bg': const Color(0xFFE0F2FE),
              'textColor': const Color(0xFF0284C7),
              'entreprise': 'Vodacom RDC',
              'ville': 'Lubumbashi',
              'titre': 'Stage en Analyse de Données',
              'domaine': 'Data Science',
              'duree': '3 mois',
              'dateLimite': '15 Oct 2026',
              'categorie': 'Informatique',
            },
            {
              'initiale': 'R',
              'bg': const Color(0xFFF3E8FF),
              'textColor': const Color(0xFF7E22CE),
              'entreprise': 'Rawbank',
              'ville': 'Kinshasa',
              'titre': 'Stage en Développement Mobile',
              'domaine': 'Dév Mobile',
              'duree': '6 mois',
              'dateLimite': '30 Oct 2026',
              'categorie': 'Informatique',
            },
            {
              'initiale': 'G',
              'bg': const Color(0xFFFFE4E6),
              'textColor': const Color(0xFFE11D48),
              'entreprise': 'Glencore Kamoto',
              'ville': 'Kolwezi',
              'titre': 'Stage en Ingénierie Réseau',
              'domaine': 'Réseaux',
              'duree': '4 mois',
              'dateLimite': '20 Nov 2026',
              'categorie': 'Informatique',
            },
            {
              'initiale': 'C',
              'bg': const Color(0xFFDCFCE7),
              'textColor': const Color(0xFF16A34A),
              'entreprise': 'Cliniques Universitaires',
              'ville': 'Kinshasa',
              'titre': 'Stage Clinique en Chirurgie',
              'domaine': 'Santé',
              'duree': '3 mois',
              'dateLimite': '01 Nov 2026',
              'categorie': 'Santé',
            },
            {
              'initiale': 'E',
              'bg': const Color(0xFFE0E7FF),
              'textColor': const Color(0xFF4338CA),
              'entreprise': 'Equity BCDC',
              'ville': 'Kinshasa',
              'titre': 'Stage en Analyse Financière',
              'domaine': 'Finance',
              'duree': '6 mois',
              'dateLimite': '15 Nov 2026',
              'categorie': 'Finance',
            },
          ];

    final query = _rechercheController.text.trim().toLowerCase();
    final filtres = listeStagesExplorer.where((item) {
      final matchFiltre =
          _filtreCategorie == 'Tous' || item['categorie'] == _filtreCategorie;
      final matchRecherche =
          query.isEmpty ||
          (item['entreprise'] as String).toLowerCase().contains(query) ||
          (item['titre'] as String).toLowerCase().contains(query) ||
          (item['ville'] as String).toLowerCase().contains(query);
      return matchFiltre && matchRecherche;
    }).toList();

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 28),
      children: [
        // Ligne de filtres horizontaux
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _buildFiltreChip(
                titre: 'Tous',
                actif: _filtreCategorie == 'Tous',
                modeSombre: modeSombre,
              ),
              const SizedBox(width: 8),
              _buildFiltreChip(
                titre: 'Informatique',
                actif: _filtreCategorie == 'Informatique',
                modeSombre: modeSombre,
              ),
              const SizedBox(width: 8),
              _buildFiltreChip(
                titre: 'Finance',
                actif: _filtreCategorie == 'Finance',
                modeSombre: modeSombre,
              ),
              const SizedBox(width: 8),
              _buildFiltreChip(
                titre: 'Santé',
                actif: _filtreCategorie == 'Santé',
                modeSombre: modeSombre,
              ),
              const SizedBox(width: 8),
              // Bouton sliders / réglages
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: modeSombre ? const Color(0xFF1E293B) : Colors.white,
                  borderRadius: BorderRadius.circular(19),
                  border: Border.all(
                    color: modeSombre
                        ? const Color(0xFF334155)
                        : const Color(0xFFE2E8F0),
                  ),
                ),
                alignment: Alignment.center,
                child: Icon(
                  CupertinoIcons.slider_horizontal_3,
                  size: 18,
                  color: modeSombre ? Colors.white : const Color(0xFF0F172A),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // Cartes des opportunités
        if (filtres.isEmpty)
          Center(
            child: Padding(
              padding: const EdgeInsets.all(32.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: modeSombre
                          ? const Color(0xFF1E293B)
                          : const Color(0xFFF1F5F9),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Iconsax.search_status,
                      size: 26,
                      color: modeSombre
                          ? const Color(0xFF64748B)
                          : const Color(0xFF94A3B8),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Aucun stage ne correspond à vos critères.',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: texteSecondaire,
                    ),
                  ),
                ],
              ),
            ),
          )
        else
          for (final item in filtres)
            Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: CarteStageExplorer(
                initiale: item['initiale'] as String,
                couleurFondInitiale: item['bg'] as Color,
                couleurTexteInitiale: item['textColor'] as Color,
                nomEntreprise: item['entreprise'] as String,
                ville: item['ville'] as String,
                titrePoste: item['titre'] as String,
                domaineTag: item['domaine'] as String,
                dureeTag: item['duree'] as String,
                dateLimite: item['dateLimite'] as String,
                libelleAction: item['libelleAction']?.toString() ?? 'Postuler',
                onPostuler: () {
                  final jsonCampagne = item['campagneJson'];
                  final campagneObj = jsonCampagne is Map<String, dynamic>
                      ? MappeurCampagneStageApi.depuisJson(jsonCampagne)
                      : null;
                  Navigator.of(context).pushNamed(
                    RoutesStage.detailCampagne,
                    arguments: campagneObj,
                  );
                },
              ),
            ),
      ],
    );
  }

  Widget _buildFiltreChip({
    required String titre,
    required bool actif,
    required bool modeSombre,
  }) {
    final couleurFond = actif
        ? const Color(0xFF1D61F2)
        : (modeSombre ? const Color(0xFF1E293B) : Colors.white);
    final couleurBordure = actif
        ? const Color(0xFF1D61F2)
        : (modeSombre ? const Color(0xFF334155) : const Color(0xFFE2E8F0));
    final couleurTexte = actif
        ? Colors.white
        : (modeSombre ? const Color(0xFF94A3B8) : const Color(0xFF64748B));

    return GestureDetector(
      onTap: () => setState(() => _filtreCategorie = titre),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8.5),
        decoration: BoxDecoration(
          color: couleurFond,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: couleurBordure),
        ),
        child: Text(
          titre,
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: actif ? FontWeight.w700 : FontWeight.w500,
            color: couleurTexte,
          ),
        ),
      ),
    );
  }

  // ==========================================
  // ONGLET 3 : CANDIDATURES (Fidèle à l'Image 4)
  // ==========================================
  Widget _buildOngletCandidatures(
    Map<String, dynamic> candidaturesData,
    Map<String, dynamic> admissionsData,
    Map<String, dynamic> reservationsData,
    Map<String, dynamic> campagnesData,
    bool modeSombre,
  ) {
    final candidaturesRaw =
        (candidaturesData['items'] as List?)
            ?.whereType<Map>()
            .map(Map<String, dynamic>.from)
            .toList() ??
        [];
    final admissionsRaw =
        (admissionsData['items'] as List?)
            ?.whereType<Map>()
            .map(Map<String, dynamic>.from)
            .toList() ??
        [];
    final reservationsRaw =
        (reservationsData['items'] as List?)
            ?.whereType<Map>()
            .map(Map<String, dynamic>.from)
            .toList() ??
        [];

    // Fusion intelligente : candidatures officielles priorisées, complétées par les admissions/réservations
    final List<Map<String, dynamic>> itemsRaw = [...candidaturesRaw];
    final uuidsConnus = <String>{
      for (final c in candidaturesRaw)
        if (c['uuid'] != null) c['uuid'].toString(),
      for (final c in candidaturesRaw)
        if (c['reservation_uuid'] != null) c['reservation_uuid'].toString(),
    };

    // Ajouter les réservations temporaires ou actives qui ne sont pas déjà dans itemsRaw
    for (final res in reservationsRaw) {
      final resUuid =
          (res['reservation'] is Map ? res['reservation']['uuid'] : res['uuid'])
              ?.toString();
      final appUuid =
          (res['application'] is Map
                  ? res['application']['uuid']
                  : res['application_uuid'])
              ?.toString();
      if ((resUuid != null && uuidsConnus.contains(resUuid)) ||
          (appUuid != null && uuidsConnus.contains(appUuid))) {
        continue;
      }
      itemsRaw.add(res);
      if (resUuid != null) uuidsConnus.add(resUuid);
      if (appUuid != null) uuidsConnus.add(appUuid);
    }

    // Ajouter les éventuelles admissions
    for (final adm in admissionsRaw) {
      final admUuid = (adm['uuid'] ?? adm['admission_uuid'])?.toString();
      if (admUuid != null && !uuidsConnus.contains(admUuid)) {
        itemsRaw.add(adm);
        uuidsConnus.add(admUuid);
      }
    }

    final campagnesDisponibles =
        (campagnesData['campaigns'] as List?)
            ?.whereType<Map>()
            .map(
              (item) => MappeurCampagneStageApi.depuisJson(
                Map<String, dynamic>.from(item),
              ),
            )
            .toList() ??
        <CampagneStage>[];

    final texteSecondaire = modeSombre
        ? const Color(0xFF94A3B8)
        : const Color(0xFF64748B);

    if (itemsRaw.isEmpty && !ConfigurationApi.utiliserDonneesMockees) {
      return LayoutBuilder(
        builder: (context, constraints) => SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        color: modeSombre
                            ? const Color(0xFF1E293B)
                            : const Color(0xFFF1F5F9),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Iconsax.document,
                        size: 30,
                        color: modeSombre
                            ? const Color(0xFF64748B)
                            : const Color(0xFF94A3B8),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      "Vous n'avez aucune candidature.",
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: texteSecondaire,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    }

    final List<Map<String, dynamic>> candidaturesListes = itemsRaw.isNotEmpty
        ? itemsRaw.map((item) {
            var suiviAdmission = item['campaign'] is Map
                ? SuiviCandidatureStage.depuisAdmission(item)
                : null;
            final admissionInitiale = suiviAdmission;
            if (admissionInitiale != null) {
              for (final campagneDisponible in campagnesDisponibles) {
                if (admissionInitiale.concerne(campagneDisponible)) {
                  suiviAdmission = admissionInitiale.avecCampagne(
                    campagneDisponible,
                  );
                  break;
                }
              }
            }

            final workflowStatus =
                suiviAdmission?.statut ??
                (item['workflow_status'] ??
                        (item['workflow'] is Map
                            ? item['workflow']['status']
                            : null) ??
                        item['application_status'] ??
                        item['statut'])
                    ?.toString()
                    .toUpperCase() ??
                '';

            final campagneInitiale =
                suiviAdmission?.campagne ??
                _campagnePourCandidature(
                  item,
                  campagnesDisponibles,
                  statut: workflowStatus,
                );

            final suivi =
                suiviAdmission ??
                SuiviCandidatureStage.depuisCandidature(item, campagneInitiale);

            final nomHopital = suivi.nomHopital.isNotEmpty
                ? suivi.nomHopital
                : (item['hospital_name'] ??
                              (item['hospital'] is Map
                                  ? item['hospital']['name']
                                  : null) ??
                              item['entreprise'])
                          ?.toString() ??
                      '';

            final titreCampagne = suivi.campagne.titre;
            final dateSoumission =
                item['submitted_at']?.toString() ??
                item['date']?.toString() ??
                (item['reservation'] is Map
                    ? item['reservation']['expires_at']?.toString()
                    : null) ??
                '';
            final campagne = suivi.campagne;

            // Statut et Libellé
            final (statutType, libelleCalcule) = switch (workflowStatus) {
              'DECISION_UNIVERSITAIRE_EN_ATTENTE' ||
              'SOUMISE' ||
              'EN_ATTENTE' => (
                StatutCandidatureType.enAttente,
                'Décision en attente',
              ),
              'EN_ATTENTE_PAIEMENT' => (
                StatutCandidatureType.paiementRequis,
                'Paiement requis',
              ),
              'ACCEPTEE' ||
              'CONFIRMEE' ||
              'PLACEMENT_UNIVERSITAIRE_EN_ATTENTE' => (
                StatutCandidatureType.acceptee,
                'Acceptée',
              ),
              'ADMISSION_HOSPITALIERE_EN_ATTENTE' || 'AFFECTATION_EN_ATTENTE' =>
                (StatutCandidatureType.confirme, 'Placement confirmé'),
              'STAGE_EN_COURS' ||
              'STAGE_PLANIFIE' ||
              'STAGE_TERMINE' ||
              'STAGE_VALIDE' => (StatutCandidatureType.admis, 'Admis en stage'),
              'CANDIDATURE_REFUSEE' ||
              'REFUSEE' => (StatutCandidatureType.refusee, 'Refusée'),
              'RESERVATION_EXPIREE' => (
                StatutCandidatureType.refusee,
                'Expirée',
              ),
              'ANNULEE' => (StatutCandidatureType.refusee, 'Annulée'),
              _ => (StatutCandidatureType.enAttente, workflowStatus),
            };

            final label = suivi.libelleStatut.isNotEmpty
                ? suivi.libelleStatut
                : libelleCalcule;

            // Sous-statut informatif : Réservation temporaire vs Candidature
            final resStatus =
                suivi.reservationStatus ??
                (item['reservation_status'] ??
                        (item['reservation'] is Map
                            ? item['reservation']['status']
                            : null))
                    ?.toString();
            String? sousStatut;
            if (resStatus == 'RESERVEE_TEMPORAIREMENT') {
              sousStatut = 'Réservation temporaire';
            } else if (resStatus == 'EN_ATTENTE_PAIEMENT') {
              sousStatut = 'Paiement requis';
            } else if (resStatus == 'CONFIRMEE') {
              sousStatut = 'Réservation confirmée';
            }

            final initiale = nomHopital.isNotEmpty
                ? nomHopital[0].toUpperCase()
                : '?';
            return {
              'initiale': initiale,
              'bg': const Color(0xFFE0F2FE),
              'textColor': const Color(0xFF0284C7),
              'entreprise': nomHopital,
              'titre': titreCampagne,
              'dateTexte': dateSoumission.isEmpty
                  ? ''
                  : (dateSoumission.contains('-') &&
                            !dateSoumission.startsWith('Soumis')
                        ? 'Soumis le ${_formaterDateCandidature(dateSoumission)}'
                        : dateSoumission),
              'statutType': statutType,
              'statutLabel': label,
              'sousStatut': sousStatut,
              'campagne': campagne,
              'suivi': suivi,
            };
          }).toList()
        : [
            {
              'initiale': 'H',
              'bg': const Color(0xFFE0F2FE),
              'textColor': const Color(0xFF0284C7),
              'entreprise': 'Hôpital Général',
              'titre': "Stage de fin d'année 2026",
              'dateTexte': 'Soumis le 15 Sept 2026',
              'statutType': StatutCandidatureType.paiementRequis,
              'statutLabel': 'Paiement requis',
              'sousStatut': 'Réservation approuvée',
              'campagne': SourceCampagneMock.campagnePrincipale,
              'suivi': SuiviCandidatureStage.depuisCandidature(const {
                'workflow_status': 'EN_ATTENTE_PAIEMENT',
                'reservation_status': 'EN_ATTENTE_PAIEMENT',
              }, SourceCampagneMock.campagnePrincipale),
            },
          ];

    final query = _rechercheController.text.trim().toLowerCase();
    final filtrer = candidaturesListes.where((c) {
      final statut = c['statutType'] as StatutCandidatureType;
      final matchStatut = switch (_filtreCandidature) {
        'En attente' =>
          statut == StatutCandidatureType.enAttente ||
              statut == StatutCandidatureType.paiementRequis,
        'Acceptée' =>
          statut == StatutCandidatureType.acceptee ||
              statut == StatutCandidatureType.confirme ||
              statut == StatutCandidatureType.admis,
        _ => true,
      };
      final matchRecherche =
          query.isEmpty ||
          (c['entreprise'] as String).toLowerCase().contains(query) ||
          (c['titre'] as String).toLowerCase().contains(query);
      return matchStatut && matchRecherche;
    }).toList();

    // Stats de l'API student/applications si disponibles, sinon comptage calculé
    final statsApi = candidaturesData['stats'] is Map
        ? Map<String, dynamic>.from(candidaturesData['stats'] as Map)
        : null;
    final nbTotal = statsApi != null && statsApi['total'] is int
        ? statsApi['total'] as int
        : candidaturesListes.length;
    final nbAcceptees = statsApi != null && statsApi['accepted'] is int
        ? statsApi['accepted'] as int
        : candidaturesListes
              .where(
                (c) =>
                    c['statutType'] == StatutCandidatureType.acceptee ||
                    c['statutType'] == StatutCandidatureType.confirme ||
                    c['statutType'] == StatutCandidatureType.admis,
              )
              .length;
    final nbEnAttente = statsApi != null && statsApi['submitted'] is int
        ? statsApi['submitted'] as int
        : candidaturesListes
              .where(
                (c) =>
                    c['statutType'] == StatutCandidatureType.enAttente ||
                    c['statutType'] == StatutCandidatureType.paiementRequis,
              )
              .length;

    final couleurFondBanniere = modeSombre
        ? const Color(0xFF1E293B)
        : Colors.white;
    final couleurBordureBanniere = modeSombre
        ? const Color(0xFF334155)
        : const Color(0xFFE2E8F0);

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 28),
      children: [
        // Bannière récapitulative fine & élégante
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: couleurFondBanniere,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: couleurBordureBanniere),
          ),
          child: Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: '$nbTotal candidature${nbTotal > 1 ? 's' : ''} ',
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w600,
                    color: texteSecondaire,
                    fontSize: 13,
                  ),
                ),
                TextSpan(
                  text: '• ',
                  style: TextStyle(
                    color: modeSombre
                        ? const Color(0xFF475569)
                        : const Color(0xFFCBD5E1),
                    fontSize: 13,
                  ),
                ),
                TextSpan(
                  text: '$nbAcceptees acceptée${nbAcceptees > 1 ? 's' : ''} ',
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w700,
                    color: modeSombre
                        ? const Color(0xFF4ADE80)
                        : const Color(0xFF16A34A),
                    fontSize: 13,
                  ),
                ),
                TextSpan(
                  text: '• ',
                  style: TextStyle(
                    color: modeSombre
                        ? const Color(0xFF475569)
                        : const Color(0xFFCBD5E1),
                    fontSize: 13,
                  ),
                ),
                TextSpan(
                  text: '$nbEnAttente en attente',
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w700,
                    color: modeSombre
                        ? const Color(0xFF38BDF8)
                        : const Color(0xFF2563EB),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 12),

        // Filtres (Toutes, En attente, Acceptée)
        Row(
          children: [
            _buildFiltreCandidatureChip('Toutes', modeSombre),
            const SizedBox(width: 8),
            _buildFiltreCandidatureChip('En attente', modeSombre),
            const SizedBox(width: 8),
            _buildFiltreCandidatureChip('Acceptée', modeSombre),
          ],
        ),

        const SizedBox(height: 16),

        // Liste des cartes de candidatures
        if (filtrer.isEmpty)
          Center(
            child: Padding(
              padding: const EdgeInsets.all(32.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: modeSombre
                          ? const Color(0xFF1E293B)
                          : const Color(0xFFF1F5F9),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Iconsax.document_filter,
                      size: 26,
                      color: modeSombre
                          ? const Color(0xFF64748B)
                          : const Color(0xFF94A3B8),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Aucune candidature ne correspond à vos filtres.',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: texteSecondaire,
                    ),
                  ),
                ],
              ),
            ),
          )
        else
          for (final item in filtrer)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: CarteCandidatureModerne(
                initiale: item['initiale'] as String,
                couleurFondInitiale: item['bg'] as Color,
                couleurTexteInitiale: item['textColor'] as Color,
                nomEntreprise: item['entreprise'] as String,
                titrePoste: item['titre'] as String,
                dateTexte: item['dateTexte'] as String,
                statutType: item['statutType'] as StatutCandidatureType,
                libelleStatutCustom: item['statutLabel'] as String?,
                sousStatutTexte: item['sousStatut'] as String?,
                onTap: () async {
                  await Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => DetailCampagnePage(
                        campagne: item['campagne'] as CampagneStage,
                        suiviCandidature:
                            item['suivi'] as SuiviCandidatureStage?,
                      ),
                    ),
                  );
                  if (mounted) {
                    _actualiser();
                  }
                },
              ),
            ),
      ],
    );
  }

  String _formaterDateCandidature(String brute) {
    final parsed = DateTime.tryParse(brute);
    if (parsed == null) return brute;
    const mois = [
      'Janv.',
      'Févr.',
      'Mars',
      'Avr.',
      'Mai',
      'Juin',
      'Juil.',
      'Août',
      'Sept.',
      'Oct.',
      'Nov.',
      'Déc.',
    ];
    return '${parsed.day} ${mois[parsed.month - 1]} ${parsed.year}';
  }

  CampagneStage _campagnePourCandidature(
    Map<String, dynamic> candidature,
    List<CampagneStage> campagnes, {
    required String statut,
  }) {
    final id =
        (candidature['campaign_id'] ?? candidature['campagne_id'])
            ?.toString()
            .trim() ??
        '';
    final code =
        (candidature['campaign_code'] ?? candidature['code'])
            ?.toString()
            .trim() ??
        '';
    final titre =
        (candidature['campaign_title'] ?? candidature['titre'])
            ?.toString()
            .trim() ??
        '';

    for (final campagne in campagnes) {
      if ((id.isNotEmpty && campagne.id == id) ||
          (code.isNotEmpty && campagne.code == code) ||
          (titre.isNotEmpty && campagne.titre == titre)) {
        return campagne;
      }
    }

    final debut = candidature['start_date']?.toString() ?? '';
    final fin = candidature['end_date']?.toString() ?? '';
    return CampagneStage(
      id: id,
      code: code,
      titre: titre.isEmpty ? 'Candidature de stage' : titre,
      sousTitre: candidature['hospital_name']?.toString() ?? '',
      dateDebut: debut,
      dateFin: fin,
      periodeTexte: debut.isNotEmpty && fin.isNotEmpty
          ? '$debut - $fin'
          : 'Dates à confirmer',
      indemnite: '',
      modalite: '',
      statut: SuiviCandidatureStage.libellePour(statut),
      nombreHopitaux: 0,
      estEligible: true,
      consignes: const [],
      criteresEligibilite: const [],
      hopitaux: const [],
    );
  }

  Widget _buildFiltreCandidatureChip(String titre, bool modeSombre) {
    final actif = _filtreCandidature == titre;
    final couleurFond = actif
        ? const Color(0xFF1D61F2)
        : (modeSombre ? const Color(0xFF1E293B) : Colors.white);
    final couleurBordure = actif
        ? const Color(0xFF1D61F2)
        : (modeSombre ? const Color(0xFF334155) : const Color(0xFFE2E8F0));
    final couleurTexte = actif
        ? Colors.white
        : (modeSombre ? const Color(0xFF94A3B8) : const Color(0xFF64748B));

    return GestureDetector(
      onTap: () => setState(() => _filtreCandidature = titre),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8.5),
        decoration: BoxDecoration(
          color: couleurFond,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: couleurBordure),
        ),
        child: Text(
          titre,
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: actif ? FontWeight.w700 : FontWeight.w500,
            color: couleurTexte,
          ),
        ),
      ),
    );
  }
}
