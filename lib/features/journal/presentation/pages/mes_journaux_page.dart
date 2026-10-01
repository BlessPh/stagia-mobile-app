import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/network/client_api_http.dart';
import '../../../../core/network/source_etudiant_distante.dart';
import '../../../messagerie/presentation/pages/messagerie_page.dart';
import '../../../notifications/presentation/pages/notifications_page.dart';
import 'detail_journal_page.dart';
import 'saisir_journal_page.dart';

class MesJournauxPage extends StatefulWidget {
  const MesJournauxPage({super.key});

  @override
  State<MesJournauxPage> createState() => _MesJournauxPageState();
}

class _MesJournauxPageState extends State<MesJournauxPage> {
  final _source = SourceEtudiantDistante(ClientApiHttp());
  String _filtreActif = 'Tous';
  final TextEditingController _rechercheController = TextEditingController();

  bool _chargement = true;
  List<Map<String, dynamic>> _journaux = [];
  Map<String, dynamic> _stats = {};

  @override
  void initState() {
    super.initState();
    _chargerJournaux();
  }

  @override
  void dispose() {
    _rechercheController.dispose();
    super.dispose();
  }

  Future<void> _chargerJournaux() async {
    try {
      final res = await _source.journal();
      final items = (res['items'] as List? ?? [])
          .whereType<Map>()
          .map(Map<String, dynamic>.from)
          .toList();

      final stats = res['stats'] is Map
          ? Map<String, dynamic>.from(res['stats'] as Map)
          : <String, dynamic>{};

      if (mounted) {
        setState(() {
          _journaux = items;
          _stats = stats;
          _chargement = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _chargement = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final query = _rechercheController.text.trim().toLowerCase();
    final filtrer = _journaux.where((j) {
      final statut = (j['statut'] ?? j['status'] ?? 'BROUILLON')
          .toString()
          .toUpperCase();
      final matchFiltre = switch (_filtreActif) {
        'Brouillons' => statut == 'BROUILLON',
        'Soumis' => statut == 'SOUMIS' || statut == 'EN_ATTENTE',
        'Validés' => statut == 'VALIDE' || statut == 'VALIDÉ',
        _ => true,
      };
      final description =
          (j['summary'] ?? j['learning'] ?? j['description'] ?? '')
              .toString()
              .toLowerCase();
      final date = (j['date'] ?? '').toString().toLowerCase();
      final matchRecherche =
          query.isEmpty || description.contains(query) || date.contains(query);
      return matchFiltre && matchRecherche;
    }).toList();

    final total = _stats['total'] ?? _journaux.length;
    final valides =
        _stats['validated'] ??
        _journaux.where((j) {
          final s = (j['statut'] ?? j['status'] ?? '').toString().toUpperCase();
          return s == 'VALIDE' || s == 'VALIDÉ';
        }).length;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF8FAFC),
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(
            CupertinoIcons.chevron_left,
            color: Color(0xFF0F172A),
            size: 24,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Mes journaux',
          style: GoogleFonts.inter(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: const Color(0xFF0F172A),
          ),
        ),
        actions: [
          IconButton(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(builder: (_) => const MessageriePage()),
            ),
            icon: const Icon(
              CupertinoIcons.chat_bubble_2,
              color: Color(0xFF0F172A),
              size: 24,
            ),
          ),
          IconButton(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => const NotificationsPage(),
              ),
            ),
            icon: const Icon(
              CupertinoIcons.bell,
              color: Color(0xFF0F172A),
              size: 24,
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: _chargement
            ? const Center(
                child: CircularProgressIndicator(color: Color(0xFFFF7417)),
              )
            : RefreshIndicator(
                color: const Color(0xFFFF7417),
                onRefresh: _chargerJournaux,
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(16, 10, 16, 28),
                  children: [
                    // Barre de recherche
                    Container(
                      height: 48,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        children: [
                          const Icon(
                            CupertinoIcons.search,
                            color: Color(0xFF94A3B8),
                            size: 20,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: TextField(
                              controller: _rechercheController,
                              onChanged: (_) => setState(() {}),
                              decoration: InputDecoration(
                                hintText: 'Rechercher une activité, un jour...',
                                hintStyle: GoogleFonts.inter(
                                  fontSize: 14,
                                  color: const Color(0xFF94A3B8),
                                ),
                                border: InputBorder.none,
                                isDense: true,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Bannière bleue Journaux complétés
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1D61F2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Journaux complétés',
                                  style: GoogleFonts.inter(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white.withValues(alpha: 0.8),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '$valides sur $total validés',
                                  style: GoogleFonts.inter(
                                    fontSize: 19,
                                    fontWeight: FontWeight.w900,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          FilledButton.icon(
                            onPressed: () async {
                              final res = await Navigator.of(context).push(
                                MaterialPageRoute<bool>(
                                  builder: (_) => const SaisirJournalPage(),
                                ),
                              );
                              if (res == true) _chargerJournaux();
                            },
                            style: FilledButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: const Color(0xFF1D61F2),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 10,
                              ),
                            ),
                            icon: const Icon(CupertinoIcons.add, size: 16),
                            label: Text(
                              'Nouveau',
                              style: GoogleFonts.inter(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 18),

                    // Filtres horizontaux
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      physics: const BouncingScrollPhysics(),
                      child: Row(
                        children: [
                          _buildFiltreChip('Tous'),
                          const SizedBox(width: 8),
                          _buildFiltreChip('Brouillons'),
                          const SizedBox(width: 8),
                          _buildFiltreChip('Soumis'),
                          const SizedBox(width: 8),
                          _buildFiltreChip('Validés'),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Cartes de journaux
                    if (filtrer.isEmpty)
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 40),
                          child: Text(
                            'Aucun journal trouvé.',
                            style: GoogleFonts.inter(
                              color: const Color(0xFF94A3B8),
                              fontSize: 14,
                            ),
                          ),
                        ),
                      )
                    else
                      ...filtrer.map(
                        (j) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _buildCarteJournal(j),
                        ),
                      ),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildFiltreChip(String label) {
    final estSelectionne = _filtreActif == label;
    return GestureDetector(
      onTap: () => setState(() => _filtreActif = label),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: estSelectionne ? const Color(0xFF0F172A) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: estSelectionne
                ? const Color(0xFF0F172A)
                : const Color(0xFFE2E8F0),
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: estSelectionne ? Colors.white : const Color(0xFF64748B),
          ),
        ),
      ),
    );
  }

  Widget _buildCarteJournal(Map<String, dynamic> j) {
    final statutBrut = (j['statut'] ?? j['status'] ?? 'BROUILLON')
        .toString()
        .toUpperCase();
    Color statutCouleur = const Color(0xFF64748B);
    Color statutBg = const Color(0xFFF1F5F9);
    String statutAffiche = 'BROUILLON';

    if (statutBrut == 'VALIDE' || statutBrut == 'VALIDÉ') {
      statutCouleur = const Color(0xFF16A34A);
      statutBg = const Color(0xFFDCFCE7);
      statutAffiche = 'VALIDÉ';
    } else if (statutBrut == 'SOUMIS' || statutBrut == 'EN_ATTENTE') {
      statutCouleur = const Color(0xFF0284C7);
      statutBg = const Color(0xFFE0F2FE);
      statutAffiche = 'SOUMIS';
    } else if (statutBrut.contains('CORRIG') || statutBrut.contains('REJET')) {
      statutCouleur = const Color(0xFFEA580C);
      statutBg = const Color(0xFFFFF7ED);
      statutAffiche = 'À CORRIGER';
    }

    final date = j['date']?.toString() ?? '';
    final description =
        (j['summary'] ?? j['learning'] ?? j['description'] ?? '').toString();
    final nbActivites =
        (j['activities'] is List
            ? (j['activities'] as List).length
            : j['nombreActivites']) ??
        0;
    final retourEncadreur =
        j['validator_comment'] ??
        j['comment'] ??
        j['feedback'] ??
        j['retourEncadreur'];

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => DetailJournalPage(
                donneesJournal: j,
                dateStage: date,
                statutTexte: statutAffiche,
                estValide: statutAffiche == 'VALIDÉ',
              ),
            ),
          );
        },
        borderRadius: BorderRadius.circular(20),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Date + Badge
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    date,
                    style: GoogleFonts.inter(
                      fontSize: 15.5,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF0F172A),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 9,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: statutBg,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      statutAffiche,
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: statutCouleur,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 10),

              // Description courte
              Text(
                description,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFF64748B),
                ),
              ),

              const SizedBox(height: 10),

              // Ligne nombre activités
              Row(
                children: [
                  const Icon(
                    CupertinoIcons.book,
                    size: 16,
                    color: Color(0xFF64748B),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '$nbActivites activités',
                    style: GoogleFonts.inter(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF64748B),
                    ),
                  ),
                ],
              ),

              // Bloc Retour de l'encadreur
              if (retourEncadreur != null &&
                  retourEncadreur.toString().trim().isNotEmpty) ...[
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF7ED),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFFFEDD5)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Retour de l\'encadreur :',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFFEA580C),
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        retourEncadreur.toString(),
                        style: GoogleFonts.inter(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFF0F172A),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
