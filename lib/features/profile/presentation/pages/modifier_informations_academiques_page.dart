import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';
import '../../../../core/network/client_api_http.dart';
import '../../../../core/network/source_etudiant_distante.dart';
import '../../../../core/widgets/contenu_adaptatif.dart';

class InformationsAcademiquesPage extends StatefulWidget {
  const InformationsAcademiquesPage({super.key});

  @override
  State<InformationsAcademiquesPage> createState() =>
      _InformationsAcademiquesPageState();
}

class _InformationsAcademiquesPageState
    extends State<InformationsAcademiquesPage> {
  final _source = SourceEtudiantDistante(ClientApiHttp());
  late Future<_DonneesAcademiques> _chargement;

  @override
  void initState() {
    super.initState();
    _chargement = _charger();
  }

  Future<_DonneesAcademiques> _charger() async {
    final rattachements = await _source.rattachements();
    final inscriptions = _liste(rattachements['items']);
    final inscription = _selectionnerInscription(inscriptions);
    if (inscription == null) return const _DonneesAcademiques();

    final enrollmentId = _entier(inscription['enrollment_id']);
    Map<String, dynamic> parcours = const {};
    if (enrollmentId != null) {
      try {
        parcours = await _source.parcoursAcademique(enrollmentId);
      } catch (_) {
        // L'année courante reste disponible depuis /student/enrollments.
      }
    }
    return _DonneesAcademiques(inscription: inscription, parcours: parcours);
  }

  Future<void> _actualiser() async {
    final chargement = _charger();
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
          'Information académique',
          style: GoogleFonts.inter(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: texteCouleur,
          ),
        ),
        centerTitle: true,
      ),
      body: ContenuAdaptatif(
        largeurMaximale: 720,
        enfant: FutureBuilder<_DonneesAcademiques>(
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
              return _ErreurChargement(onReessayer: _actualiser);
            }

            final donnees = snapshot.data ?? const _DonneesAcademiques();
            if (donnees.inscription.isEmpty) {
              return RefreshIndicator(
                color: const Color(0xFF1D61F2),
                onRefresh: _actualiser,
                child: const _ListeVide(
                  texte: 'Aucune information académique disponible.',
                ),
              );
            }

            final inscription = donnees.inscription;
            final parcours = donnees.parcours;
            final universiteInscription = _map(inscription['university']);
            final structure = _map(inscription['academic_structure']);
            final uniteAcademique = _map(structure['academic_unit']);
            final departementInscription = _map(structure['department']);
            final filiereInscription = _map(structure['program']);
            final courantInscription = _map(inscription['current_academic']);

            final universiteParcours = _map(parcours['university']);
            final curriculum = _map(parcours['curriculum']);
            final faculteParcours = _map(curriculum['faculty']);
            final departementParcours = _map(curriculum['department']);
            final filiereParcours = _map(curriculum['program']);
            final annees = _liste(parcours['academic_years']);
            final courantParcours = _selectionnerAnneeCourante(annees);
            final historique = annees
                .where((annee) => annee['is_current'] != true)
                .toList();
            final courant = courantInscription.isNotEmpty
                ? courantInscription
                : courantParcours;
            final anneeCourante = _map(courant['academic_year']);
            final promotionCourante = _map(courant['promotion']);
            final filiere = _premierTexte([
              filiereInscription['name'],
              filiereParcours['name'],
            ]);
            final matricule = _premierTexte([
              inscription['student_number'],
              inscription['registration_number'],
              inscription['matricule'],
              parcours['student_number'],
              parcours['matricule'],
            ]);

            final champsCourants = <(String, String)>[
              (
                'Université',
                _premierTexte([
                  universiteInscription['name'],
                  universiteParcours['name'],
                ]),
              ),
              (
                'Faculté',
                _premierTexte([uniteAcademique['name'], faculteParcours['name']]),
              ),
              (
                'Département',
                _premierTexte([
                  departementInscription['name'],
                  departementParcours['name'],
                ]),
              ),
              if (filiere.isNotEmpty) ('Filière', filiere),
              if (matricule.isNotEmpty) ('Matricule', matricule),
              ('Promotion', _texte(promotionCourante['name'])),
              ('Niveau', _texte(courant['level'])),
              ('Année académique', _texte(anneeCourante['label'])),
            ];

            return RefreshIndicator(
              color: const Color(0xFF1D61F2),
              onRefresh: _actualiser,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 36),
                children: [
                  // Section 1 : Inscription académique actuelle
                  _EnTeteSection(
                    titre: 'Inscription académique',
                    sousTitre: 'Votre affectation et cursus en cours',
                    icone: Iconsax.teacher,
                  ),
                  const SizedBox(height: 12),
                  _TableauDeuxColonnes(champs: champsCourants),

                  const SizedBox(height: 32),

                  // Section 2 : Historique académique
                  _EnTeteSection(
                    titre: 'Historique académique',
                    sousTitre: 'Parcours antérieur dans cette université',
                    icone: Iconsax.clock,
                  ),
                  const SizedBox(height: 12),
                  if (historique.isEmpty)
                    const _BlocVide(
                      texte: 'Aucun historique académique antérieur disponible.',
                    )
                  else
                    for (int i = 0; i < historique.length; i++)
                      Padding(
                        padding: EdgeInsets.only(bottom: i < historique.length - 1 ? 16 : 0),
                        child: _CarteHistorique(annee: historique[i]),
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

class _DonneesAcademiques {
  const _DonneesAcademiques({
    this.inscription = const {},
    this.parcours = const {},
  });

  final Map<String, dynamic> inscription;
  final Map<String, dynamic> parcours;
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

/// Tableau à deux colonnes épuré, propre et moderne sans bordures de séparation de lignes ni colonnes
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
          final estNonRenseigne = champ.$2.isEmpty;

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

class _CarteHistorique extends StatelessWidget {
  const _CarteHistorique({required this.annee});
  final Map<String, dynamic> annee;

  @override
  Widget build(BuildContext context) {
    final anneeAcademique = _map(annee['academic_year']);
    final promotion = _map(annee['promotion']);
    final statut = _texte(annee['status']);

    final champs = <(String, String)>[
      ('Année académique', _texte(anneeAcademique['label'])),
      ('Promotion', _texte(promotion['name'])),
      ('Niveau', _texte(annee['level'])),
      if (statut.isNotEmpty) ('Statut', statut),
    ];

    return _TableauDeuxColonnes(champs: champs);
  }
}

class _BlocVide extends StatelessWidget {
  const _BlocVide({required this.texte});
  final String texte;

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.surfaceContainerLow,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
    ),
    child: Text(texte, textAlign: TextAlign.center),
  );
}

class _ListeVide extends StatelessWidget {
  const _ListeVide({required this.texte});
  final String texte;

  @override
  Widget build(BuildContext context) => ListView(
    physics: const AlwaysScrollableScrollPhysics(),
    padding: const EdgeInsets.all(18),
    children: [_BlocVide(texte: texte)],
  );
}

class _ErreurChargement extends StatelessWidget {
  const _ErreurChargement({required this.onReessayer});
  final Future<void> Function() onReessayer;

  @override
  Widget build(BuildContext context) => Center(
    child: TextButton(
      onPressed: onReessayer,
      child: const Text('Chargement impossible · Réessayer'),
    ),
  );
}

Map<String, dynamic>? _selectionnerInscription(
  List<Map<String, dynamic>> inscriptions,
) {
  for (final inscription in inscriptions) {
    if (inscription['is_active'] == true) return inscription;
  }
  return inscriptions.isEmpty ? null : inscriptions.first;
}

Map<String, dynamic> _selectionnerAnneeCourante(
  List<Map<String, dynamic>> annees,
) {
  for (final annee in annees) {
    if (annee['is_current'] == true) return annee;
  }
  return annees.isEmpty ? const {} : annees.first;
}

Map<String, dynamic> _map(Object? valeur) =>
    valeur is Map ? Map<String, dynamic>.from(valeur) : <String, dynamic>{};

List<Map<String, dynamic>> _liste(Object? valeur) => valeur is List
    ? valeur.whereType<Map>().map(Map<String, dynamic>.from).toList()
    : <Map<String, dynamic>>[];

int? _entier(Object? valeur) =>
    valeur is num ? valeur.toInt() : int.tryParse(valeur?.toString() ?? '');

String _texte(Object? valeur) => valeur?.toString().trim() ?? '';

String _premierTexte(List<Object?> valeurs) {
  for (final valeur in valeurs) {
    final texte = _texte(valeur);
    if (texte.isNotEmpty) return texte;
  }
  return '';
}
