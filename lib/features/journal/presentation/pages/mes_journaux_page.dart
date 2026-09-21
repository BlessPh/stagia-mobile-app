import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'detail_journal_page.dart';
import 'saisir_journal_page.dart';

class MesJournauxPage extends StatefulWidget {
  const MesJournauxPage({super.key});

  @override
  State<MesJournauxPage> createState() => _MesJournauxPageState();
}

class _MesJournauxPageState extends State<MesJournauxPage> {
  String _filtreActif = 'Tous';
  final TextEditingController _rechercheController = TextEditingController();

  final List<Map<String, dynamic>> _journaux = [
    {
      'date': '15 Jan 2026',
      'statut': 'VALIDÉ',
      'statutCouleur': const Color(0xFF16A34A),
      'statutBg': const Color(0xFFDCFCE7),
      'description': 'Prise en charge de 4 traumas thoraciques légers et sut...',
      'nombreActivites': 5,
      'retourEncadreur': 'Excellent compte-rendu, très pro.',
      'actionLibelle': null,
    },
    {
      'date': '14 Jan 2026',
      'statut': 'SOUMIS',
      'statutCouleur': const Color(0xFF0284C7),
      'statutBg': const Color(0xFFE0F2FE),
      'description': 'Observation de pose de drain thoracique par le Dr. Dup...',
      'nombreActivites': 3,
      'retourEncadreur': null,
      'actionLibelle': null,
    },
    {
      'date': '13 Jan 2026',
      'statut': 'À CORRIGER',
      'statutCouleur': const Color(0xFFEA580C),
      'statutBg': const Color(0xFFFFF7ED),
      'description': 'Suture complexe avant-bras sous AL. À corriger selon r...',
      'nombreActivites': 2,
      'retourEncadreur': 'Préciser la quantité d\'anesthésique.',
      'actionLibelle': 'Reprendre',
    },
    {
      'date': '12 Jan 2026',
      'statut': 'BROUILLON',
      'statutCouleur': const Color(0xFF64748B),
      'statutBg': const Color(0xFFF1F5F9),
      'description': 'Journée de garde active. Multiples petites chirurgies et...',
      'nombreActivites': 6,
      'retourEncadreur': null,
      'actionLibelle': 'Modifier & Soumettre',
    },
  ];

  @override
  void dispose() {
    _rechercheController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final query = _rechercheController.text.trim().toLowerCase();
    final filtrer = _journaux.where((j) {
      final statut = j['statut'] as String;
      final matchFiltre = switch (_filtreActif) {
        'Brouillons' => statut == 'BROUILLON',
        'Soumis' => statut == 'SOUMIS',
        'Validés' => statut == 'VALIDÉ',
        _ => true,
      };
      final matchRecherche = query.isEmpty ||
          (j['description'] as String).toLowerCase().contains(query) ||
          (j['date'] as String).toLowerCase().contains(query);
      return matchFiltre && matchRecherche;
    }).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF8FAFC),
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(CupertinoIcons.chevron_left, color: Color(0xFF0F172A), size: 24),
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
            onPressed: () {},
            icon: const Icon(CupertinoIcons.chat_bubble_2, color: Color(0xFF0F172A), size: 24),
          ),
          IconButton(
            onPressed: () {},
            icon: const Icon(CupertinoIcons.bell, color: Color(0xFF0F172A), size: 24),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
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
                  const Icon(CupertinoIcons.search, color: Color(0xFF94A3B8), size: 20),
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

            // Bannière bleue Journaus complétés
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: const Color(0xFF1D61F2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Journaux complétés',
                        style: GoogleFonts.inter(
                          fontSize: 15.5,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        '12 / 15 jours',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: const LinearProgressIndicator(
                      value: 12 / 15,
                      minHeight: 7,
                      backgroundColor: Color(0x33FFFFFF),
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Prochain point de contrôle : Fin de 2ème semaine',
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

            // Filtres (Tous, Brouillons, Soumis, Validés)
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
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

            // Liste des cartes de journaux
            for (final j in filtrer)
              Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: _buildCarteJournal(j),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildFiltreChip(String titre) {
    final actif = _filtreActif == titre;
    return GestureDetector(
      onTap: () => setState(() => _filtreActif = titre),
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

  Widget _buildCarteJournal(Map<String, dynamic> j) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => DetailJournalPage(
                dateStage: j['date'] as String,
                statutTexte: j['statut'] as String,
                estValide: j['statut'] == 'VALIDÉ',
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
                    j['date'] as String,
                    style: GoogleFonts.inter(
                      fontSize: 15.5,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF0F172A),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                    decoration: BoxDecoration(
                      color: j['statutBg'] as Color,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      j['statut'] as String,
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: j['statutCouleur'] as Color,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 10),

              // Description courte
              Text(
                j['description'] as String,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFF64748B),
                ),
              ),

              const SizedBox(height: 10),

              // Ligne nombre activités + Action optionnelle
              Row(
                children: [
                  const Icon(CupertinoIcons.book, size: 16, color: Color(0xFF64748B)),
                  const SizedBox(width: 6),
                  Text(
                    '${j['nombreActivites']} activités',
                    style: GoogleFonts.inter(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF64748B),
                    ),
                  ),
                  if (j['actionLibelle'] != null) ...[
                    const Spacer(),
                    GestureDetector(
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => SaisirJournalPage(
                              dateInitiale: j['date'] as String,
                            ),
                          ),
                        );
                      },
                      child: Text(
                        j['actionLibelle'] as String,
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: j['actionLibelle'] == 'Reprendre'
                              ? const Color(0xFFEA580C)
                              : const Color(0xFF1D61F2),
                        ),
                      ),
                    ),
                  ],
                ],
              ),

              // Bloc Retour de l'encadreur
              if (j['retourEncadreur'] != null) ...[
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
                        j['retourEncadreur'] as String,
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
