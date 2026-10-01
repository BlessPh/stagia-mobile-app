import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/mocks/depot_mock_etudiant.dart';
import '../../../../core/network/client_api_http.dart';
import '../../../../core/network/configuration_api.dart';
import '../../../../core/network/source_etudiant_distante.dart';
import '../../../journal/presentation/pages/journal_page.dart';
import '../../../messagerie/presentation/pages/messagerie_page.dart';
import '../../../notifications/presentation/pages/notifications_page.dart';
import '../../data/datasources/source_stage_distante.dart';
import '../../data/mappers/mappeur_campagne_stage_api.dart';
import '../routes/routes_stage.dart';
import '../widgets/barre_recherche_stages.dart';
import '../widgets/carte_candidature_moderne.dart';
import '../widgets/carte_stage_explorer.dart';
import '../widgets/onglets_trois_stages.dart';

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

  @override
  void initState() {
    super.initState();
    _chargement = _charger();
    if (ConfigurationApi.utiliserDonneesMockees) {
      DepotMockEtudiant.changements.addListener(_onChangementDonnees);
    }
  }

  @override
  void dispose() {
    if (ConfigurationApi.utiliserDonneesMockees) {
      DepotMockEtudiant.changements.removeListener(_onChangementDonnees);
    }
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

  Future<List<Map<String, dynamic>>> _charger() => Future.wait([
    _sourceEtudiant.stages(),
    _sourceStages.campagnes(),
    _sourceEtudiant.candidatures(),
  ]);

  Future<void> _actualiser() async {
    final futur = _charger();
    setState(() => _chargement = futur);
    await futur;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: _buildAppBar(context),
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
            const Divider(height: 1, color: Color(0xFFE2E8F0)),

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

                  final stagesListe =
                      (donneesStages['items'] as List?)
                          ?.whereType<Map>()
                          .map(Map<String, dynamic>.from)
                          .toList() ??
                      [];
                  Map<String, dynamic>? stageActif;
                  for (final stage in stagesListe) {
                    final statut =
                        (stage['assignment_status'] ?? stage['statut'])
                            ?.toString()
                            .toUpperCase();
                    if (statut == 'ACTIVE' || statut == 'EN_COURS') {
                      stageActif = stage;
                      break;
                    }
                  }

                  return RefreshIndicator(
                    color: const Color(0xFF1D61F2),
                    onRefresh: _actualiser,
                    child: switch (_ongletActif) {
                      0 => _buildOngletEnCours(stageActif),
                      1 => _buildOngletExplorer(donneesCampagnes),
                      2 => _buildOngletCandidatures(donneesCandidatures),
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

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      automaticallyImplyLeading: false,
      backgroundColor: const Color(0xFFF8FAFC),
      elevation: 0,
      surfaceTintColor: Colors.transparent,
      title: Text(
        'Mes stages',
        style: GoogleFonts.inter(
          fontSize: 22,
          fontWeight: FontWeight.w800,
          color: const Color(0xFF0F172A),
          letterSpacing: -0.3,
        ),
      ),
      actions: [
        // Bouton Chat avec badge
        Stack(
          clipBehavior: Clip.none,
          children: [
            IconButton(
              tooltip: 'Messages',
              onPressed: () => Navigator.of(context, rootNavigator: true).push(
                MaterialPageRoute<void>(builder: (_) => const MessageriePage()),
              ),
              icon: const Icon(
                CupertinoIcons.chat_bubble_2,
                color: Color(0xFF0F172A),
                size: 24,
              ),
            ),
            if (ConfigurationApi.utiliserDonneesMockees)
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
                  child: const Text(
                    '3',
                    textAlign: TextAlign.center,
                    style: TextStyle(
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

        // Bouton Notifications avec badge
        Stack(
          clipBehavior: Clip.none,
          children: [
            IconButton(
              tooltip: 'Notifications',
              onPressed: () => Navigator.of(context, rootNavigator: true).push(
                MaterialPageRoute<void>(
                  builder: (_) => const NotificationsPage(),
                ),
              ),
              icon: const Icon(
                CupertinoIcons.bell,
                color: Color(0xFF0F172A),
                size: 25,
              ),
            ),
            if (ConfigurationApi.utiliserDonneesMockees)
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
                  child: const Text(
                    '5',
                    textAlign: TextAlign.center,
                    style: TextStyle(
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
  Widget _buildOngletEnCours(Map<String, dynamic>? stage) {
    if (stage == null) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(32),
        children: [
          Center(
            child: Text(
              "Vous n'avez aucun stage en cours.",
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(color: const Color(0xFF64748B)),
            ),
          ),
        ],
      );
    }

    final entreprise = stage['hospital_name']?.toString() ?? 'Non renseigné';
    final role = stage['unit_name']?.toString() ?? '';
    final superviseur = (stage['rotations'] as List?)?.isNotEmpty == true
        ? (stage['rotations'][0]['supervisor_name']?.toString() ??
              'Non renseigné')
        : 'Non renseigné';
    final ville = stage['ville']?.toString() ?? 'Non renseigné';
    final departement = stage['unit_name']?.toString() ?? 'Non renseigné';
    final initiales = entreprise
        .split(RegExp(r'\s+'))
        .where((mot) => mot.isNotEmpty)
        .take(2)
        .map((mot) => mot[0].toUpperCase())
        .join();
    final dateDebut = DateTime.tryParse(stage['date_debut']?.toString() ?? '');
    final dateFin = DateTime.tryParse(stage['date_fin']?.toString() ?? '');
    final totalJours = dateDebut != null && dateFin != null
        ? dateFin.difference(dateDebut).inDays.abs() + 1
        : 0;
    final joursEffectues = dateDebut != null
        ? DateTime.now().difference(dateDebut).inDays.clamp(0, totalJours)
        : 0;
    final progression = totalJours > 0 ? joursEffectues / totalJours : 0.0;
    final periode = dateDebut != null && dateFin != null
        ? '${_formaterDateStage(dateDebut)} — ${_formaterDateStage(dateFin)}'
        : 'Non renseignée';

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
      children: [
        // Carte principale du stage actif
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFE2E8F0)),
            boxShadow: const [
              BoxShadow(
                color: Color(0x06000000),
                blurRadius: 12,
                offset: Offset(0, 3),
              ),
            ],
          ),
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Logo + Nom + Badge En cours
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: const Color(0xFF4F46E5),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      initiales.isEmpty ? '?' : initiales,
                      style: GoogleFonts.inter(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          entreprise,
                          style: GoogleFonts.inter(
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF0F172A),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          role,
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: const Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4.5,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFDCFCE7),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      'En cours',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF16A34A),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 18),

              // Progression du stage
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Progression du stage',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF64748B),
                    ),
                  ),
                  Text(
                    '$joursEffectues jours / $totalJours jours',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF0F172A),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Barre de progression
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: progression,
                  minHeight: 7,
                  backgroundColor: const Color(0xFFE2E8F0),
                  valueColor: const AlwaysStoppedAnimation<Color>(
                    Color(0xFF1D61F2),
                  ),
                ),
              ),

              const SizedBox(height: 6),

              Text(
                '${(progression * 100).round()}% du stage effectué',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFF94A3B8),
                ),
              ),

              const SizedBox(height: 12),
              const Divider(height: 1, color: Color(0xFFF1F5F9)),
              const SizedBox(height: 12),

              // Période
              Row(
                children: [
                  const Icon(
                    CupertinoIcons.calendar,
                    size: 16,
                    color: Color(0xFF1D61F2),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Période :  ',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF64748B),
                    ),
                  ),
                  Text(
                    periode,
                    style: GoogleFonts.inter(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF0F172A),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: 14),

        // Deux cartes côte à côte : Superviseur & Lieu
        Row(
          children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Superviseur',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFF94A3B8),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      superviseur,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF0F172A),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Lieu',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFF94A3B8),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      ville,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF0F172A),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 12),

        // Carte Département
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Département',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFF94A3B8),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                departement,
                style: GoogleFonts.inter(
                  fontSize: 14.5,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF0F172A),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 22),

        // Titre Outils de suivi
        Text(
          'Outils de suivi',
          style: GoogleFonts.inter(
            fontSize: 17,
            fontWeight: FontWeight.w800,
            color: const Color(0xFF0F172A),
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

        const SizedBox(height: 14),

        // Carte Alerte Rapport mi-parcours (information encore mockée)
        if (ConfigurationApi.utiliserDonneesMockees)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF7ED),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xFFFFEDD5)),
            ),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: const BoxDecoration(
                    color: Color(0xFFF97316),
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: const Icon(
                    CupertinoIcons.time,
                    color: Colors.white,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Rapport mi-parcours',
                        style: GoogleFonts.inter(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Rendu attendu dans 12 jours',
                        style: GoogleFonts.inter(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  CupertinoIcons.chevron_right,
                  color: Color(0xFF94A3B8),
                  size: 18,
                ),
              ],
            ),
          ),
      ],
    );
  }

  String _formaterDateStage(DateTime date) {
    const mois = [
      'janv.',
      'févr.',
      'mars',
      'avr.',
      'mai',
      'juin',
      'juil.',
      'août',
      'sept.',
      'oct.',
      'nov.',
      'déc.',
    ];
    return '${date.day} ${mois[date.month - 1]} ${date.year}';
  }

  Widget _buildCarteOutilSuivi({
    required IconData icone,
    required Color couleurIcone,
    required String titre,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          height: 90,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE2E8F0)),
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
                  color: const Color(0xFF0F172A),
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
  Widget _buildOngletExplorer(Map<String, dynamic> campagnesData) {
    final campaignsApi =
        (campagnesData['campaigns'] as List?)
            ?.whereType<Map>()
            .map(Map<String, dynamic>.from)
            .toList() ??
        [];

    if (campaignsApi.isEmpty && !ConfigurationApi.utiliserDonneesMockees) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(32),
        children: [
          Center(
            child: Text(
              'Aucune campagne de stage disponible.',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(color: const Color(0xFF64748B)),
            ),
          ),
        ],
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
            final mode = c['mode'] is Map
                ? Map<String, dynamic>.from(c['mode'] as Map)
                : const <String, dynamic>{};
            final autoriseReservationAutonome =
                mode['self_reservation_allowed'] != false;
            final nbPlaces =
                c['available_places']?.toString() ??
                (hopitaux.isNotEmpty ? '${hopitaux.length} hôpitaux' : '');
            final premierHopital = hopitaux.isNotEmpty
                ? (hopitaux.first['hospital'] is Map
                      ? hopitaux.first['hospital']['name']?.toString()
                      : null)
                : null;
            final entreprise = premierHopital ?? '';
            final ville =
                hopitaux.isNotEmpty && hopitaux.first['hospital'] is Map
                ? (hopitaux.first['hospital']['city']?.toString() ?? '')
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
              'libelleAction': autoriseReservationAutonome
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
              ),
              const SizedBox(width: 8),
              _buildFiltreChip(
                titre: 'Informatique',
                actif: _filtreCategorie == 'Informatique',
              ),
              const SizedBox(width: 8),
              _buildFiltreChip(
                titre: 'Finance',
                actif: _filtreCategorie == 'Finance',
              ),
              const SizedBox(width: 8),
              _buildFiltreChip(
                titre: 'Santé',
                actif: _filtreCategorie == 'Santé',
              ),
              const SizedBox(width: 8),
              // Bouton sliders / réglages
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(19),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                alignment: Alignment.center,
                child: const Icon(
                  CupertinoIcons.slider_horizontal_3,
                  size: 18,
                  color: Color(0xFF0F172A),
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
              child: Text(
                'Aucun stage ne correspond à vos critères.',
                style: GoogleFonts.inter(color: const Color(0xFF64748B)),
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

  Widget _buildFiltreChip({required String titre, required bool actif}) {
    return GestureDetector(
      onTap: () => setState(() => _filtreCategorie = titre),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8.5),
        decoration: BoxDecoration(
          color: actif ? const Color(0xFF1D61F2) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: actif ? const Color(0xFF1D61F2) : const Color(0xFFE2E8F0),
          ),
        ),
        child: Text(
          titre,
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: actif ? FontWeight.w700 : FontWeight.w500,
            color: actif ? Colors.white : const Color(0xFF64748B),
          ),
        ),
      ),
    );
  }

  // ==========================================
  // ONGLET 3 : CANDIDATURES (Fidèle à l'Image 4)
  // ==========================================
  Widget _buildOngletCandidatures(Map<String, dynamic> candidaturesData) {
    final itemsRaw =
        (candidaturesData['items'] as List?)
            ?.whereType<Map>()
            .map(Map<String, dynamic>.from)
            .toList() ??
        [];

    if (itemsRaw.isEmpty && !ConfigurationApi.utiliserDonneesMockees) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(32),
        children: [
          Center(
            child: Text(
              "Vous n'avez aucune candidature.",
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(color: const Color(0xFF64748B)),
            ),
          ),
        ],
      );
    }

    final List<Map<String, dynamic>> candidaturesListes = itemsRaw.isNotEmpty
        ? itemsRaw.map((item) {
            final workflowStatus =
                item['workflow_status']?.toString().toUpperCase() ??
                item['statut']?.toString().toUpperCase() ??
                '';
            final nomHopital =
                item['hospital_name']?.toString() ??
                item['entreprise']?.toString() ??
                '';
            final titreCampagne =
                item['campaign_title']?.toString() ??
                item['titre']?.toString() ??
                '';
            final dateSoumission =
                item['submitted_at']?.toString() ??
                item['date']?.toString() ??
                '';

            final (statutType, label) = switch (workflowStatus) {
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
              'STAGE_EN_COURS' || 'STAGE_PLANIFIE' => (
                StatutCandidatureType.admis,
                'Admis en stage',
              ),
              'CANDIDATURE_REFUSEE' ||
              'REFUSEE' => (StatutCandidatureType.refusee, 'Refusée'),
              'RESERVATION_EXPIREE' => (
                StatutCandidatureType.refusee,
                'Expirée',
              ),
              'ANNULEE' => (StatutCandidatureType.refusee, 'Annulée'),
              _ => (StatutCandidatureType.enAttente, workflowStatus),
            };

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
                  : 'Soumis le $dateSoumission',
              'statutType': statutType,
              'statutLabel': label,
            };
          }).toList()
        : [
            {
              'initiale': 'H',
              'bg': const Color(0xFFE0F2FE),
              'textColor': const Color(0xFF0284C7),
              'entreprise': 'Hôpital Général de Référence',
              'titre': 'Stage médical D4',
              'dateTexte': 'Soumis le 26 Sept 2026',
              'statutType': StatutCandidatureType.enAttente,
              'statutLabel': 'Décision en attente',
            },
          ];

    final query = _rechercheController.text.trim().toLowerCase();
    final filtrer = candidaturesListes.where((c) {
      final statut = c['statutType'] as StatutCandidatureType;
      final matchStatut = switch (_filtreCandidature) {
        'En attente' => statut == StatutCandidatureType.enAttente,
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

    final nbTotal = candidaturesListes.length;
    final nbAcceptees = candidaturesListes
        .where(
          (c) =>
              c['statutType'] == StatutCandidatureType.acceptee ||
              c['statutType'] == StatutCandidatureType.confirme ||
              c['statutType'] == StatutCandidatureType.admis,
        )
        .length;
    final nbEnAttente = candidaturesListes
        .where((c) => c['statutType'] == StatutCandidatureType.enAttente)
        .length;

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 28),
      children: [
        // Bannière récapitulative fine & élégante
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: '$nbTotal candidature${nbTotal > 1 ? 's' : ''} ',
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF64748B),
                    fontSize: 13,
                  ),
                ),
                const TextSpan(
                  text: '• ',
                  style: TextStyle(color: Color(0xFFCBD5E1), fontSize: 13),
                ),
                TextSpan(
                  text: '$nbAcceptees acceptée${nbAcceptees > 1 ? 's' : ''} ',
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF16A34A),
                    fontSize: 13,
                  ),
                ),
                const TextSpan(
                  text: '• ',
                  style: TextStyle(color: Color(0xFFCBD5E1), fontSize: 13),
                ),
                TextSpan(
                  text: '$nbEnAttente en attente',
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF2563EB),
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
            _buildFiltreCandidatureChip('Toutes'),
            const SizedBox(width: 8),
            _buildFiltreCandidatureChip('En attente'),
            const SizedBox(width: 8),
            _buildFiltreCandidatureChip('Acceptée'),
          ],
        ),

        const SizedBox(height: 16),

        // Liste des cartes de candidatures
        if (filtrer.isEmpty)
          Center(
            child: Padding(
              padding: const EdgeInsets.all(32.0),
              child: Text(
                'Aucune candidature ne correspond à vos filtres.',
                style: GoogleFonts.inter(color: const Color(0xFF64748B)),
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
                onTap: () {
                  Navigator.of(context).pushNamed(RoutesStage.candidatures);
                },
              ),
            ),
      ],
    );
  }

  Widget _buildFiltreCandidatureChip(String titre) {
    final actif = _filtreCandidature == titre;
    return GestureDetector(
      onTap: () => setState(() => _filtreCandidature = titre),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8.5),
        decoration: BoxDecoration(
          color: actif ? const Color(0xFF1D61F2) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: actif ? const Color(0xFF1D61F2) : const Color(0xFFE2E8F0),
          ),
        ),
        child: Text(
          titre,
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: actif ? FontWeight.w700 : FontWeight.w500,
            color: actif ? Colors.white : const Color(0xFF64748B),
          ),
        ),
      ),
    );
  }
}
