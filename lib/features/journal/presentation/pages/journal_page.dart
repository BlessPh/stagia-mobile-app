import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';
import '../../../../core/network/client_api_http.dart';
import '../../../../core/network/configuration_api.dart';
import '../../../../core/network/reponse_api.dart';
import '../../../../core/network/source_etudiant_distante.dart';
import '../../../messagerie/presentation/pages/messagerie_page.dart';
import '../../../notifications/presentation/pages/notifications_page.dart';
import 'calendrier_presence_page.dart';
import 'detail_journal_page.dart';
import 'fiche_evaluation_page.dart';
import 'mes_journaux_page.dart';
import 'mes_taches_page.dart';
import '../../../../core/services/suivi_stage_service.dart';
import 'saisir_journal_page.dart';
import '../widgets/barre_recherche_journal.dart';
import '../widgets/calendrier_mois_entier.dart';
import '../widgets/carte_echeance_tache.dart';
import '../widgets/en_tete_journal.dart';
import '../widgets/onglets_journal.dart';

class JournalPage extends StatefulWidget {
  const JournalPage({super.key});

  @override
  State<JournalPage> createState() => _JournalPageState();
}

class _JournalPageState extends State<JournalPage> {
  final _source = SourceEtudiantDistante(ClientApiHttp());
  int _indexOnglet = 0;
  final TextEditingController _rechercheController = TextEditingController();

  // État onglet Tâches
  late DateTime _dateSelectionneeTaches;

  // État onglet Journal
  String _filtreJournal = 'Aujourd\'hui';

  // État onglet Evaluations
  String _filtreEvaluation = 'Tous';

  int _nombreTachesAujourdhui = 0;

  // État pointage de présence
  bool _pointageEnCours = false;
  final Set<String> _feedbacksLectureEnCours = <String>{};

  late Future<List<Map<String, dynamic>>> _chargement;

  @override
  void initState() {
    super.initState();
    _dateSelectionneeTaches = DateTime.now();
    _chargement = _charger();
    SuiviStageService.ongletJournalDemande.addListener(_onChangementOngletJournalDemande);
    _verifierOngletJournalDemande();
  }

  void _verifierOngletJournalDemande() {
    final index = SuiviStageService.ongletJournalDemande.value;
    if (index != null && index >= 0 && index <= 3) {
      if (mounted && _indexOnglet != index) {
        setState(() => _indexOnglet = index);
      }
    }
  }

  void _onChangementOngletJournalDemande() {
    _verifierOngletJournalDemande();
  }

  @override
  void dispose() {
    SuiviStageService.ongletJournalDemande.removeListener(_onChangementOngletJournalDemande);
    _rechercheController.dispose();
    super.dispose();
  }

  Future<List<Map<String, dynamic>>> _charger() async {
    final aujourdHui = DateTime.now();
    final premierJour = DateTime(aujourdHui.year, aujourdHui.month);
    final dernierJour = DateTime(aujourdHui.year, aujourdHui.month + 1, 0);
    final reponses = await Future.wait([
      _source.journal(perPage: 100),
      _source.presences(
        dateFrom: _dateApi(premierJour),
        dateTo: _dateApi(dernierJour),
        perPage: 100,
      ),
      _source.evaluations(perPage: 100),
      _source.contexteExecution(),
      _source.taches(perPage: 100),
      _source.feedbacks(perPage: 100),
    ]);
    final taches = _items(reponses[4]['items']);
    final nombre = taches.where((tache) {
      final date = DateTime.tryParse(
        (tache['date_echeance'] ?? tache['due_date'])?.toString() ?? '',
      );
      return date != null &&
          date.year == aujourdHui.year &&
          date.month == aujourdHui.month &&
          date.day == aujourdHui.day;
    }).length;
    if (mounted) {
      setState(() => _nombreTachesAujourdhui = nombre);
    }
    return reponses;
  }

  Future<void> _actualiser() async {
    final futur = _charger();
    setState(() => _chargement = futur);
    await futur;
  }

  Future<void> _actionnerPointage(String action) async {
    if (_pointageEnCours) return;
    if (action != 'ARRIVEE' && action != 'DEPART') return;
    setState(() => _pointageEnCours = true);
    try {
      late final Map<String, dynamic> resultat;
      if (action == 'ARRIVEE') {
        resultat = await _source.pointerArrivee();
      } else {
        resultat = await _source.pointerDepart();
      }
      await _actualiser();
      if (mounted) {
        final message = resultat['message']?.toString().trim() ?? '';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              message.isNotEmpty
                  ? message
                  : action == 'ARRIVEE'
                  ? 'Arrivée enregistrée.'
                  : 'Départ enregistré.',
            ),
            backgroundColor: action == 'ARRIVEE'
                ? const Color(0xFF16A34A)
                : const Color(0xFFF97316),
          ),
        );
      }
    } on ErreurApi catch (erreur) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(erreur.message),
            backgroundColor: const Color(0xFFDC2626),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _pointageEnCours = false);
    }
  }

  Future<void> _marquerFeedbackLu(String uuid) async {
    if (uuid.isEmpty || _feedbacksLectureEnCours.contains(uuid)) return;
    setState(() => _feedbacksLectureEnCours.add(uuid));
    try {
      final resultat = await _source.marquerFeedbackLu(uuid);
      await _actualiser();
      if (mounted) {
        final message = resultat['message']?.toString().trim() ?? '';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              message.isNotEmpty ? message : 'Feedback marqué comme lu.',
            ),
          ),
        );
      }
    } on ErreurApi catch (erreur) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(erreur.message),
            backgroundColor: const Color(0xFFDC2626),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _feedbacksLectureEnCours.remove(uuid));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final modeSombre = Theme.of(context).brightness == Brightness.dark;
    final fondPage = modeSombre
        ? const Color(0xFF0F172A)
        : const Color(0xFFF8FAFC);
    final separateurCouleur = modeSombre
        ? const Color(0xFF334155)
        : const Color(0xFFE2E8F0);

    return Scaffold(
      backgroundColor: fondPage,
      appBar: EnTeteJournal(
        nombreTachesAujourdhui: _nombreTachesAujourdhui,
        onOuvrirChat: () => Navigator.of(
          context,
          rootNavigator: true,
        ).push(MaterialPageRoute<void>(builder: (_) => const MessageriePage())),
        onOuvrirNotifications: () =>
            Navigator.of(context, rootNavigator: true).push(
              MaterialPageRoute<void>(
                builder: (_) => const NotificationsPage(),
              ),
            ),
        onOuvrirTaches: () {
          setState(() => _indexOnglet = 0);
        },
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Barre de recherche stylée moderne
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              child: BarreRechercheJournal(
                controller: _rechercheController,
                onChanged: (_) => setState(() {}),
              ),
            ),

            // TabBar à 4 onglets : Mes tâches, Présences, Evaluations, Journal
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: OngletsJournal(
                indexActif: _indexOnglet,
                onChangementOnglet: (index) {
                  setState(() => _indexOnglet = index);
                },
              ),
            ),
            Divider(height: 1, color: separateurCouleur),

            // Contenu de l'onglet actif
            Expanded(
              child: FutureBuilder<List<Map<String, dynamic>>>(
                future: _chargement,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFFFF7417),
                      ),
                    );
                  }
                  final reponses = snapshot.data ?? [{}, {}, {}, {}, {}, {}];
                  final journalData = reponses.isNotEmpty
                      ? reponses[0]
                      : <String, dynamic>{};
                  final presencesData = reponses.length > 1
                      ? reponses[1]
                      : <String, dynamic>{};
                  final evaluationsData = reponses.length > 2
                      ? reponses[2]
                      : <String, dynamic>{};
                  final pointageData = reponses.length > 3
                      ? reponses[3]
                      : <String, dynamic>{};
                  final tachesData = reponses.length > 4
                      ? reponses[4]
                      : <String, dynamic>{};
                  final feedbacksData = reponses.length > 5
                      ? reponses[5]
                      : <String, dynamic>{};

                  return RefreshIndicator(
                    color: const Color(0xFF1D61F2),
                    onRefresh: _actualiser,
                    child: switch (_indexOnglet) {
                      0 => _buildOngletMesTaches(tachesData),
                      1 => _buildOngletPresences(presencesData, pointageData),
                      2 => _buildOngletEvaluations(
                        evaluationsData,
                        feedbacksData,
                      ),
                      3 => _buildOngletJournal(journalData),
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

  // ==========================================
  // ONGLET 1 : MES TÂCHES (Image 1)
  // ==========================================
  Widget _buildOngletMesTaches(Map<String, dynamic> tachesData) {
    final items = _items(tachesData['items']);
    final itemsDateSelectionnee = items.where((tache) {
      final date = DateTime.tryParse(
        (tache['due_date'] ?? tache['date_echeance'])?.toString() ?? '',
      );
      return date != null &&
          date.year == _dateSelectionneeTaches.year &&
          date.month == _dateSelectionneeTaches.month &&
          date.day == _dateSelectionneeTaches.day;
    }).toList();
    final points = <int, Color>{};
    for (final tache in items) {
      final date = DateTime.tryParse(
        (tache['date_echeance'] ?? tache['due_date'])?.toString() ?? '',
      );
      if (date != null &&
          date.year == _dateSelectionneeTaches.year &&
          date.month == _dateSelectionneeTaches.month) {
        points[date.day] = const Color(0xFF1D61F2);
      }
    }
    final mois = _nomMois(_dateSelectionneeTaches.month);

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 28),
      children: [
        // Sélecteur de calendrier mois entier Janvier 2026
        CalendrierMoisEntier(
          dateSelectionnee: _dateSelectionneeTaches,
          pointsCouleursParDate: points,
          onDateSelectionnee: (date) {
            setState(() => _dateSelectionneeTaches = date);
          },
        ),

        const SizedBox(height: 22),

        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Échéances du ${_dateSelectionneeTaches.day} $mois',
              style: GoogleFonts.inter(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.white
                    : const Color(0xFF0F172A),
              ),
            ),
            GestureDetector(
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const MesTachesPage(),
                  ),
                );
              },
              child: Text(
                'Voir toutes',
                style: GoogleFonts.inter(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF1D61F2),
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 14),

        if (itemsDateSelectionnee.isNotEmpty)
          for (final t in itemsDateSelectionnee.take(4)) ...[
            CarteEcheanceTache(
              horaireTexte: _heureTache(t),
              sousHoraireTexte: '',
              tagLibelle:
                  (t['statut'] ?? t['status'])?.toString().replaceAll(
                    '_',
                    ' ',
                  ) ??
                  '',
              tagCouleurFond: const Color(0xFFE0F2FE),
              tagCouleurTexte: const Color(0xFF0284C7),
              titre: (t['titre'] ?? t['title'])?.toString() ?? '',
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => MesTachesPage(
                      assignmentUuid:
                          (t['assignment_uuid'] ??
                                  _map(t['assignment'])['uuid'])
                              ?.toString(),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 12),
          ]
        else if (ConfigurationApi.utiliserDonneesMockees &&
            tachesData.containsKey('__legacy_ui_preview')) ...[
          CarteEcheanceTache(
            horaireTexte: 'Toute la',
            sousHoraireTexte: 'journée',
            tagLibelle: 'EVALUATION',
            tagCouleurFond: const Color(0xFFE0F2FE),
            tagCouleurTexte: const Color(0xFF0284C7),
            titre: 'Remise du rapport de stage de mi-parcours',
            onTap: () {},
          ),
          const SizedBox(height: 12),
          CarteEcheanceTache(
            horaireTexte: '18:00',
            sousHoraireTexte: 'Échéance',
            tagLibelle: 'LOGBOOK',
            tagCouleurFond: const Color(0xFFF3E8FF),
            tagCouleurTexte: const Color(0xFF7E22CE),
            titre: 'Saisie du journal clinique quotidien',
            onTap: () => setState(() => _indexOnglet = 3),
          ),
        ] else ...[
          _etatVide(
            "Vous n'avez aucune tâche assignée.",
            icone: Iconsax.task_square,
          ),
        ],
      ],
    );
  }

  // ==========================================
  // ONGLET 2 : PRÉSENCES (Image 2)
  // ==========================================
  Widget _buildOngletPresences(
    Map<String, dynamic> presencesData,
    Map<String, dynamic> pointageData,
  ) {
    final items = _items(presencesData['items']);
    final punch = _map(pointageData['punch']).isNotEmpty
        ? _map(pointageData['punch'])
        : pointageData;
    final execution = _map(pointageData['execution']);
    final rotation = _map(punch['rotation']).isNotEmpty
        ? _map(punch['rotation'])
        : _map(execution['current_rotation']).isNotEmpty
        ? _map(execution['current_rotation'])
        : _map(pointageData['active_rotation']);
    final attendance = _map(punch['attendance']);

    if (items.isEmpty && rotation.isEmpty && attendance.isEmpty) {
      return _listeEtatVide(
        "Vous n'avez aucune présence ni rotation active.",
        icone: Iconsax.calendar_tick,
      );
    }

    final nomService =
        (rotation['unit_name'] ?? rotation['service_name'] ?? rotation['title'])
            ?.toString() ??
        '';
    final canPunch = punch['can_punch'] == true;
    final nextAction = punch['next_action']?.toString() ?? '';
    final actionSupportee = nextAction == 'ARRIVEE' || nextAction == 'DEPART';
    final estArrivee = nextAction == 'ARRIVEE';
    final lastPunchAt =
        (attendance['heure_depart'] ??
                attendance['departure_time'] ??
                attendance['heure_arrivee'] ??
                attendance['arrival_time'] ??
                pointageData['last_punch_at'])
            ?.toString() ??
        '';
    final statutPointage =
        (attendance['statut'] ?? attendance['status'])?.toString() ?? '';

    final stats = presencesData['stats'] is Map
        ? Map<String, dynamic>.from(presencesData['stats'] as Map)
        : null;
    final tauxBrut = stats?['attendance_rate'] ?? stats?['taux_presence'];
    final tauxGlobal = tauxBrut == null ? '0%' : '$tauxBrut%';
    final presents =
        stats?['present']?.toString() ?? stats?['presents']?.toString() ?? '0';
    final retards =
        stats?['late']?.toString() ?? stats?['retards']?.toString() ?? '0';
    final absences =
        stats?['absent']?.toString() ?? stats?['absences']?.toString() ?? '0';
    final gardes = stats?['guard']?.toString() ?? '0';

    final modeSombre = Theme.of(context).brightness == Brightness.dark;
    final fondCarte = modeSombre ? const Color(0xFF1E293B) : Colors.white;
    final bordureCouleur = modeSombre
        ? const Color(0xFF334155)
        : const Color(0xFFE2E8F0);
    final texteCouleur = modeSombre ? Colors.white : const Color(0xFF0F172A);

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 28),
      children: [
        // Carte Service Actuel
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: fondCarte,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: bordureCouleur),
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
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Service Actuel',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF94A3B8),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4.5,
                    ),
                    decoration: BoxDecoration(
                      color: modeSombre
                          ? const Color(0xFF14532D)
                          : const Color(0xFFDCFCE7),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      rotation['statut']?.toString() ?? '',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: modeSombre
                            ? const Color(0xFF4ADE80)
                            : const Color(0xFF16A34A),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                nomService,
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: texteCouleur,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        estArrivee ? 'Dernier pointage' : 'Arrivée enregistrée',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFF94A3B8),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        lastPunchAt,
                        style: GoogleFonts.inter(
                          fontSize: 16.5,
                          fontWeight: FontWeight.w800,
                          color: texteCouleur,
                        ),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'Statut',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFF94A3B8),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        statutPointage.replaceAll('_', ' '),
                        style: GoogleFonts.inter(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF16A34A),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: FilledButton.icon(
                  onPressed: (!canPunch || !actionSupportee || _pointageEnCours)
                      ? null
                      : () => _actionnerPointage(nextAction),
                  icon: _pointageEnCours
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : Icon(
                          estArrivee
                              ? Icons.login_rounded
                              : Icons.logout_rounded,
                          size: 18,
                        ),
                  label: Text(
                    estArrivee
                        ? 'Enregistrer mon arrivée'
                        : 'Enregistrer mon départ',
                    style: GoogleFonts.inter(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  style: FilledButton.styleFrom(
                    backgroundColor: estArrivee
                        ? const Color(0xFF16A34A)
                        : const Color(0xFFF97316),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 0,
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 22),

        // Titre Statistiques du mois
        Text(
          'Statistiques du mois (${_nomMois(DateTime.now().month)})',
          style: GoogleFonts.inter(
            fontSize: 17,
            fontWeight: FontWeight.w800,
            color: modeSombre ? Colors.white : const Color(0xFF0F172A),
          ),
        ),

        const SizedBox(height: 12),

        // Grille 2x2 des indicateurs de présence
        Row(
          children: [
            Expanded(
              child: _buildCarteStatistiquePresence(
                titre: 'Taux global',
                valeurWidget: Text(
                  tauxGlobal,
                  style: GoogleFonts.inter(
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    color: const Color(0xFF1D61F2),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildCarteStatistiquePresence(
                titre: 'Présent / Retard',
                valeurWidget: Row(
                  children: [
                    Text(
                      presents,
                      style: GoogleFonts.inter(
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                        color: const Color(0xFF16A34A),
                      ),
                    ),
                    Text(
                      ' / ',
                      style: GoogleFonts.inter(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF94A3B8),
                      ),
                    ),
                    Text(
                      retards,
                      style: GoogleFonts.inter(
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                        color: const Color(0xFFF97316),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 12),

        Row(
          children: [
            Expanded(
              child: _buildCarteStatistiquePresence(
                titre: 'Absences',
                valeurWidget: Text(
                  absences,
                  style: GoogleFonts.inter(
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    color: const Color(0xFFDC2626),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildCarteStatistiquePresence(
                titre: 'Gardes effectuées',
                valeurWidget: Text(
                  gardes,
                  style: GoogleFonts.inter(
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    color: const Color(0xFF7E22CE),
                  ),
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 24),

        // Bouton orange pleine largeur : Voir les details
        SizedBox(
          width: double.infinity,
          height: 48,
          child: FilledButton(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const CalendrierPresencePage(),
                ),
              );
            },
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFF97316),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              elevation: 0,
            ),
            child: Text(
              'Voir les details',
              style: GoogleFonts.inter(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCarteStatistiquePresence({
    required String titre,
    required Widget valeurWidget,
  }) {
    final modeSombre = Theme.of(context).brightness == Brightness.dark;
    final fondCarte = modeSombre ? const Color(0xFF1E293B) : Colors.white;
    final bordureCouleur = modeSombre
        ? const Color(0xFF334155)
        : const Color(0xFFE2E8F0);

    return Container(
      height: 94,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: fondCarte,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: bordureCouleur),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            titre,
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF94A3B8),
            ),
          ),
          const SizedBox(height: 4),
          valeurWidget,
        ],
      ),
    );
  }

  // ==========================================
  // ONGLET 3 : EVALUATIONS (Image 3)
  // ==========================================
  Widget _buildOngletEvaluations(
    Map<String, dynamic> evaluationsData,
    Map<String, dynamic> feedbacksData,
  ) {
    final modeSombre = Theme.of(context).brightness == Brightness.dark;
    final fondCarte = modeSombre ? const Color(0xFF1E293B) : Colors.white;
    final bordureCouleur = modeSombre
        ? const Color(0xFF334155)
        : const Color(0xFFE2E8F0);
    final texteCouleur = modeSombre ? Colors.white : const Color(0xFF0F172A);

    final items = _items(evaluationsData['items']);
    final feedbacks = _items(feedbacksData['items']);
    if (items.isEmpty && feedbacks.isEmpty) {
      return _listeEtatVide(
        "Vous n'avez aucune évaluation ou aucun feedback disponible.",
        icone: Iconsax.award,
      );
    }
    final stats = evaluationsData['stats'] is Map
        ? Map<String, dynamic>.from(evaluationsData['stats'] as Map)
        : null;
    final moyenneScore = stats?['average'];
    final moyenneNumerique = double.tryParse(moyenneScore?.toString() ?? '');
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 28),
      children: [
        // Carte Moyenne Générale
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: fondCarte,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: bordureCouleur),
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
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Moyenne Générale',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF94A3B8),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    moyenneScore == null ? '—' : '$moyenneScore / 20',
                    style: GoogleFonts.inter(
                      fontSize: 26,
                      fontWeight: FontWeight.w900,
                      color: const Color(0xFF1D61F2),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Évaluations validées',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: modeSombre
                          ? const Color(0xFF4ADE80)
                          : const Color(0xFF16A34A),
                    ),
                  ),
                ],
              ),
              // Badge Grade A
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: modeSombre
                      ? const Color(0xFF0C4A6E)
                      : const Color(0xFFE0F2FE),
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Text(
                  _gradeEvaluation(moyenneNumerique),
                  style: GoogleFonts.inter(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: modeSombre
                        ? const Color(0xFF38BDF8)
                        : const Color(0xFF0284C7),
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 22),

        if (feedbacks.isNotEmpty) ...[
          Text(
            'Retours des encadreurs (${feedbacks.length})',
            style: GoogleFonts.inter(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              color: texteCouleur,
            ),
          ),
          const SizedBox(height: 14),
          for (final feedback in feedbacks) ...[
            _buildCarteFeedback(feedback),
            const SizedBox(height: 14),
          ],
          const SizedBox(height: 8),
        ],

        // Section Fiches d'évaluations
        Text(
          'Fiches d\'évaluations (${items.length})',
          style: GoogleFonts.inter(
            fontSize: 17,
            fontWeight: FontWeight.w800,
            color: texteCouleur,
          ),
        ),

        const SizedBox(height: 12),

        // Filtres horizontaux par statut
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          child: Row(
            children: [
              _buildFiltreEvaluationChip('Tous'),
              const SizedBox(width: 8),
              _buildFiltreEvaluationChip('Validée'),
              const SizedBox(width: 8),
              _buildFiltreEvaluationChip('En attente'),
              const SizedBox(width: 8),
              _buildFiltreEvaluationChip('Rejetée'),
            ],
          ),
        ),

        const SizedBox(height: 14),

        Builder(
          builder: (context) {
            final fichesFiltrees = items
                .where(_evaluationCorrespondAuFiltre)
                .toList(growable: false);

            if (fichesFiltrees.isNotEmpty) {
              return Column(
                children: [
                  for (final ev in fichesFiltrees)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 14),
                      child: _buildCarteEvaluation(
                        tagLibelle: _formaterStatutCapitalize(
                          ev['status']?.toString().isNotEmpty == true
                              ? ev['status'].toString()
                              : (ev['type']?.toString() ?? ''),
                        ),
                        tagCouleurFond: const Color(0xFFE0F2FE),
                        tagCouleurTexte: const Color(0xFF0284C7),
                        note: ev['note'] == null ? '—' : '${ev['note']}/20',
                        titre: _titreEvaluation(ev),
                        evaluateur:
                            (ev['evaluator_name'] ?? ev['supervisor'])?.toString() ??
                            '',
                        appreciation:
                            (ev['appreciation'] ?? ev['comment'])?.toString() ?? '',
                        dateTexte:
                            (ev['finalized_at'] ?? ev['validated_at'])?.toString() ??
                            '',
                        donneesEvaluation: ev,
                      ),
                    ),
                ],
              );
            }

            if (items.isEmpty &&
                ConfigurationApi.utiliserDonneesMockees &&
                evaluationsData.containsKey('__legacy_ui_preview')) {
              return Column(
                children: [
                  _buildCarteEvaluation(
                    tagLibelle: 'Fin de rotation',
                    tagCouleurFond: const Color(0xFFE0F2FE),
                    tagCouleurTexte: const Color(0xFF0284C7),
                    note: '17.5 / 20',
                    titre: 'Stage Clinique - Urgences de Jour',
                    evaluateur: 'Dr. Marie Dupont',
                    appreciation:
                        '"Très bon sens clinique. Aptitude remarquable à gérer le stress en période de forte affluence..."',
                    dateTexte: '10 Janvier 2026',
                  ),
                  const SizedBox(height: 14),
                  _buildCarteEvaluation(
                    tagLibelle: 'Mi-parcours',
                    tagCouleurFond: const Color(0xFFF3E8FF),
                    tagCouleurTexte: const Color(0xFF7E22CE),
                    note: '16.0 / 20',
                    titre: 'Gestes Techniques & Sutures',
                    evaluateur: 'Dr. Jean-Pierre Mwamba',
                    appreciation:
                        '"Maîtrise les bases aseptiques. Rapidité d’exécution à perfectionner."',
                    dateTexte: '05 Janvier 2026',
                  ),
                ],
              );
            }

            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: _etatVide(
                'Aucune évaluation ne correspond à ce filtre.',
                icone: Iconsax.search_status,
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildCarteEvaluation({
    required String tagLibelle,
    required Color tagCouleurFond,
    required Color tagCouleurTexte,
    required String note,
    required String titre,
    required String evaluateur,
    required String appreciation,
    required String dateTexte,
    Map<String, dynamic>? donneesEvaluation,
  }) {
    final modeSombre = Theme.of(context).brightness == Brightness.dark;
    final fondCarte = modeSombre ? const Color(0xFF1E293B) : Colors.white;
    final bordureCouleur = modeSombre
        ? const Color(0xFF334155)
        : const Color(0xFFE2E8F0);
    final texteCouleur = modeSombre ? Colors.white : const Color(0xFF0F172A);
    final separateurCouleur = modeSombre
        ? const Color(0xFF334155)
        : const Color(0xFFF1F5F9);

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: fondCarte,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: bordureCouleur),
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
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Ligne Tag + Note
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                decoration: BoxDecoration(
                  color: tagCouleurFond,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  tagLibelle,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: tagCouleurTexte,
                  ),
                ),
              ),
              Text(
                note,
                style: GoogleFonts.inter(
                  fontSize: 15.5,
                  fontWeight: FontWeight.w800,
                  color: modeSombre
                      ? const Color(0xFF4ADE80)
                      : const Color(0xFF16A34A),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Titre
          Text(
            titre,
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: texteCouleur,
            ),
          ),

          const SizedBox(height: 6),

          // Évaluateur
          Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: 'Évaluateur :  ',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF94A3B8),
                  ),
                ),
                TextSpan(
                  text: evaluateur,
                  style: GoogleFonts.inter(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    color: texteCouleur,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 10),

          // Citation appréciation
          Text(
            appreciation,
            style: GoogleFonts.inter(
              fontSize: 12.5,
              fontWeight: FontWeight.w500,
              color: modeSombre
                  ? const Color(0xFFCBD5E1)
                  : const Color(0xFF64748B),
              fontStyle: FontStyle.italic,
              height: 1.35,
            ),
          ),

          const SizedBox(height: 12),
          Divider(height: 1, color: separateurCouleur),
          const SizedBox(height: 10),

          // Footer : Évalué le + Voir les détails
          Row(
            children: [
              Expanded(
                child: Text(
                  'Évalué le : $dateTexte',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF94A3B8),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => FicheEvaluationPage(
                        donneesEvaluation: donneesEvaluation,
                        scoreGlobal:
                            double.tryParse(note.split('/').first.trim()) ?? 0,
                        nomEvaluateur: evaluateur,
                        initialesEvaluateur: evaluateur
                            .split(' ')
                            .where((e) => e.isNotEmpty && !e.startsWith('Dr.'))
                            .map((e) => e[0])
                            .take(2)
                            .join(),
                      ),
                    ),
                  );
                },
                child: Text(
                  'Voir les détails',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF1D61F2),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCarteFeedback(Map<String, dynamic> feedback) {
    final modeSombre = Theme.of(context).brightness == Brightness.dark;
    final fondCarte = modeSombre ? const Color(0xFF1E293B) : Colors.white;
    final bordureCouleur = modeSombre
        ? const Color(0xFF334155)
        : const Color(0xFFE2E8F0);
    final texteCouleur = modeSombre ? Colors.white : const Color(0xFF0F172A);
    final type = feedback['type']?.toString().toUpperCase() ?? '';
    final couleurs = _couleursFeedback(type);
    final lu = feedback['seen'] == true;
    final actionLecture = _map(_map(feedback['actions'])['read']);
    final peutMarquerLu = actionLecture['allowed'] == true;
    final uuid = feedback['uuid']?.toString() ?? '';
    final lectureEnCours = _feedbacksLectureEnCours.contains(uuid);
    final auteur = feedback['author_name']?.toString() ?? '';

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: fondCarte,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: bordureCouleur),
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
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                decoration: BoxDecoration(
                  color: couleurs.$1,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  _formaterStatutCapitalize(type),
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: couleurs.$2,
                  ),
                ),
              ),
              Text(
                lu ? 'Lu' : 'Nouveau',
                style: GoogleFonts.inter(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w800,
                  color: lu ? const Color(0xFF94A3B8) : const Color(0xFF1D61F2),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            feedback['title']?.toString() ?? '',
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: texteCouleur,
            ),
          ),
          if (auteur.isNotEmpty) ...[
            const SizedBox(height: 5),
            Text(
              'Encadreur : $auteur',
              style: GoogleFonts.inter(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF94A3B8),
              ),
            ),
          ],
          const SizedBox(height: 10),
          Text(
            feedback['comment']?.toString() ?? '',
            style: GoogleFonts.inter(
              fontSize: 12.5,
              fontWeight: FontWeight.w500,
              color: modeSombre
                  ? const Color(0xFFCBD5E1)
                  : const Color(0xFF64748B),
              height: 1.35,
            ),
          ),
          const SizedBox(height: 12),
          Divider(
            height: 1,
            color: modeSombre
                ? const Color(0xFF334155)
                : const Color(0xFFF1F5F9),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: Text(
                  feedback['published_at']?.toString() ??
                      feedback['date']?.toString() ??
                      '',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF94A3B8),
                  ),
                ),
              ),
              if (peutMarquerLu && uuid.isNotEmpty)
                GestureDetector(
                  onTap: lectureEnCours ? null : () => _marquerFeedbackLu(uuid),
                  child: Text(
                    lectureEnCours ? 'Enregistrement...' : 'Marquer comme lu',
                    style: GoogleFonts.inter(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF1D61F2),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  (Color, Color) _couleursFeedback(String type) => switch (type) {
    'ENCOURAGEMENT' => (const Color(0xFFDCFCE7), const Color(0xFF16A34A)),
    'A_AMELIORER' => (const Color(0xFFFFF7ED), const Color(0xFFEA580C)),
    'AVERTISSEMENT' => (const Color(0xFFFEE2E2), const Color(0xFFDC2626)),
    _ => (const Color(0xFFE0F2FE), const Color(0xFF0284C7)),
  };

  // ==========================================
  // ONGLET 4 : JOURNAL (Image 4)
  // ==========================================
  Widget _buildOngletJournal(Map<String, dynamic> journalData) {
    final items = _items(journalData['items']);
    if (items.isEmpty) {
      return _listeEtatVide(
        "Vous n'avez aucun journal enregistré.",
        icone: Iconsax.book,
      );
    }
    final stats = _map(journalData['stats']);
    final total = _entier(stats['total']);
    final termines =
        _entier(stats['submitted']) +
        _entier(stats['validated']) +
        _entier(stats['rejected']);
    final progression = total > 0 ? termines / total : 0.0;
    final journauxFiltres = items.where(_journalCorrespondAuFiltre).toList();

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 28),
      children: [
        // Carte bleue vive : Progression du jour
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: const Color(0xFF1D61F2),
            borderRadius: BorderRadius.circular(20),
            boxShadow: const [
              BoxShadow(
                color: Color(0x1A1D61F2),
                blurRadius: 14,
                offset: Offset(0, 4),
              ),
            ],
          ),
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Progression du jour',
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    '${(progression * 100).round()}% effectué',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: progression,
                  minHeight: 7,
                  backgroundColor: const Color(0x33FFFFFF),
                  valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                '$termines sur $total journaux traités',
                style: GoogleFonts.inter(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w500,
                  color: Colors.white.withValues(alpha: 0.85),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // Filtres défilables horizontalement + Lien vers Mes journaux
        Row(
          children: [
            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                child: Row(
                  children: [
                    _buildFiltreJournalChip('Aujourd\'hui'),
                    const SizedBox(width: 8),
                    _buildFiltreJournalChip('À venir'),
                    const SizedBox(width: 8),
                    _buildFiltreJournalChip('Terminées'),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 6),
            IconButton(
              tooltip: 'Historique des journaux',
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const MesJournauxPage(),
                  ),
                );
              },
              icon: const Icon(
                Icons.list_alt_rounded,
                color: Color(0xFF1D61F2),
                size: 22,
              ),
            ),
          ],
        ),

        const SizedBox(height: 16),

        if (journauxFiltres.isEmpty)
          _etatVide(
            'Aucun journal ne correspond à ce filtre.',
            icone: Iconsax.search_status,
          ),

        for (final journal in journauxFiltres) ...[
          _buildCarteActiviteJournal(
            tagPriorite: _categorieJournal(journal),
            tagPrioriteBg: const Color(0xFFF3E8FF),
            tagPrioriteTexte: const Color(0xFF7E22CE),
            statutLibelle:
                journal['status']?.toString().replaceAll('_', ' ') ?? '',
            statutBg: const Color(0xFFE0F2FE),
            statutTexte: const Color(0xFF0284C7),
            titre:
                (journal['learning'] ?? journal['summary'])?.toString() ?? '',
            description: journal['summary']?.toString() ?? '',
            echeanceTexte: journal['date']?.toString() ?? '',
            actionTexte: journal['editable'] == true ? 'Corriger' : 'Ouvrir',
            actionCouleur: const Color(0xFF1D61F2),
            donneesJournal: journal,
          ),
          const SizedBox(height: 14),
        ],

        if (ConfigurationApi.utiliserDonneesMockees &&
            journalData.containsKey('__legacy_ui_preview')) ...[
          // Carte 1 : HAUTE PRIORITÉ - En cours
          _buildCarteActiviteJournal(
            tagPriorite: 'HAUTE PRIORITÉ',
            tagPrioriteBg: const Color(0xFFFFF7ED),
            tagPrioriteTexte: const Color(0xFFEA580C),
            statutLibelle: 'En cours',
            statutBg: const Color(0xFFE0F2FE),
            statutTexte: const Color(0xFF0284C7),
            titre: 'Rapport d\'admission - Traumatisme thoracique',
            description: 'Patient transféré suite à un accident de la route...',
            echeanceTexte: 'Échéance : Aujourd\'hui, 14:00',
            actionTexte: 'Ouvrir',
            actionCouleur: const Color(0xFF1D61F2),
          ),

          const SizedBox(height: 14),

          // Carte 2 : PROCÉDURE - À corriger
          _buildCarteActiviteJournal(
            tagPriorite: 'PROCÉDURE',
            tagPrioriteBg: const Color(0xFFF3E8FF),
            tagPrioriteTexte: const Color(0xFF7E22CE),
            statutLibelle: 'À corriger',
            statutBg: const Color(0xFFFEF3C7),
            statutTexte: const Color(0xFFD97706),
            titre: 'Suture et parage de plaie complexe',
            description:
                'Suture effectuée sous la supervision du Dr. Marie Dupo...',
            echeanceTexte: 'Échéance : Aujourd\'hui, 18:00',
            actionTexte: 'Corriger',
            actionCouleur: const Color(0xFF1D61F2),
          ),
        ],
      ],
    );
  }

  Widget _buildFiltreJournalChip(String titre) {
    final modeSombre = Theme.of(context).brightness == Brightness.dark;
    final actif = _filtreJournal == titre;
    final fondInactif = modeSombre ? const Color(0xFF1E293B) : Colors.white;
    final bordureInactif = modeSombre
        ? const Color(0xFF334155)
        : const Color(0xFFE2E8F0);
    final texteInactif = modeSombre
        ? const Color(0xFF94A3B8)
        : const Color(0xFF64748B);

    return GestureDetector(
      onTap: () => setState(() => _filtreJournal = titre),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8.5),
        decoration: BoxDecoration(
          color: actif ? const Color(0xFF1D61F2) : fondInactif,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: actif ? const Color(0xFF1D61F2) : bordureInactif,
          ),
        ),
        child: Text(
          titre,
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: actif ? FontWeight.w700 : FontWeight.w500,
            color: actif ? Colors.white : texteInactif,
          ),
        ),
      ),
    );
  }

  String _nomMois(int mois) => const [
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
  ][mois - 1];

  String _heureTache(Map<String, dynamic> tache) {
    final valeur = tache['date_echeance'] ?? tache['due_date'];
    final date = DateTime.tryParse(valeur?.toString() ?? '');
    if (date == null) return '';
    return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  bool _journalCorrespondAuFiltre(Map<String, dynamic> journal) {
    final date = DateTime.tryParse(journal['date']?.toString() ?? '');
    final maintenant = DateTime.now();
    final aujourdHui = DateTime(
      maintenant.year,
      maintenant.month,
      maintenant.day,
    );
    final jour = date == null
        ? null
        : DateTime(date.year, date.month, date.day);
    if (_filtreJournal.startsWith('Aujourd')) return jour == aujourdHui;
    if (_filtreJournal == 'À venir') {
      return jour != null && jour.isAfter(aujourdHui);
    }
    final statut = journal['status']?.toString().toUpperCase() ?? '';
    return const {
      'SOUMIS',
      'SOUMISE',
      'VALIDE',
      'VALIDEE',
      'REJETE',
      'REJETEE',
    }.contains(statut);
  }

  String _categorieJournal(Map<String, dynamic> journal) {
    final activites = _items(journal['activities']);
    return activites.isEmpty
        ? 'JOURNAL'
        : activites.first['category']?.toString() ?? 'JOURNAL';
  }

  String _gradeEvaluation(double? moyenne) {
    if (moyenne == null) return '—';
    if (moyenne >= 16) return 'A';
    if (moyenne >= 14) return 'B';
    if (moyenne >= 12) return 'C';
    if (moyenne >= 10) return 'D';
    return 'E';
  }

  String _titreEvaluation(Map<String, dynamic> evaluation) {
    final unit = _map(evaluation['unit']);
    final campaign = _map(evaluation['campaign']);
    return unit['name']?.toString() ??
        campaign['title']?.toString() ??
        campaign['name']?.toString() ??
        evaluation['campaign_title']?.toString() ??
        '';
  }

  String _formaterStatutCapitalize(String brut) {
    final texte = brut.trim().replaceAll('_', ' ');
    if (texte.isEmpty) return '';
    return texte
        .split(' ')
        .where((mot) => mot.isNotEmpty)
        .map((mot) {
          final premier = mot.substring(0, 1).toUpperCase();
          final reste = mot.length > 1 ? mot.substring(1).toLowerCase() : '';
          return '$premier$reste';
        })
        .join(' ');
  }

  bool _evaluationCorrespondAuFiltre(Map<String, dynamic> evaluation) {
    if (_filtreEvaluation == 'Tous') return true;
    final statut = (evaluation['status'] ?? '').toString().toUpperCase().trim();
    return switch (_filtreEvaluation) {
      'Validée' || 'Validées' =>
        statut == 'VALIDEE' || statut == 'VALIDE' || statut == 'FINALISEE' || statut == 'FINALISE',
      'En attente' =>
        statut == 'EN_ATTENTE' || statut == 'PENDING' || statut == 'SOUMISE' || statut == 'SOUMIS',
      'Rejetée' || 'Rejetées' =>
        statut == 'REJETEE' || statut == 'REJETE',
      _ => statut == _filtreEvaluation.toUpperCase(),
    };
  }

  Widget _buildFiltreEvaluationChip(String titre) {
    final modeSombre = Theme.of(context).brightness == Brightness.dark;
    final actif = _filtreEvaluation == titre;
    final fondInactif = modeSombre ? const Color(0xFF1E293B) : Colors.white;
    final bordureInactif = modeSombre
        ? const Color(0xFF334155)
        : const Color(0xFFE2E8F0);
    final texteInactif = modeSombre
        ? const Color(0xFF94A3B8)
        : const Color(0xFF64748B);

    return GestureDetector(
      onTap: () => setState(() => _filtreEvaluation = titre),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8.5),
        decoration: BoxDecoration(
          color: actif ? const Color(0xFF1D61F2) : fondInactif,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: actif ? const Color(0xFF1D61F2) : bordureInactif,
          ),
        ),
        child: Text(
          titre,
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: actif ? FontWeight.w700 : FontWeight.w500,
            color: actif ? Colors.white : texteInactif,
          ),
        ),
      ),
    );
  }

  Widget _etatVide(String message, {IconData icone = Iconsax.document}) {
    final modeSombre = Theme.of(context).brightness == Brightness.dark;
    final couleurIcone = modeSombre
        ? const Color(0xFF38BDF8)
        : const Color(0xFF1D61F2);
    final couleurFondIcone = modeSombre
        ? const Color(0x2238BDF8)
        : const Color(0x141D61F2);
    final couleurTexte = modeSombre
        ? const Color(0xFF94A3B8)
        : const Color(0xFF64748B);

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: couleurFondIcone,
                shape: BoxShape.circle,
              ),
              child: Icon(icone, size: 34, color: couleurIcone),
            ),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 14.5,
                fontWeight: FontWeight.w600,
                color: couleurTexte,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _listeEtatVide(String message, {IconData icone = Iconsax.document}) =>
      LayoutBuilder(
        builder: (context, constraints) => SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Center(child: _etatVide(message, icone: icone)),
          ),
        ),
      );

  Widget _buildCarteActiviteJournal({
    required String tagPriorite,
    required Color tagPrioriteBg,
    required Color tagPrioriteTexte,
    required String statutLibelle,
    required Color statutBg,
    required Color statutTexte,
    required String titre,
    required String description,
    required String echeanceTexte,
    required String actionTexte,
    required Color actionCouleur,
    Map<String, dynamic>? donneesJournal,
  }) {
    final modeSombre = Theme.of(context).brightness == Brightness.dark;
    final fondCarte = modeSombre ? const Color(0xFF1E293B) : Colors.white;
    final bordureCouleur = modeSombre
        ? const Color(0xFF334155)
        : const Color(0xFFE2E8F0);
    final texteCouleur = modeSombre ? Colors.white : const Color(0xFF0F172A);
    final descriptionCouleur = modeSombre
        ? const Color(0xFF94A3B8)
        : const Color(0xFF64748B);
    final separateurCouleur = modeSombre
        ? const Color(0xFF334155)
        : const Color(0xFFF1F5F9);

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: fondCarte,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: bordureCouleur),
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
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Ligne Badge Priorité + Badge Statut
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                decoration: BoxDecoration(
                  color: tagPrioriteBg,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  tagPriorite,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: tagPrioriteTexte,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                decoration: BoxDecoration(
                  color: statutBg,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  statutLibelle,
                  style: GoogleFonts.inter(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    color: statutTexte,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Titre
          Text(
            titre,
            style: GoogleFonts.inter(
              fontSize: 15.5,
              fontWeight: FontWeight.w800,
              color: texteCouleur,
            ),
          ),

          const SizedBox(height: 4),

          // Description
          Text(
            description,
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: descriptionCouleur,
            ),
          ),

          const SizedBox(height: 12),
          Divider(height: 1, color: separateurCouleur),
          const SizedBox(height: 10),

          // Footer : Échéance + Action
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                echeanceTexte,
                style: GoogleFonts.inter(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFF94A3B8),
                ),
              ),
              GestureDetector(
                onTap: () {
                  if (actionTexte == 'Ouvrir') {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) =>
                            DetailJournalPage(donneesJournal: donneesJournal),
                      ),
                    );
                  } else {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => SaisirJournalPage(
                          donneesJournal: donneesJournal,
                          assignmentUuid: _map(
                            donneesJournal?['assignment'],
                          )['uuid']?.toString(),
                          logbookUuid: donneesJournal?['uuid']?.toString(),
                        ),
                      ),
                    );
                  }
                },
                child: Text(
                  actionTexte,
                  style: GoogleFonts.inter(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    color: actionCouleur,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

String _dateApi(DateTime date) =>
    '${date.year.toString().padLeft(4, '0')}-'
    '${date.month.toString().padLeft(2, '0')}-'
    '${date.day.toString().padLeft(2, '0')}';

List<Map<String, dynamic>> _items(Object? valeur) => valeur is List
    ? valeur
          .whereType<Map>()
          .map((item) => Map<String, dynamic>.from(item))
          .toList()
    : <Map<String, dynamic>>[];

Map<String, dynamic> _map(Object? valeur) =>
    valeur is Map ? Map<String, dynamic>.from(valeur) : <String, dynamic>{};

int _entier(Object? valeur) => valeur is num
    ? valeur.toInt()
    : int.tryParse(valeur?.toString() ?? '') ?? 0;
