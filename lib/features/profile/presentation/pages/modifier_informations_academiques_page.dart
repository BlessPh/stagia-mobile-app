import 'package:flutter/material.dart';
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
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Information académique')),
    body: ContenuAdaptatif(
      largeurMaximale: 720,
      enfant: FutureBuilder<_DonneesAcademiques>(
        future: _chargement,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return _ErreurChargement(onReessayer: _actualiser);
          }

          final donnees = snapshot.data ?? const _DonneesAcademiques();
          if (donnees.inscription.isEmpty) {
            return RefreshIndicator(
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
            ('Promotion', _texte(promotionCourante['name'])),
            ('Niveau', _texte(courant['level'])),
            ('Année académique', _texte(anneeCourante['label'])),
          ];

          return RefreshIndicator(
            onRefresh: _actualiser,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(18, 18, 18, 32),
              children: [
                const _TitreSection('Année en cours'),
                const SizedBox(height: 12),
                _CarteInformations(champs: champsCourants),
                const SizedBox(height: 26),
                const _TitreSection('Historique'),
                const SizedBox(height: 12),
                if (historique.isEmpty)
                  const _BlocVide(
                    texte: 'Aucun historique académique disponible.',
                  )
                else
                  for (final annee in historique)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _CarteHistorique(annee: annee),
                    ),
              ],
            ),
          );
        },
      ),
    ),
  );
}

class _DonneesAcademiques {
  const _DonneesAcademiques({
    this.inscription = const {},
    this.parcours = const {},
  });

  final Map<String, dynamic> inscription;
  final Map<String, dynamic> parcours;
}

class _TitreSection extends StatelessWidget {
  const _TitreSection(this.texte);
  final String texte;

  @override
  Widget build(BuildContext context) => Text(
    texte,
    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
  );
}

class _CarteInformations extends StatelessWidget {
  const _CarteInformations({required this.champs});
  final List<(String, String)> champs;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 4),
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.surfaceContainerLow,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
    ),
    child: Column(
      children: List.generate(champs.length, (index) {
        final champ = champs[index];
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 13),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 135,
                    child: Text(
                      champ.$1,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      champ.$2.isEmpty ? 'Non renseigné' : champ.$2,
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                  ),
                ],
              ),
            ),
            if (index < champs.length - 1)
              Divider(
                height: 1,
                color: Theme.of(context).colorScheme.outlineVariant,
              ),
          ],
        );
      }),
    ),
  );
}

class _CarteHistorique extends StatelessWidget {
  const _CarteHistorique({required this.annee});
  final Map<String, dynamic> annee;

  @override
  Widget build(BuildContext context) {
    final anneeAcademique = _map(annee['academic_year']);
    final promotion = _map(annee['promotion']);
    return _CarteInformations(
      champs: [
        ('Année académique', _texte(anneeAcademique['label'])),
        ('Promotion', _texte(promotion['name'])),
        ('Niveau', _texte(annee['level'])),
      ],
    );
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
