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
import '../../../../core/widgets/erreur_chargement_api.dart';
import '../../../messagerie/presentation/pages/messagerie_page.dart';
import '../../../notifications/presentation/pages/notifications_page.dart';
import '../../data/datasources/source_stage_distante.dart';
import '../../data/datasources/source_campagne_mock.dart';
import '../../data/mappers/mappeur_campagne_stage_api.dart';
import '../../data/mappers/mappeur_affectation_stage_api.dart';
import '../../domain/entities/campagne_stage.dart';
import '../../domain/entities/suivi_candidature_stage.dart';
import '../routes/routes_stage.dart';
import 'detail_campagne_page.dart';
import 'justification_stage_page.dart';
import 'mon_stage_page.dart';
import '../widgets/barre_recherche_stages.dart';
import '../widgets/carte_candidature_moderne.dart';
import '../widgets/carte_stage_explorer.dart';
import '../widgets/onglets_trois_stages.dart';

import 'dart:async';
import '../../../../core/services/sse_notifications_service.dart';

class MesStagesPage extends StatefulWidget {
  const MesStagesPage({
    this.filtreSuiviInitial = 'Tous',
    this.depuisProfil = false,
    super.key,
  });

  final String filtreSuiviInitial;
  final bool depuisProfil;

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
  late String _filtreSuiviStage;
  bool _actuelServiceDeroule = true;
  bool _prochainServiceDeroule = false;

  late Future<List<Map<String, dynamic>>> _chargement;
  Map<String, dynamic>? _counts;
  StreamSubscription? _sseSubscription;

  @override
  void initState() {
    super.initState();
    _filtreSuiviStage = widget.filtreSuiviInitial;
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
    _sourceEtudiant.cloturesStage(perPage: 100),
    _sourceEtudiant.resultatsStage(perPage: 100),
    _sourceEtudiant.justificationsStage(),
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
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFF1D61F2),
                      ),
                    );
                  }
                  if (snapshot.hasError) {
                    return ErreurChargementApi(
                      erreur: snapshot.error,
                      onReessayer: _actualiser,
                    );
                  }
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
                  final donneesClotures =
                      snapshot.data != null && snapshot.data!.length > 5
                      ? snapshot.data![5]
                      : const <String, dynamic>{};
                  final donneesResultats =
                      snapshot.data != null && snapshot.data!.length > 6
                      ? snapshot.data![6]
                      : const <String, dynamic>{};
                  final donneesJustifications =
                      snapshot.data != null && snapshot.data!.length > 7
                      ? snapshot.data![7]
                      : const <String, dynamic>{};

                  final stagesListe =
                      (donneesStages['items'] as List?)
                          ?.whereType<Map>()
                          .map(Map<String, dynamic>.from)
                          .toList() ??
                      [];
                  return RefreshIndicator(
                    color: const Color(0xFF1D61F2),
                    onRefresh: _actualiser,
                    child: switch (_ongletActif) {
                      0 => _buildOngletEnCours(
                        stagesListe,
                        donneesClotures,
                        donneesResultats,
                        donneesJustifications,
                        modeSombre,
                      ),
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
      automaticallyImplyLeading: widget.depuisProfil,
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
  // ONGLET 1 : EN COURS (Harmonisé avec Candidatures)
  // ==========================================
  Widget _buildOngletEnCours(
    List<Map<String, dynamic>> stages,
    Map<String, dynamic> donneesClotures,
    Map<String, dynamic> donneesResultats,
    Map<String, dynamic> donneesJustifications,
    bool modeSombre,
  ) {
    final couleurCarte = modeSombre ? const Color(0xFF1E293B) : Colors.white;
    final couleurBordure = modeSombre
        ? const Color(0xFF334155)
        : const Color(0xFFE2E8F0);
    final textePrincipal = modeSombre ? Colors.white : const Color(0xFF0F172A);
    final texteSecondaire = modeSombre
        ? const Color(0xFF94A3B8)
        : const Color(0xFF64748B);

    final clotures = _maps(donneesClotures['items']);
    final resultats = _maps(donneesResultats['items']);

    // Compteurs pour la bannière récapitulative
    int nbTotal = stages.length;
    int nbEnCours = 0;
    int nbClotures = 0;
    int nbEnValidation = 0;
    int nbValides = 0;

    for (final s in stages) {
      final ref = s['assignment_uuid']?.toString();
      final c = _parAffectation(clotures, ref);
      final r = _parAffectation(resultats, ref);
      final lib = _libelleSuivi(s, c, r);
      if (lib == 'Stage validé') {
        nbValides++;
      } else if (lib == 'Validation universitaire en attente') {
        nbEnValidation++;
      } else if (lib == 'Clôture en cours') {
        nbClotures++;
      } else {
        nbEnCours++;
      }
    }

    final query = _rechercheController.text.trim().toLowerCase();
    final stagesFiltres = stages
        .where((stage) {
          final reference = stage['assignment_uuid']?.toString();
          final completion = _parAffectation(clotures, reference);
          final resultat = _parAffectation(resultats, reference);
          final matchFiltre = _correspondAuFiltre(stage, completion, resultat);

          if (!matchFiltre) return false;
          if (query.isEmpty) return true;

          final nomH =
              (stage['hospital'] is Map
                      ? stage['hospital']['name']
                      : stage['hospital_name'])
                  ?.toString()
                  .toLowerCase() ??
              '';
          final titreC =
              (stage['campaign'] is Map
                      ? stage['campaign']['title']
                      : stage['campaign_title'] ?? stage['titre'])
                  ?.toString()
                  .toLowerCase() ??
              '';
          final nomDep =
              (stage['department'] is Map
                      ? stage['department']['name']
                      : stage['department_name'])
                  ?.toString()
                  .toLowerCase() ??
              '';
          return nomH.contains(query) ||
              titreC.contains(query) ||
              nomDep.contains(query);
        })
        .toList(growable: false);

    final stage = stagesFiltres.isEmpty
        ? null
        : MappeurAffectationStageApi.selectionnerAffectationPrincipale(
                stagesFiltres,
              ) ??
              stagesFiltres.first;
    final completion = _parAffectation(
      clotures,
      stage?['assignment_uuid']?.toString(),
    );
    final resultat = _parAffectation(
      resultats,
      stage?['assignment_uuid']?.toString(),
    );
    final justification = _justificationPourAffectation(
      donneesJustifications,
      stage?['assignment_uuid']?.toString(),
    );

    final couleurFondBanniere = modeSombre
        ? const Color(0xFF1E293B)
        : Colors.white;
    final couleurBordureBanniere = modeSombre
        ? const Color(0xFF334155)
        : const Color(0xFFE2E8F0);

    // Extraction enrichie selon GET /api/v1/student/stages. Une map vide
    // permet de préparer le rendu avant le branchement vide/non vide sans
    // forcer l'accès à une affectation nullable.
    final stageAffiche = stage ?? const <String, dynamic>{};
    final hospital = stageAffiche['hospital'] is Map
        ? stageAffiche['hospital'] as Map
        : const {};
    final department = stageAffiche['department'] is Map
        ? stageAffiche['department'] as Map
        : const {};
    final campaign = stageAffiche['campaign'] is Map
        ? stageAffiche['campaign'] as Map
        : const {};
    final period = stageAffiche['period'] is Map
        ? stageAffiche['period'] as Map
        : const {};
    final planning = stageAffiche['planning'] is Map
        ? stageAffiche['planning'] as Map
        : const {};
    final rotationsList =
        (planning['rotations'] as List? ??
                stageAffiche['rotations'] as List? ??
                [])
            .whereType<Map>()
            .map(Map<String, dynamic>.from)
            .toList();
    final currentRotation = planning['current_rotation'] is Map
        ? Map<String, dynamic>.from(planning['current_rotation'] as Map)
        : null;
    final titreCampagne =
        (campaign['title'] ??
                stageAffiche['campaign_title'] ??
                stageAffiche['titre'])
            ?.toString() ??
        '';
    final nomHopital =
        (hospital['name'] ?? stageAffiche['hospital_name'])?.toString() ?? '';
    final nomDepartement =
        (department['name'] ?? stageAffiche['department_name'])?.toString() ??
        '';

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

    final supervisorMap =
        currentRotation != null && currentRotation['supervisor'] is Map
        ? currentRotation['supervisor'] as Map
        : const {};
    final nomEncadreur =
        (supervisorMap['name'] ?? currentRotation?['supervisor_name'])
            ?.toString() ??
        '';

    // Extraction du service actuel
    final rotationActuelle = currentRotation ??
        (rotationsList.isNotEmpty ? rotationsList.first : null);
    final serviceActuelMap = rotationActuelle != null && rotationActuelle['service'] is Map
        ? rotationActuelle['service'] as Map
        : const {};
    final unitActuelMap = rotationActuelle != null && rotationActuelle['unit'] is Map
        ? rotationActuelle['unit'] as Map
        : const {};
    final supervisorActuelMap = rotationActuelle != null && rotationActuelle['supervisor'] is Map
        ? rotationActuelle['supervisor'] as Map
        : const {};
    final deptActuelMap = rotationActuelle != null && rotationActuelle['department'] is Map
        ? rotationActuelle['department'] as Map
        : const {};

    final nomServiceAffiche = (serviceActuelMap['name'] ??
            rotationActuelle?['service_name'] ??
            nomService)
        ?.toString() ?? '';
    final nomUniteAffiche = (unitActuelMap['name'] ??
            rotationActuelle?['unit_name'] ??
            nomUnite)
        ?.toString();
    final nomDepartementActuel = (deptActuelMap['name'] ??
            rotationActuelle?['department_name'] ??
            nomDepartement)
        ?.toString() ?? '';
    final nomEncadreurActuel = (supervisorActuelMap['name'] ??
            rotationActuelle?['supervisor_name'] ??
            nomEncadreur)
        ?.toString() ?? '';

    final periodActuelMap = rotationActuelle != null && rotationActuelle['period'] is Map
        ? rotationActuelle['period'] as Map
        : const {};
    final debActuel = (periodActuelMap['start_date'] ?? rotationActuelle?['date_debut'])?.toString();
    final finActuel = (periodActuelMap['end_date'] ?? rotationActuelle?['date_fin'])?.toString();
    final periodeActuel = (debActuel != null && debActuel.isNotEmpty && finActuel != null && finActuel.isNotEmpty)
        ? 'Du $debActuel au $finActuel'
        : '';

    // Extraction du prochain service (next_rotation ou rotation suivante dans rotationsList)
    final nextRotation = planning['next_rotation'] is Map
        ? Map<String, dynamic>.from(planning['next_rotation'] as Map)
        : null;
    final Map<String, dynamic>? prochainRotationAffichee = nextRotation ?? () {
      if (rotationActuelle == null || rotationsList.length <= 1) return null;
      final indexActuel = rotationsList.indexOf(rotationActuelle);
      if (indexActuel >= 0 && indexActuel + 1 < rotationsList.length) {
        return rotationsList[indexActuel + 1];
      }
      return null;
    }();

    final serviceProchainMap = prochainRotationAffichee != null && prochainRotationAffichee['service'] is Map
        ? prochainRotationAffichee['service'] as Map
        : const {};
    final unitProchainMap = prochainRotationAffichee != null && prochainRotationAffichee['unit'] is Map
        ? prochainRotationAffichee['unit'] as Map
        : const {};
    final supervisorProchainMap = prochainRotationAffichee != null && prochainRotationAffichee['supervisor'] is Map
        ? prochainRotationAffichee['supervisor'] as Map
        : const {};
    final deptProchainMap = prochainRotationAffichee != null && prochainRotationAffichee['department'] is Map
        ? prochainRotationAffichee['department'] as Map
        : const {};

    final nomServiceProchain = (serviceProchainMap['name'] ??
            prochainRotationAffichee?['service_name'])
        ?.toString() ?? '';
    final nomUniteProchain = (unitProchainMap['name'] ??
            prochainRotationAffichee?['unit_name'])
        ?.toString();
    final nomDepartementProchain = (deptProchainMap['name'] ??
            prochainRotationAffichee?['department_name'] ??
            nomDepartement)
        ?.toString() ?? '';
    final nomEncadreurProchain = (supervisorProchainMap['name'] ??
            prochainRotationAffichee?['supervisor_name'])
        ?.toString() ?? '';

    final periodProchainMap = prochainRotationAffichee != null && prochainRotationAffichee['period'] is Map
        ? prochainRotationAffichee['period'] as Map
        : const {};
    final debProchain = (periodProchainMap['start_date'] ?? prochainRotationAffichee?['date_debut'])?.toString();
    final finProchain = (periodProchainMap['end_date'] ?? prochainRotationAffichee?['date_fin'])?.toString();
    final periodeProchain = (debProchain != null && debProchain.isNotEmpty && finProchain != null && finProchain.isNotEmpty)
        ? 'Du $debProchain au $finProchain'
        : '';

    final dateDebutStr = (period['start_date'] ?? stageAffiche['date_debut'])
        ?.toString();
    final dateFinStr = (period['end_date'] ?? stageAffiche['date_fin'])
        ?.toString();
    final dateDebut = DateTime.tryParse(dateDebutStr ?? '');
    final dateFin = DateTime.tryParse(dateFinStr ?? '');
    final totalJours = dateDebut != null && dateFin != null
        ? dateFin.difference(dateDebut).inDays.abs() + 1
        : 0;
    final joursEffectues = dateDebut != null
        ? DateTime.now().difference(dateDebut).inDays.clamp(0, totalJours)
        : 0;

    final totalRotations = planning['total'] is int
        ? planning['total'] as int
        : rotationsList.length;
    final rotationsEffectuees = rotationsList
        .where((rotation) => rotation['status'] == 'TERMINEE')
        .length;

    final paddingBas = MediaQuery.paddingOf(context).bottom + 96.0;

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: EdgeInsets.fromLTRB(16, 14, 16, paddingBas),
      children: [
        // 1. Bannière récapitulative fine & élégante comme dans Candidatures
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8.5),
          decoration: BoxDecoration(
            color: couleurFondBanniere,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: couleurBordureBanniere),
          ),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                Text(
                  '$nbTotal stage${nbTotal > 1 ? 's' : ''}',
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w600,
                    color: texteSecondaire,
                    fontSize: 12.5,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  child: Text(
                    '•',
                    style: TextStyle(
                      color: modeSombre
                          ? const Color(0xFF475569)
                          : const Color(0xFFCBD5E1),
                      fontSize: 12,
                    ),
                  ),
                ),
                Text(
                  '$nbEnCours en cours',
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w700,
                    color: modeSombre
                        ? const Color(0xFF38BDF8)
                        : const Color(0xFF1D61F2),
                    fontSize: 12.5,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  child: Text(
                    '•',
                    style: TextStyle(
                      color: modeSombre
                          ? const Color(0xFF475569)
                          : const Color(0xFFCBD5E1),
                      fontSize: 12,
                    ),
                  ),
                ),
                Text(
                  '$nbValides validé${nbValides > 1 ? 's' : ''}',
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w700,
                    color: modeSombre
                        ? const Color(0xFF4ADE80)
                        : const Color(0xFF16A34A),
                    fontSize: 12.5,
                  ),
                ),
                if (nbEnValidation > 0) ...[
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    child: Text(
                      '•',
                      style: TextStyle(
                        color: modeSombre
                            ? const Color(0xFF475569)
                            : const Color(0xFFCBD5E1),
                        fontSize: 12,
                      ),
                    ),
                  ),
                  Text(
                    '$nbEnValidation en validation',
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.w700,
                      color: modeSombre
                          ? const Color(0xFFFCD34D)
                          : const Color(0xFFD97706),
                      fontSize: 12.5,
                    ),
                  ),
                ],
                if (nbClotures > 0) ...[
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    child: Text(
                      '•',
                      style: TextStyle(
                        color: modeSombre
                            ? const Color(0xFF475569)
                            : const Color(0xFFCBD5E1),
                        fontSize: 12,
                      ),
                    ),
                  ),
                  Text(
                    '$nbClotures clôturé${nbClotures > 1 ? 's' : ''}',
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.w700,
                      color: modeSombre
                          ? const Color(0xFFA5B4FC)
                          : const Color(0xFF4338CA),
                      fontSize: 12.5,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),

        const SizedBox(height: 12),

        // 2. Filtres horizontaux au design élégant des chips Candidatures
        _buildFiltresSuivi(modeSombre),

        const SizedBox(height: 16),

        if (stage == null) ...[
          const SizedBox(height: 48),
          Center(
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
                    _filtreSuiviStage == 'Tous'
                        ? "Vous n'avez aucun stage à suivre."
                        : 'Aucun stage ne correspond à ce filtre.',
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
        ] else ...[
          // Titre de la campagne au sommet de la page
          if (titreCampagne.isNotEmpty) ...[
            Text(
              titreCampagne,
              style: GoogleFonts.inter(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: textePrincipal,
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: 14),
          ],

          // Justification moderne (juste sous le titre de la campagne)
          if (justification != null) ...[
            _buildAlerteJustification(justification, modeSombre),
            const SizedBox(height: 14),
          ],

          // Statut du suivi / validation
          _buildEtatSuiviStage(stage, completion, resultat, modeSombre),
          const SizedBox(height: 16),

          // Carte décomposée : Progression globale du stage (Inspirée de Présences dans Mon journal)
          _buildCarteProgressionStageDirecte(
            nomHopital: nomHopital,
            joursEffectues: joursEffectues,
            totalJours: totalJours,
            rotationsEffectuees: rotationsEffectuees,
            totalRotations: totalRotations,
            onOuvrirMonStage: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => MonStagePage(
                  assignmentReference: stage['assignment_uuid']?.toString(),
                ),
              ),
            ),
            modeSombre: modeSombre,
            couleurCarte: couleurCarte,
            couleurBordure: couleurBordure,
            textePrincipal: textePrincipal,
            texteSecondaire: texteSecondaire,
          ),

          const SizedBox(height: 18),

          // 1. CARTE "SERVICE ACTUEL"
          _buildCarteServiceRotationResume(
            titreSection: 'Service actuel',
            iconeSection: Icons.medical_services_rounded,
            couleurIcone: const Color(0xFF1D61F2),
            nomService: nomServiceAffiche,
            nomUnite: nomUniteAffiche,
            nomDepartement: nomDepartementActuel,
            nomHopital: nomHopital,
            periodeTexte: periodeActuel,
            nomEncadreur: nomEncadreurActuel,
            estDeroule: _actuelServiceDeroule,
            surChangementDeroule: () => setState(() {
              _actuelServiceDeroule = !_actuelServiceDeroule;
            }),
            modeSombre: modeSombre,
            couleurCarte: couleurCarte,
            couleurBordure: couleurBordure,
            textePrincipal: textePrincipal,
            texteSecondaire: texteSecondaire,
          ),

          // 2. CARTE "PROCHAIN SERVICE" (si présent)
          if (prochainRotationAffichee != null) ...[
            const SizedBox(height: 14),
            _buildCarteServiceRotationResume(
              titreSection: 'Prochain service',
              iconeSection: Icons.arrow_forward_rounded,
              couleurIcone: const Color(0xFF6366F1),
              nomService: nomServiceProchain,
              nomUnite: nomUniteProchain,
              nomDepartement: nomDepartementProchain,
              nomHopital: nomHopital,
              periodeTexte: periodeProchain,
              nomEncadreur: nomEncadreurProchain,
              estDeroule: _prochainServiceDeroule,
              surChangementDeroule: () => setState(() {
                _prochainServiceDeroule = !_prochainServiceDeroule;
              }),
              modeSombre: modeSombre,
              couleurCarte: couleurCarte,
              couleurBordure: couleurBordure,
              textePrincipal: textePrincipal,
              texteSecondaire: texteSecondaire,
            ),
          ],
        ],
      ],
    );
  }

  /// Carte directe de progression du stage (Inspirée du design Présence de Mon journal)
  Widget _buildCarteProgressionStageDirecte({
    required String nomHopital,
    required int joursEffectues,
    required int totalJours,
    required int rotationsEffectuees,
    required int totalRotations,
    required VoidCallback onOuvrirMonStage,
    required bool modeSombre,
    required Color couleurCarte,
    required Color couleurBordure,
    required Color textePrincipal,
    required Color texteSecondaire,
  }) {
    final double progressionRatio = totalJours > 0
        ? (joursEffectues / totalJours).clamp(0.0, 1.0)
        : 0.0;
    final int pourcentage = (progressionRatio * 100).round();

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: couleurCarte,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: couleurBordure),
        boxShadow: [
          BoxShadow(
            color: modeSombre
                ? const Color(0x30000000)
                : const Color(0x05000000),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Ligne Établissement et badge de progression
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFF1D61F2).withValues(
                    alpha: modeSombre ? 0.2 : 0.1,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.local_hospital_rounded,
                  size: 20,
                  color: Color(0xFF1D61F2),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Établissement d\'accueil',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFF94A3B8),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      nomHopital.isNotEmpty ? nomHopital : 'Établissement non renseigné',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                        fontSize: 15.5,
                        fontWeight: FontWeight.w800,
                        color: textePrincipal,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4.5,
                ),
                decoration: BoxDecoration(
                  color: modeSombre
                      ? const Color(0xFF1E3A8A).withValues(alpha: 0.5)
                      : const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '$pourcentage%',
                  style: GoogleFonts.inter(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF1D61F2),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Barre de progression
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: progressionRatio,
              minHeight: 7,
              backgroundColor: modeSombre
                  ? const Color(0xFF334155)
                  : const Color(0xFFE2E8F0),
              valueColor: const AlwaysStoppedAnimation<Color>(
                Color(0xFF1D61F2),
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Indicateurs métriques clés (style Présences)
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: modeSombre
                        ? const Color(0xFF0F172A).withValues(alpha: 0.4)
                        : const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: couleurBordure),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Jours validés',
                        style: GoogleFonts.inter(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFF94A3B8),
                        ),
                      ),
                      const SizedBox(height: 3),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Text(
                            '$joursEffectues',
                            style: GoogleFonts.inter(
                              fontSize: 17,
                              fontWeight: FontWeight.w900,
                              color: const Color(0xFF16A34A),
                            ),
                          ),
                          Text(
                            ' / $totalJours j',
                            style: GoogleFonts.inter(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w600,
                              color: texteSecondaire,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: modeSombre
                        ? const Color(0xFF0F172A).withValues(alpha: 0.4)
                        : const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: couleurBordure),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Services validés',
                        style: GoogleFonts.inter(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFF94A3B8),
                        ),
                      ),
                      const SizedBox(height: 3),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Text(
                            '$rotationsEffectuees',
                            style: GoogleFonts.inter(
                              fontSize: 17,
                              fontWeight: FontWeight.w900,
                              color: const Color(0xFF1D61F2),
                            ),
                          ),
                          Text(
                            ' / $totalRotations',
                            style: GoogleFonts.inter(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w600,
                              color: texteSecondaire,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          // Bouton d'action pour ouvrir le dossier complet
          SizedBox(
            width: double.infinity,
            height: 42,
            child: OutlinedButton.icon(
              onPressed: onOuvrirMonStage,
              icon: const Icon(
                Icons.assignment_outlined,
                size: 17,
                color: Color(0xFF1D61F2),
              ),
              label: Text(
                'Consulter le dossier du stage',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF1D61F2),
                ),
              ),
              style: OutlinedButton.styleFrom(
                side: BorderSide(
                  color: const Color(0xFF1D61F2).withValues(
                    alpha: modeSombre ? 0.5 : 0.3,
                  ),
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCarteServiceRotationResume({
    required String titreSection,
    required IconData iconeSection,
    required Color couleurIcone,
    required String nomService,
    required String? nomUnite,
    required String nomDepartement,
    required String nomHopital,
    required String periodeTexte,
    required String nomEncadreur,
    required bool estDeroule,
    required VoidCallback surChangementDeroule,
    required bool modeSombre,
    required Color couleurCarte,
    required Color couleurBordure,
    required Color textePrincipal,
    required Color texteSecondaire,
  }) {
    final aUnDepartement = nomDepartement.isNotEmpty;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: couleurCarte,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: couleurBordure),
        boxShadow: [
          BoxShadow(
            color: modeSombre
                ? const Color(0x33000000)
                : const Color(0x06000000),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // En-tête principal : icône + Service + flèche déroulante
          InkWell(
            onTap: surChangementDeroule,
            borderRadius: BorderRadius.circular(18),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: couleurIcone.withValues(
                        alpha: modeSombre ? 0.2 : 0.12,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      iconeSection,
                      size: 22,
                      color: couleurIcone,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          titreSection,
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF94A3B8),
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          nomService.isNotEmpty
                              ? (nomUnite != null && nomUnite.isNotEmpty
                                  ? '$nomService • $nomUnite'
                                  : nomService)
                              : 'Service non défini',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.inter(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: textePrincipal,
                          ),
                        ),
                        if (periodeTexte.isNotEmpty) ...[
                          const SizedBox(height: 3),
                          Text(
                            periodeTexte,
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: texteSecondaire,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: modeSombre
                          ? const Color(0xFF334155).withValues(alpha: 0.5)
                          : const Color(0xFFF1F5F9),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      estDeroule
                          ? Icons.keyboard_arrow_up_rounded
                          : Icons.keyboard_arrow_down_rounded,
                      size: 20,
                      color: texteSecondaire,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Section déroulante affichant le Département et les infos associées
          if (estDeroule) ...[
            Divider(height: 1, color: couleurBordure),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
              decoration: BoxDecoration(
                color: modeSombre
                    ? const Color(0xFF0F172A).withValues(alpha: 0.5)
                    : const Color(0xFFF8FAFC),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(18),
                  bottomRight: Radius.circular(18),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: modeSombre
                              ? const Color(0xFF0C4A6E).withValues(alpha: 0.4)
                              : const Color(0xFFE0F2FE),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.domain_rounded,
                          size: 18,
                          color: Color(0xFF0284C7),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Département',
                              style: GoogleFonts.inter(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF94A3B8),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              aUnDepartement ? nomDepartement : 'Non renseigné',
                              style: GoogleFonts.inter(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w700,
                                color: textePrincipal,
                              ),
                            ),
                            if (nomHopital.isNotEmpty) ...[
                              const SizedBox(height: 2),
                              Text(
                                nomHopital,
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: texteSecondaire,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                  if (nomEncadreur.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 12,
                          backgroundColor: modeSombre
                              ? const Color(0xFF334155)
                              : const Color(0xFFE2E8F0),
                          child: Icon(
                            Icons.person,
                            size: 14,
                            color: texteSecondaire,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          'Encadreur : ',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: texteSecondaire,
                          ),
                        ),
                        Expanded(
                          child: Text(
                            nomEncadreur,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.inter(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF1D61F2),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ],
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

  Widget _buildAlerteJustification(
    Map<String, dynamic> justification,
    bool modeSombre,
  ) {
    final statut = justification['justification_status']
        ?.toString()
        .toUpperCase();
    final (titre, couleur, icone, badgeTexte) = switch (statut) {
      'ACCEPTEE' => (
        'Justification acceptée',
        const Color(0xFF16A34A),
        CupertinoIcons.checkmark_seal_fill,
        'Validée',
      ),
      'REJETEE' => (
        'Justification rejetée',
        const Color(0xFFDC2626),
        CupertinoIcons.clear_circled_solid,
        'Rejetée',
      ),
      'EN_ATTENTE' => (
        'Justification en attente',
        const Color(0xFFEA580C),
        CupertinoIcons.clock_fill,
        'En attente',
      ),
      _ => (
        'Justification requise',
        const Color(0xFFFF751F),
        CupertinoIcons.exclamationmark_triangle_fill,
        'À fournir',
      ),
    };
    final description =
        justification['decision_message']?.toString().trim().isNotEmpty == true
        ? justification['decision_message'].toString().trim()
        : justification['message']?.toString().trim().isNotEmpty == true
        ? justification['message'].toString().trim()
        : 'Une démarche de justification est requise pour ce stage.';
    final assignmentUuid = justification['assignment_uuid']?.toString() ?? '';
    final couleurCarte = modeSombre ? const Color(0xFF1E293B) : Colors.white;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: assignmentUuid.isEmpty
            ? null
            : () async {
                await Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) =>
                        JustificationStagePage(assignmentUuid: assignmentUuid),
                  ),
                );
                if (mounted) await _actualiser();
              },
        borderRadius: BorderRadius.circular(20),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: couleurCarte,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: couleur.withValues(alpha: modeSombre ? 0.35 : 0.25),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: modeSombre
                    ? const Color(0x30000000)
                    : const Color(0x05000000),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: couleur.withValues(alpha: modeSombre ? 0.18 : 0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                alignment: Alignment.center,
                child: Icon(icone, color: couleur, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            titre,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.inter(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              color: modeSombre
                                  ? Colors.white
                                  : const Color(0xFF0F172A),
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: couleur.withValues(
                              alpha: modeSombre ? 0.2 : 0.1,
                            ),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            badgeTexte,
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: couleur,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w500,
                        color: modeSombre
                            ? const Color(0xFF94A3B8)
                            : const Color(0xFF64748B),
                        height: 1.35,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Text(
                          'Gérer la justification',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF1D61F2),
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Icon(
                          CupertinoIcons.chevron_right,
                          color: Color(0xFF1D61F2),
                          size: 13,
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
    );
  }

  Map<String, dynamic>? _justificationPourAffectation(
    Map<String, dynamic> donnees,
    String? assignmentUuid,
  ) {
    if (assignmentUuid == null || assignmentUuid.isEmpty) return null;
    for (final item in _maps(donnees['items'])) {
      if (item['assignment_uuid']?.toString() != assignmentUuid) continue;
      final situation = item['situation']?.toString().trim() ?? '';
      final justificationUuid =
          item['justification_uuid']?.toString().trim() ?? '';
      final statut = item['justification_status']?.toString().trim() ?? '';
      final allowedType = item['allowed_type']?.toString().trim() ?? '';
      if (situation.isNotEmpty ||
          justificationUuid.isNotEmpty ||
          statut.isNotEmpty ||
          allowedType.isNotEmpty) {
        return item;
      }
    }
    return null;
  }

  Widget _buildFiltresSuivi(bool modeSombre) {
    const filtres = [
      'Tous',
      'En cours',
      'Clôturé',
      'En cours de validation',
      'Validé',
    ];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: filtres.map((filtre) {
          final actif = _filtreSuiviStage == filtre;
          final couleurFond = actif
              ? const Color(0xFF1D61F2)
              : (modeSombre ? const Color(0xFF1E293B) : Colors.white);
          final couleurBordure = actif
              ? const Color(0xFF1D61F2)
              : (modeSombre
                    ? const Color(0xFF334155)
                    : const Color(0xFFE2E8F0));
          final couleurTexte = actif
              ? Colors.white
              : (modeSombre
                    ? const Color(0xFF94A3B8)
                    : const Color(0xFF64748B));

          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () => setState(() => _filtreSuiviStage = filtre),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8.5,
                ),
                decoration: BoxDecoration(
                  color: couleurFond,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: couleurBordure),
                ),
                child: Text(
                  filtre,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: actif ? FontWeight.w700 : FontWeight.w500,
                    color: couleurTexte,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildEtatSuiviStage(
    Map<String, dynamic> stage,
    Map<String, dynamic>? completion,
    Map<String, dynamic>? resultat,
    bool modeSombre,
  ) {
    final libelle = _libelleSuivi(stage, completion, resultat);
    final (couleurFond, couleurTexte, icone, sousTitre) = switch (libelle) {
      'Stage validé' => (
        modeSombre
            ? const Color(0xFF14532D).withValues(alpha: 0.35)
            : const Color(0xFFDCFCE7),
        modeSombre ? const Color(0xFF86EFAC) : const Color(0xFF16A34A),
        CupertinoIcons.checkmark_seal_fill,
        'Stage évalué et validé académiquement',
      ),
      'Validation universitaire en attente' => (
        modeSombre
            ? const Color(0xFF78350F).withValues(alpha: 0.35)
            : const Color(0xFFFEF3C7),
        modeSombre ? const Color(0xFFFCD34D) : const Color(0xFFD97706),
        CupertinoIcons.hourglass,
        'Dossier transmis pour validation universitaire',
      ),
      'Clôture en cours' => (
        modeSombre
            ? const Color(0xFF312E81).withValues(alpha: 0.35)
            : const Color(0xFFE0E7FF),
        modeSombre ? const Color(0xFFA5B4FC) : const Color(0xFF4338CA),
        CupertinoIcons.archivebox_fill,
        'Période terminée — finalisation du rapport et clôture',
      ),
      _ => (
        modeSombre
            ? const Color(0xFF0C4A6E).withValues(alpha: 0.35)
            : const Color(0xFFE0F2FE),
        modeSombre ? const Color(0xFF7DD3FC) : const Color(0xFF0284C7),
        CupertinoIcons.sparkles,
        'Période de stage en déroulement normal',
      ),
    };

    final couleurCarte = modeSombre ? const Color(0xFF1E293B) : Colors.white;
    final couleurBordure = modeSombre
        ? const Color(0xFF334155)
        : const Color(0xFFE2E8F0);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: couleurCarte,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: couleurBordure),
        boxShadow: [
          BoxShadow(
            color: modeSombre
                ? const Color(0x30000000)
                : const Color(0x05000000),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: couleurFond,
              borderRadius: BorderRadius.circular(14),
            ),
            alignment: Alignment.center,
            child: Icon(icone, color: couleurTexte, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        libelle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w800,
                          color: modeSombre
                              ? Colors.white
                              : const Color(0xFF0F172A),
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: couleurFond,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        libelle == 'Stage validé'
                            ? 'Validé'
                            : libelle == 'Validation universitaire en attente'
                            ? 'En validation'
                            : libelle == 'Clôture en cours'
                            ? 'Clôturé'
                            : 'En cours',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: couleurTexte,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  sousTitre,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: modeSombre
                        ? const Color(0xFF94A3B8)
                        : const Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  bool _correspondAuFiltre(
    Map<String, dynamic> stage,
    Map<String, dynamic>? completion,
    Map<String, dynamic>? resultat,
  ) {
    if (_filtreSuiviStage == 'Tous') return true;
    final libelle = _libelleSuivi(stage, completion, resultat);
    return switch (_filtreSuiviStage) {
      'En cours' => libelle == 'Stage en cours',
      'Clôturé' || 'Clôture' => libelle == 'Clôture en cours',
      'En cours de validation' ||
      'Validation' => libelle == 'Validation universitaire en attente',
      'Validé' || 'Validés' => libelle == 'Stage validé',
      _ => true,
    };
  }

  String _libelleSuivi(
    Map<String, dynamic> stage,
    Map<String, dynamic>? completion,
    Map<String, dynamic>? resultat,
  ) {
    final processus = _map(resultat?['administrative_process']);
    final transmission = _map(processus['university_transmission']);
    final transmissionStatus = transmission['status']?.toString().toUpperCase();
    if (const {'VALIDE', 'ARCHIVE'}.contains(transmissionStatus) ||
        processus['status']?.toString().toUpperCase() == 'COMPLETED') {
      return 'Stage validé';
    }
    final statutCloture = completion?['status']?.toString().toUpperCase();
    if (statutCloture == 'VALIDE') {
      return 'Validation universitaire en attente';
    }
    if (completion != null ||
        const {
          'TERMINEE',
          'CLOTUREE',
        }.contains(stage['assignment_status']?.toString().toUpperCase())) {
      return 'Clôture en cours';
    }
    return 'Stage en cours';
  }

  Map<String, dynamic>? _parAffectation(
    List<Map<String, dynamic>> items,
    String? reference,
  ) {
    if (reference == null || reference.isEmpty) return null;
    for (final item in items) {
      if (_map(item['assignment'])['uuid']?.toString() == reference ||
          item['assignment_uuid']?.toString() == reference) {
        return item;
      }
    }
    return null;
  }

  static List<Map<String, dynamic>> _maps(Object? valeur) => valeur is List
      ? valeur.whereType<Map>().map(Map<String, dynamic>.from).toList()
      : <Map<String, dynamic>>[];

  static Map<String, dynamic> _map(Object? valeur) =>
      valeur is Map ? Map<String, dynamic>.from(valeur) : <String, dynamic>{};

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
