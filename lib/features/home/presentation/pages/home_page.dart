import 'package:flutter/material.dart';
import '../../../../core/mocks/depot_mock_etudiant.dart';
import '../../../../core/network/client_api_http.dart';
import '../../../../core/network/configuration_api.dart';
import '../../../../core/network/source_etudiant_distante.dart';
import '../../../../core/services/session_authentification_service.dart';
import '../../../../core/services/suivi_stage_service.dart';
import '../../../../core/widgets/contenu_adaptatif.dart';
import '../../../planning/domain/entities/tache_planning.dart';
import '../../../stage/data/datasources/source_stage_distante.dart';
import '../../../stage/data/mappers/mappeur_campagne_stage_api.dart';
import '../../../stage/domain/entities/campagne_stage.dart';
import '../../../stage/domain/entities/suivi_candidature_stage.dart';
import '../widgets/carousel_accueil.dart';
import '../widgets/home_skeleton_widgets.dart';
import '../widgets/section_stage_disponible_accueil.dart';
import '../widgets/section_stage_en_cours_accueil.dart';
import '../widgets/section_taches_jour_accueil.dart';
import 'home_shared_widgets.dart';

class HomePage extends StatefulWidget {
  const HomePage({
    this.onOuvrirStages,
    this.onOuvrirCampagnes,
    this.onOuvrirCandidatures,
    super.key,
  });

  final VoidCallback? onOuvrirStages;
  final VoidCallback? onOuvrirCampagnes;
  final VoidCallback? onOuvrirCandidatures;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final _source = SourceEtudiantDistante(ClientApiHttp());
  final _sourceStages = SourceStageDistante(ClientApiHttp());

  // États de chargement et données pour chaque section
  bool _chargementProfil = true;
  Map<String, dynamic> _donneesProfil = const {};
  Map<String, dynamic> _identiteSession = const {};

  bool _chargementTaches = true;
  List<TachePlanning> _taches = [];

  bool _chargementCampagnes = true;
  CampagneStage? _campagneDisponible;
  SuiviCandidatureStage? _suiviCandidature;

  bool _chargementDashboard = true;
  Map<String, dynamic> _donneesDashboard = const {};

  @override
  void initState() {
    super.initState();
    if (ConfigurationApi.utiliserDonneesMockees) {
      DepotMockEtudiant.changements.addListener(_donneesLocalesModifiees);
    }
    SuiviStageService.changements.addListener(_workflowStageModifie);
    _initialiserChargements();
  }

  @override
  void dispose() {
    if (ConfigurationApi.utiliserDonneesMockees) {
      DepotMockEtudiant.changements.removeListener(_donneesLocalesModifiees);
    }
    SuiviStageService.changements.removeListener(_workflowStageModifie);
    super.dispose();
  }

  void _donneesLocalesModifiees() {
    if (mounted) _initialiserChargements();
  }

  void _workflowStageModifie() {
    if (mounted) {
      _chargerCampagnes();
      _chargerDashboard();
    }
  }

  void _initialiserChargements() {
    _chargerProfil();
    _chargerTaches();
    _chargerCampagnes();
    _chargerDashboard();
  }

  Future<void> _chargerProfil() async {
    try {
      final identite = await SessionAuthentificationService.identite();
      final profil = await _source.profil();
      if (mounted) {
        setState(() {
          _identiteSession = identite;
          _donneesProfil = profil;
          _chargementProfil = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _chargementProfil = false;
        });
      }
    }
  }

  Future<void> _chargerTaches() async {
    try {
      final res = await _source.taches();
      final items =
          (res['items'] as List?)
              ?.whereType<Map>()
              .where((m) {
                final statut = (m['statut'] ?? m['status'])
                    ?.toString()
                    .toUpperCase();
                final echeance = DateTime.tryParse(
                  (m['date_echeance'] ?? m['due_date'])?.toString() ?? '',
                );
                return (statut == 'A_FAIRE' || statut == 'EN_COURS') &&
                    echeance != null;
              })
              .map(
                (m) => TachePlanning.depuisTacheStage(
                  Map<String, dynamic>.from(m),
                ),
              )
              .toList() ??
          <TachePlanning>[];
      if (mounted) {
        setState(() {
          _taches = items;
          _chargementTaches = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _taches = const [];
          _chargementTaches = false;
        });
      }
    }
  }

  Future<void> _chargerCampagnes() async {
    var campagnes = <CampagneStage>[];
    var suivis = <SuiviCandidatureStage>[];
    SuiviCandidatureStage? suivi;

    try {
      final res = await _sourceStages.campagnes();
      final list = listeApi(res['campaigns']);
      campagnes = list.map(MappeurCampagneStageApi.depuisJson).toList();
    } catch (_) {}

    try {
      final admissions = await _source.admissions();
      final items = listeApi(admissions['items']);
      if (items.isNotEmpty) {
        suivis = items.map(SuiviCandidatureStage.depuisAdmission).toList();
        suivi = suivis.firstWhere(
          (element) => !element.estTermine,
          orElse: () => suivis.first,
        );
      }
    } catch (_) {}

    final campagnesNonEngagees = suivis.isEmpty
        ? campagnes
        : campagnes
              .where(
                (campagne) => !suivis.any(
                  (suiviExistant) => suiviExistant.concerne(campagne),
                ),
              )
              .toList();

    if (mounted) {
      setState(() {
        _campagneDisponible = campagnesNonEngagees.isEmpty
            ? null
            : campagnesNonEngagees.first;
        _suiviCandidature = suivi;
        _chargementCampagnes = false;
      });
    }
  }

  Future<void> _chargerDashboard() async {
    try {
      final res = await _source.tableauDeBord();
      if (mounted) {
        setState(() {
          _donneesDashboard = res;
          _chargementDashboard = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _chargementDashboard = false;
        });
      }
    }
  }

  Future<void> _actualiser() async {
    setState(() {
      _chargementProfil = true;
      _chargementTaches = true;
      _chargementCampagnes = true;
      _chargementDashboard = true;
    });
    await Future.wait([
      _chargerProfil(),
      _chargerTaches(),
      _chargerCampagnes(),
      _chargerDashboard(),
    ]);
  }

  Map<String, dynamic> _construireIdentiteEtudiant() {
    final etudiant = <String, dynamic>{};
    void ajouterIdentite(Map<String, dynamic> source) {
      for (final entree in source.entries) {
        if (entree.value != null && entree.value.toString().trim().isNotEmpty) {
          etudiant[entree.key] = entree.value;
        }
      }
    }

    ajouterIdentite(mapApi(_donneesProfil['user']));
    ajouterIdentite(mapApi(_donneesProfil['student']));
    ajouterIdentite(mapApi(_donneesDashboard['user']));
    ajouterIdentite(mapApi(_donneesDashboard['student']));
    for (final entree in _identiteSession.entries) {
      if (entree.value.toString().trim().isNotEmpty) {
        etudiant[entree.key] = entree.value;
      }
    }
    return etudiant;
  }

  @override
  Widget build(BuildContext context) {
    final marge = MediaQuery.sizeOf(context).width < 360 ? 14.0 : 18.0;

    // AppBar : Skeleton tant que le profil n'est pas chargé
    final PreferredSizeWidget appBar = _chargementProfil
        ? const EnTeteAccueilSkeleton()
        : EnTeteAccueil(etudiant: _construireIdentiteEtudiant());

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: appBar,
      body: ContenuAdaptatif(
        enfant: RefreshIndicator(
          color: const Color(0xFFFF7417),
          onRefresh: _actualiser,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.fromLTRB(marge, 12, marge, 28),
            children: [
              // 1. Carousel d'accueil (avec timer autonome, s'affiche ou skeleton si besoin)
              const CarouselAccueil(),
              const SizedBox(height: 20),

              // 2. Tâches du jour : Skeleton granulaire si en cours de chargement
              if (_chargementTaches)
                const SectionTachesAccueilSkeleton()
              else if (_taches.isNotEmpty)
                SectionTachesJourAccueil(tachesPersonnalisees: _taches),
              if (_chargementTaches || _taches.isNotEmpty)
                const SizedBox(height: 20),

              // 3. Stage disponible : Skeleton granulaire si en cours de chargement
              if (_chargementCampagnes)
                const SectionStageDisponibleSkeleton()
              else if (_suiviCandidature != null)
                SectionStageDisponibleAccueil(
                  campagne: _suiviCandidature!.campagne,
                  titreSection: 'Suivi de candidature',
                  libelleCompteur: _suiviCandidature!.estTermine
                      ? 'Dossier clôturé'
                      : 'Dossier en cours',
                  statutAffiche: _suiviCandidature!.libelleStatut,
                  messageStatut: _suiviCandidature!.message,
                  libelleInformationSecondaire: 'Hôpital',
                  valeurInformationSecondaire:
                      _suiviCandidature!.nomHopital.isEmpty
                      ? 'À déterminer'
                      : _suiviCandidature!.nomHopital,
                  afficherNombreHopitaux: false,
                  libelleAction: 'Suivre mon dossier',
                  estSuiviCandidature: true,
                  onVoirDetails:
                      widget.onOuvrirCandidatures ?? widget.onOuvrirStages,
                ),
              if (!_chargementCampagnes &&
                  _suiviCandidature != null &&
                  _campagneDisponible != null)
                const SizedBox(height: 20),
              if (!_chargementCampagnes && _campagneDisponible != null)
                SectionStageDisponibleAccueil(
                  campagne: _campagneDisponible,
                  onVoirDetails:
                      widget.onOuvrirCampagnes ?? widget.onOuvrirStages,
                ),
              if (_chargementCampagnes ||
                  _campagneDisponible != null ||
                  _suiviCandidature != null)
                const SizedBox(height: 20),

              // 4. Stage en cours : Skeleton granulaire si en cours de chargement
              _chargementDashboard
                  ? const SectionStageEnCoursSkeleton()
                  : _buildSectionStageEnCours(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionStageEnCours() {
    final stage = mapApi(_donneesDashboard['current_stage']);
    if (stage.isEmpty) return const SizedBox.shrink();
    final statut = stage['statut']?.toString().toUpperCase() ?? '';
    if (statut != 'ACTIVE' && statut != 'EN_COURS') {
      return const SizedBox.shrink();
    }
    final progression = _progressionStage(
      stage['date_debut'],
      stage['date_fin'],
    );

    final totalRotations = stage['total_rotations'] is num
        ? (stage['total_rotations'] as num).toInt()
        : 0;
    final journauxValides = stage['journaux_valides'] is num
        ? (stage['journaux_valides'] as num).toInt()
        : 0;

    return SectionStageEnCoursAccueil(
      titreCampagne: stage['campaign_title']?.toString() ?? '',
      nomEtablissement: stage['hospital_name']?.toString() ?? '',
      serviceActuel: stage['unit_name']?.toString() ?? '',
      joursEffectues: progression.$1,
      totalJours: progression.$2,
      servicesEffectues: journauxValides,
      totalServices: totalRotations,
      joursRestantsService: _joursRestants(stage['date_fin']) ?? 0,
      nomEncadreur: stage['supervisor_name']?.toString() ?? '',
      onTap: widget.onOuvrirStages,
    );
  }

  (int, int) _progressionStage(Object? debutBrut, Object? finBrut) {
    final debut = DateTime.tryParse(debutBrut?.toString() ?? '');
    final fin = DateTime.tryParse(finBrut?.toString() ?? '');
    if (debut == null || fin == null || fin.isBefore(debut)) return (0, 0);

    final total = fin.difference(debut).inDays + 1;
    final joursEcoules = DateTime.now().difference(debut).inDays + 1;
    return (joursEcoules.clamp(0, total).toInt(), total);
  }

  int? _joursRestants(Object? valeur) {
    final fin = DateTime.tryParse(valeur?.toString() ?? '');
    if (fin == null) return null;
    final aujourdHui = DateTime.now();
    final debutJour = DateTime(
      aujourdHui.year,
      aujourdHui.month,
      aujourdHui.day,
    );
    final finJour = DateTime(fin.year, fin.month, fin.day);
    final jours = finJour.difference(debutJour).inDays;
    return jours < 0 ? 0 : jours;
  }
}
