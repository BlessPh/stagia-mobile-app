import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';
import '../../../../core/network/client_api_http.dart';
import '../../../../core/network/source_etudiant_distante.dart';
import '../../../../core/widgets/contenu_adaptatif.dart';
import '../../data/models/etudiant_profil.dart';

class ParcoursAcademiquePage extends StatefulWidget {
  const ParcoursAcademiquePage({required this.profil, super.key});

  final EtudiantProfil profil;

  @override
  State<ParcoursAcademiquePage> createState() => _ParcoursAcademiquePageState();
}

class _ParcoursAcademiquePageState extends State<ParcoursAcademiquePage> {
  final _source = SourceEtudiantDistante(ClientApiHttp());
  late Future<Map<String, dynamic>> _chargement;

  @override
  void initState() {
    super.initState();
    _chargement = _source.parcoursAcademique();
  }

  Future<void> _actualiser() async {
    final chargement = _source.parcoursAcademique();
    setState(() => _chargement = chargement);
    await chargement;
  }

  @override
  Widget build(BuildContext context) {
    final modeSombre = Theme.of(context).brightness == Brightness.dark;
    final fondPage = modeSombre ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC);
    final texteCouleur = modeSombre ? Colors.white : const Color(0xFF0F172A);

    return Scaffold(
      backgroundColor: fondPage,
      appBar: AppBar(
        backgroundColor: fondPage,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            size: 20,
            color: texteCouleur,
          ),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: Text(
          'Parcours académique',
          style: GoogleFonts.inter(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: texteCouleur,
          ),
        ),
        centerTitle: true,
      ),
      body: ContenuAdaptatif(
        largeurMaximale: 680,
        enfant: FutureBuilder<Map<String, dynamic>>(
          future: _chargement,
          builder: (context, snapshot) {
            final donnees = snapshot.data;
            final historique = donnees != null && donnees['academic_path'] is List
                ? (donnees['academic_path'] as List)
                    .whereType<Map>()
                    .map((e) => Map<String, dynamic>.from(e))
                    .toList()
                : <Map<String, dynamic>>[];

            return RefreshIndicator(
              color: const Color(0xFF1D61F2),
              onRefresh: _actualiser,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 36),
                children: [
                  _EnTeteSection(
                    titre: 'Inscription actuelle',
                    sousTitre: 'Cursus en cours dans l’établissement',
                    icone: Iconsax.teacher,
                  ),
                  const SizedBox(height: 12),
                  _TableauDeuxColonnes(
                    champs: [
                      ('Université', widget.profil.etablissement),
                      ('Faculté', widget.profil.faculte),
                      ('Département ou filière', widget.profil.filiere),
                      ('Option', widget.profil.option),
                      ('Promotion ou niveau', widget.profil.niveau),
                      ('Année académique', widget.profil.anneeAcademique),
                      ('Matricule', widget.profil.matricule),
                    ],
                  ),
                  const SizedBox(height: 32),
                  _EnTeteSection(
                    titre: 'Historique académique',
                    sousTitre: 'Parcours antérieur dans cette université',
                    icone: Iconsax.clock,
                  ),
                  const SizedBox(height: 12),
                  if (historique.isEmpty)
                    const _EtatVide(
                      'Aucun autre parcours académique n’est disponible.',
                    )
                  else
                    for (int i = 0; i < historique.length; i++)
                      Padding(
                        padding: EdgeInsets.only(
                          bottom: i < historique.length - 1 ? 16 : 0,
                        ),
                        child: _TableauDeuxColonnes(
                          champs: [
                            ('Promotion', historique[i]['promotion']?.toString() ?? '-'),
                            ('Année académique', historique[i]['annee']?.toString() ?? '-'),
                            ('Filière', historique[i]['filiere']?.toString() ?? '-'),
                            ('Faculté', historique[i]['faculte']?.toString() ?? '-'),
                            ('Statut', historique[i]['statut']?.toString() ?? '-'),
                          ],
                        ),
                      ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _EnTeteSection extends StatelessWidget {
  const _EnTeteSection({
    required this.titre,
    required this.sousTitre,
    required this.icone,
  });

  final String titre;
  final String sousTitre;
  final IconData icone;

  @override
  Widget build(BuildContext context) {
    final modeSombre = Theme.of(context).brightness == Brightness.dark;
    final texteCouleur = modeSombre ? Colors.white : const Color(0xFF0F172A);
    final texteSecondaire = modeSombre ? const Color(0xFF94A3B8) : const Color(0xFF64748B);

    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: const Color(0xFF1D61F2).withValues(alpha: modeSombre ? 0.2 : 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          alignment: Alignment.center,
          child: Icon(icone, color: const Color(0xFF1D61F2), size: 18),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                titre,
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: texteCouleur,
                ),
              ),
              const SizedBox(height: 1),
              Text(
                sousTitre,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: texteSecondaire,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _TableauDeuxColonnes extends StatelessWidget {
  const _TableauDeuxColonnes({required this.champs});
  final List<(String, String)> champs;

  @override
  Widget build(BuildContext context) {
    final modeSombre = Theme.of(context).brightness == Brightness.dark;
    final fondCarte = modeSombre ? const Color(0xFF1E293B) : Colors.white;
    final bordureCarte = modeSombre ? const Color(0xFF334155) : const Color(0xFFE2E8F0);
    final couleurLibelle = modeSombre ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
    final couleurValeur = modeSombre ? Colors.white : const Color(0xFF0F172A);

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: fondCarte,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: bordureCarte),
        boxShadow: [
          BoxShadow(
            color: modeSombre ? const Color(0x30000000) : const Color(0x05000000),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Table(
        columnWidths: const {
          0: FlexColumnWidth(1.15),
          1: FlexColumnWidth(1.85),
        },
        defaultVerticalAlignment: TableCellVerticalAlignment.middle,
        children: champs.map((champ) {
          final libelle = champ.$1;
          final valeur = champ.$2.isEmpty ? 'Non renseigné' : champ.$2;
          final estNonRenseigne = champ.$2.isEmpty || champ.$2 == '-';

          return TableRow(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 9),
                child: Text(
                  libelle,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: couleurLibelle,
                    letterSpacing: -0.1,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 9),
                child: Text(
                  valeur,
                  textAlign: TextAlign.end,
                  style: GoogleFonts.inter(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    color: estNonRenseigne
                        ? (modeSombre ? const Color(0xFF64748B) : const Color(0xFF94A3B8))
                        : couleurValeur,
                    letterSpacing: -0.1,
                  ),
                ),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }
}

class _EtatVide extends StatelessWidget {
  const _EtatVide(this.texte);
  final String texte;

  @override
  Widget build(BuildContext context) {
    final modeSombre = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: modeSombre ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: modeSombre ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
        ),
      ),
      child: Text(
        texte,
        textAlign: TextAlign.center,
        style: GoogleFonts.inter(
          fontSize: 13.5,
          color: modeSombre ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
        ),
      ),
    );
  }
}
