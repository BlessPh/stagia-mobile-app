import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/network/client_api_http.dart';
import '../../../../core/network/configuration_api.dart';
import '../../../../core/network/source_etudiant_distante.dart';
import '../../../messagerie/presentation/pages/messagerie_page.dart';
import '../../../notifications/presentation/pages/notifications_page.dart';
import 'calendrier_presence_page.dart';
import 'detail_journal_page.dart';
import 'fiche_evaluation_page.dart';
import 'mes_journaux_page.dart';
import 'mes_taches_page.dart';
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

  int _nombreTachesAujourdhui = 0;

  // État pointage de présence
  bool _pointageEnCours = false;

  late Future<List<Map<String, dynamic>>> _chargement;

  @override
  void initState() {
    super.initState();
    _dateSelectionneeTaches = ConfigurationApi.utiliserDonneesMockees
        ? DateTime(2026, 1, 15)
        : DateTime.now();
    if (ConfigurationApi.utiliserDonneesMockees) {
      _filtreJournal = 'Aujourd\'hui (5)';
      _nombreTachesAujourdhui = 5;
    }
    _chargement = _charger();
  }

  @override
  void dispose() {
    _rechercheController.dispose();
    super.dispose();
  }

  Future<List<Map<String, dynamic>>> _charger() async {
    final reponses = await Future.wait([
      _source.journal(),
      _source.presences(),
      _source.evaluations(),
      _source.contextePointage(),
      _source.taches(),
    ]);
    final taches = _items(reponses[4]['items']);
    final aujourdHui = DateTime.now();
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
    setState(() => _pointageEnCours = true);
    try {
      if (action == 'ARRIVEE') {
        await _source.pointerArrivee();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Arrivée enregistrée avec succès !'),
              backgroundColor: Color(0xFF16A34A),
            ),
          );
        }
      } else {
        await _source.pointerDepart();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Départ enregistré avec succès !'),
              backgroundColor: Color(0xFFF97316),
            ),
          );
        }
      }
      await _actualiser();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: const Color(0xFFDC2626),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _pointageEnCours = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
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
            const Divider(height: 1, color: Color(0xFFE2E8F0)),

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
                  final reponses = snapshot.data ?? [{}, {}, {}, {}, {}];
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

                  return RefreshIndicator(
                    color: const Color(0xFF1D61F2),
                    onRefresh: _actualiser,
                    child: switch (_indexOnglet) {
                      0 => _buildOngletMesTaches(tachesData),
                      1 => _buildOngletPresences(presencesData, pointageData),
                      2 => _buildOngletEvaluations(evaluationsData),
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
          pointsCouleursParDate: ConfigurationApi.utiliserDonneesMockees
              ? const {
                  14: Color(0xFFF97316),
                  15: Color(0xFF1D61F2),
                  18: Color(0xFF16A34A),
                }
              : points,
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
                color: const Color(0xFF0F172A),
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

        if (items.isNotEmpty)
          for (final t in items.take(4)) ...[
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
              onTap: () {},
            ),
            const SizedBox(height: 12),
          ]
        else if (ConfigurationApi.utiliserDonneesMockees) ...[
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
        ] else ...[_etatVide("Vous n'avez aucune tâche assignée.")],
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
      return _listeEtatVide("Vous n'avez aucune présence ni rotation active.");
    }

    final nomService =
        (rotation['unit_name'] ?? rotation['title'])?.toString() ?? '';
    final canPunch = punch['can_punch'] == true;
    final nextAction = punch['next_action']?.toString() ?? '';
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

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 28),
      children: [
        // Carte Service Actuel
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFE2E8F0)),
            boxShadow: const [
              BoxShadow(
                color: Color(0x05000000),
                blurRadius: 10,
                offset: Offset(0, 2),
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
                      color: const Color(0xFFDCFCE7),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      rotation['statut']?.toString() ?? '',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF16A34A),
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
                  color: const Color(0xFF0F172A),
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
                          color: const Color(0xFF0F172A),
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
                  onPressed: (!canPunch || _pointageEnCours)
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
            color: const Color(0xFF0F172A),
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
    return Container(
      height: 94,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x05000000),
            blurRadius: 10,
            offset: Offset(0, 2),
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
  Widget _buildOngletEvaluations(Map<String, dynamic> evaluationsData) {
    final items = _items(evaluationsData['items']);
    if (items.isEmpty && !ConfigurationApi.utiliserDonneesMockees) {
      return _listeEtatVide("Vous n'avez aucune évaluation disponible.");
    }
    final stats = evaluationsData['stats'] is Map
        ? Map<String, dynamic>.from(evaluationsData['stats'] as Map)
        : null;
    final moyenneScore =
        stats?['average'] ??
        (ConfigurationApi.utiliserDonneesMockees ? '16.8' : null);
    final moyenneNumerique = double.tryParse(moyenneScore?.toString() ?? '');
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 28),
      children: [
        // Carte Moyenne Générale
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFE2E8F0)),
            boxShadow: const [
              BoxShadow(
                color: Color(0x05000000),
                blurRadius: 10,
                offset: Offset(0, 2),
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
                      color: const Color(0xFF16A34A),
                    ),
                  ),
                ],
              ),
              // Badge Grade A
              Container(
                width: 60,
                height: 60,
                decoration: const BoxDecoration(
                  color: Color(0xFFE0F2FE),
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Text(
                  _gradeEvaluation(moyenneNumerique),
                  style: GoogleFonts.inter(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: const Color(0xFF0284C7),
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 22),

        // Titre Fiches d'évaluations
        Text(
          'Fiches d\'évaluations (${items.isNotEmpty ? items.length : 2})',
          style: GoogleFonts.inter(
            fontSize: 17,
            fontWeight: FontWeight.w800,
            color: const Color(0xFF0F172A),
          ),
        ),

        const SizedBox(height: 14),

        if (items.isNotEmpty)
          for (final ev in items)
            Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: _buildCarteEvaluation(
                tagLibelle: ev['type']?.toString().replaceAll('_', ' ') ?? '',
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
                    (ev['validated_at'] ?? ev['finalized_at'])?.toString() ??
                    '',
                donneesEvaluation: ev,
              ),
            )
        else ...[
          // Carte 1 : FIN DE ROTATION
          _buildCarteEvaluation(
            tagLibelle: 'FIN DE ROTATION',
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

          // Carte 2 : MI-PARCOURS
          _buildCarteEvaluation(
            tagLibelle: 'MI-PARCOURS',
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
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x05000000),
            blurRadius: 10,
            offset: Offset(0, 2),
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
                  color: const Color(0xFF16A34A),
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
              color: const Color(0xFF0F172A),
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
                    color: const Color(0xFF0F172A),
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
              color: const Color(0xFF64748B),
              fontStyle: FontStyle.italic,
              height: 1.35,
            ),
          ),

          const SizedBox(height: 12),
          const Divider(height: 1, color: Color(0xFFF1F5F9)),
          const SizedBox(height: 10),

          // Footer : Évalué le + Voir les détails
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Évalué le : $dateTexte',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFF94A3B8),
                ),
              ),
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

  // ==========================================
  // ONGLET 4 : JOURNAL (Image 4)
  // ==========================================
  Widget _buildOngletJournal(Map<String, dynamic> journalData) {
    final items = _items(journalData['items']);
    if (items.isEmpty && !ConfigurationApi.utiliserDonneesMockees) {
      return _listeEtatVide("Vous n'avez aucun journal enregistré.");
    }
    final stats = _map(journalData['stats']);
    final total = _entier(stats['total']);
    final termines =
        _entier(stats['submitted']) +
        _entier(stats['validated']) +
        _entier(stats['rejected']);
    final progression = total > 0 ? termines / total : 0.0;
    final journauxFiltres = ConfigurationApi.utiliserDonneesMockees
        ? const <Map<String, dynamic>>[]
        : items.where(_journalCorrespondAuFiltre).toList();

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
                    _buildFiltreJournalChip(
                      ConfigurationApi.utiliserDonneesMockees
                          ? 'Aujourd\'hui (5)'
                          : 'Aujourd\'hui',
                    ),
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

        if (!ConfigurationApi.utiliserDonneesMockees && journauxFiltres.isEmpty)
          _etatVide('Aucun journal ne correspond à ce filtre.'),

        if (!ConfigurationApi.utiliserDonneesMockees)
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

        if (ConfigurationApi.utiliserDonneesMockees) ...[
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
    final actif = _filtreJournal == titre;
    return GestureDetector(
      onTap: () => setState(() => _filtreJournal = titre),
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
    return unit['name']?.toString() ?? campaign['title']?.toString() ?? '';
  }

  Widget _etatVide(String message) => Center(
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 32),
      child: Text(
        message,
        textAlign: TextAlign.center,
        style: GoogleFonts.inter(color: const Color(0xFF64748B)),
      ),
    ),
  );

  Widget _listeEtatVide(String message) => ListView(
    physics: const AlwaysScrollableScrollPhysics(),
    padding: const EdgeInsets.all(32),
    children: [_etatVide(message)],
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
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x05000000),
            blurRadius: 10,
            offset: Offset(0, 2),
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
              color: const Color(0xFF0F172A),
            ),
          ),

          const SizedBox(height: 4),

          // Description
          Text(
            description,
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF64748B),
            ),
          ),

          const SizedBox(height: 12),
          const Divider(height: 1, color: Color(0xFFF1F5F9)),
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
