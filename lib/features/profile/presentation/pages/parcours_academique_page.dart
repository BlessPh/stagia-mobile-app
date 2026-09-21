import 'package:flutter/material.dart';
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

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Parcours académique')),
    body: ContenuAdaptatif(
      largeurMaximale: 640,
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

          return ListView(
            padding: const EdgeInsets.all(18),
            children: [
              const Text(
                'Inscription actuelle',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 14),
              _FicheAcademique(
                donnees: [
                  ('Université', widget.profil.etablissement),
                  ('Faculté', widget.profil.faculte),
                  ('Département ou filière', widget.profil.filiere),
                  ('Option', widget.profil.option),
                  ('Promotion ou niveau', widget.profil.niveau),
                  ('Année académique', widget.profil.anneeAcademique),
                  ('Matricule', widget.profil.matricule),
                ],
              ),
              const SizedBox(height: 24),
              const Text(
                'Historique académique',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 14),
              if (historique.isEmpty)
                const _EtatVide(
                  'Aucun autre parcours académique n’est disponible.',
                )
              else
                for (final etape in historique)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _FicheAcademique(
                      donnees: [
                        ('Promotion', etape['promotion']?.toString() ?? '-'),
                        ('Année', etape['annee']?.toString() ?? '-'),
                        ('Filière', etape['filiere']?.toString() ?? '-'),
                        ('Faculté', etape['faculte']?.toString() ?? '-'),
                        ('Statut', etape['statut']?.toString() ?? '-'),
                      ],
                    ),
                  ),
            ],
          );
        },
      ),
    ),
  );
}

class _FicheAcademique extends StatelessWidget {
  const _FicheAcademique({required this.donnees});
  final List<(String, String)> donnees;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 4),
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.surfaceContainerLow,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
    ),
    child: Column(
      children: List.generate(donnees.length, (index) {
        final donnee = donnees[index];
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 13),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 145,
                    child: Text(
                      donnee.$1,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      donnee.$2.isEmpty ? 'Non renseigné' : donnee.$2,
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                  ),
                ],
              ),
            ),
            if (index < donnees.length - 1)
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

class _EtatVide extends StatelessWidget {
  const _EtatVide(this.texte);
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
