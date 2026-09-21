import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/network/client_api_http.dart';
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
  DateTime _dateSelectionneeTaches = DateTime(2026, 1, 15);

  // État onglet Journal
  String _filtreJournal = 'Aujourd\'hui (5)';

  // État pointage de présence
  bool _arriveeEnregistree = true;
  String _heureArrivee = '07:54 AM';

  late Future<List<Map<String, dynamic>>> _chargement;

  @override
  void initState() {
    super.initState();
    _chargement = _charger();
  }

  @override
  void dispose() {
    _rechercheController.dispose();
    super.dispose();
  }

  Future<List<Map<String, dynamic>>> _charger() => Future.wait([
        _source.journal(),
        _source.presences(),
        _source.evaluations(),
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
      appBar: EnTeteJournal(
        nombreTachesAujourdhui: 5,
        onOuvrirChat: () => Navigator.of(context, rootNavigator: true).push(
          MaterialPageRoute<void>(builder: (_) => const MessageriePage()),
        ),
        onOuvrirNotifications: () => Navigator.of(context, rootNavigator: true).push(
          MaterialPageRoute<void>(builder: (_) => const NotificationsPage()),
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
                  return RefreshIndicator(
                    color: const Color(0xFF1D61F2),
                    onRefresh: _actualiser,
                    child: switch (_indexOnglet) {
                      0 => _buildOngletMesTaches(),
                      1 => _buildOngletPresences(),
                      2 => _buildOngletEvaluations(),
                      3 => _buildOngletJournal(),
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
  Widget _buildOngletMesTaches() {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 28),
      children: [
        // Sélecteur de calendrier mois entier Janvier 2026
        CalendrierMoisEntier(
          dateSelectionnee: _dateSelectionneeTaches,
          pointsCouleursParDate: const {
            14: Color(0xFFF97316), // point orange sous le 14
            15: Color(0xFF1D61F2),
            18: Color(0xFF16A34A),
          },
          onDateSelectionnee: (date) {
            setState(() => _dateSelectionneeTaches = date);
          },
        ),

        const SizedBox(height: 22),

        // Titre Échéances du 15 Janvier + Lien vers Mes tâches
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Échéances du ${_dateSelectionneeTaches.day} Janvier',
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

        // Liste des cartes d'échéances
        CarteEcheanceTache(
          horaireTexte: 'Toute la',
          sousHoraireTexte: 'journée',
          tagLibelle: 'EVALUATION',
          tagCouleurFond: const Color(0xFFE0F2FE),
          tagCouleurTexte: const Color(0xFF0284C7),
          titre: 'Remise du rapport de stage de mi-...',
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
          onTap: () {
            setState(() => _indexOnglet = 3);
          },
        ),
        const SizedBox(height: 12),
        CarteEcheanceTache(
          horaireTexte: '10:00',
          sousHoraireTexte: '12:30',
          tagLibelle: 'CHIRURGIE',
          tagCouleurFond: const Color(0xFFDCFCE7),
          tagCouleurTexte: const Color(0xFF16A34A),
          titre: 'Aide opératoire en cure de hernie',
          onTap: () {},
        ),
      ],
    );
  }

  // ==========================================
  // ONGLET 2 : PRÉSENCES (Image 2)
  // ==========================================
  Widget _buildOngletPresences() {
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
              // Ligne Service + Badge Garde active
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
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4.5),
                    decoration: BoxDecoration(
                      color: const Color(0xFFDCFCE7),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'Garde active',
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

              // Titre du service
              Text(
                'Urgences Générales (HKG)',
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF0F172A),
                ),
              ),

              const SizedBox(height: 16),

              // Ligne Arrivée enregistrée + Statut À l'heure
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Arrivée enregistrée',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFF94A3B8),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _heureArrivee,
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
                        'À l\'heure',
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

              // Bouton orange Enregistrer mon départ / Arrivée
              SizedBox(
                width: double.infinity,
                height: 48,
                child: FilledButton.icon(
                  onPressed: () {
                    setState(() {
                      _arriveeEnregistree = !_arriveeEnregistree;
                      if (_arriveeEnregistree) {
                        _heureArrivee = '07:54 AM';
                      }
                    });
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          _arriveeEnregistree
                              ? 'Arrivée validée à 07:54 AM'
                              : 'Départ enregistré avec succès !',
                        ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.logout_rounded, size: 18),
                  label: Text(
                    _arriveeEnregistree ? 'Enregistrer mon départ' : 'Enregistrer mon arrivée',
                    style: GoogleFonts.inter(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFFF97316),
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
          'Statistiques du mois (Janvier)',
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
                  '96%',
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
                      '12',
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
                      '1',
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
                  '0',
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
                  '4',
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
  Widget _buildOngletEvaluations() {
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
                    '16.8 / 20',
                    style: GoogleFonts.inter(
                      fontSize: 26,
                      fontWeight: FontWeight.w900,
                      color: const Color(0xFF1D61F2),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Excellent travail d\'équipe',
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
                  'A',
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

        // Titre Fiches d'évaluations (3)
        Text(
          'Fiches d\'évaluations (3)',
          style: GoogleFonts.inter(
            fontSize: 17,
            fontWeight: FontWeight.w800,
            color: const Color(0xFF0F172A),
          ),
        ),

        const SizedBox(height: 14),

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
                        scoreGlobal: double.tryParse(note.split('/').first.trim()) ?? 17.5,
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
  Widget _buildOngletJournal() {
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
                    '60% effectué',
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
                child: const LinearProgressIndicator(
                  value: 0.6,
                  minHeight: 7,
                  backgroundColor: Color(0x33FFFFFF),
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                '3 sur 5 tâches cliniques obligatoires validées',
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

        // Filtres (Aujourd'hui (5), À venir, Terminées) + Lien vers Mes journaux
        Row(
          children: [
            _buildFiltreJournalChip('Aujourd\'hui (5)'),
            const SizedBox(width: 8),
            _buildFiltreJournalChip('À venir'),
            const SizedBox(width: 8),
            _buildFiltreJournalChip('Terminées'),
            const Spacer(),
            IconButton(
              tooltip: 'Historique des journaux',
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const MesJournauxPage(),
                  ),
                );
              },
              icon: const Icon(Icons.list_alt_rounded, color: Color(0xFF1D61F2), size: 22),
            ),
          ],
        ),

        const SizedBox(height: 16),

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
          description: 'Suture effectuée sous la supervision du Dr. Marie Dupo...',
          echeanceTexte: 'Échéance : Aujourd\'hui, 18:00',
          actionTexte: 'Corriger',
          actionCouleur: const Color(0xFF1D61F2),
        ),
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
                        builder: (_) => const DetailJournalPage(),
                      ),
                    );
                  } else {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => const SaisirJournalPage(),
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
