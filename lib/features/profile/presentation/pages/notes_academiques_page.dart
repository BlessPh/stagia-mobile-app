import 'package:alert_info/alert_info.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:open_filex/open_filex.dart';

import '../../../../core/network/client_api_http.dart';
import '../../../../core/network/reponse_api.dart';
import '../../../../core/network/source_etudiant_distante.dart';
import '../../../../core/network/telechargeur_document_api.dart';
import '../../../../core/widgets/contenu_adaptatif.dart';
import '../../../../core/widgets/erreur_chargement_api.dart';

class NotesAcademiquesPage extends StatefulWidget {
  const NotesAcademiquesPage({this.academicEnrollmentId, super.key});
  final int? academicEnrollmentId;

  @override
  State<NotesAcademiquesPage> createState() => _NotesAcademiquesPageState();
}

class _NotesAcademiquesPageState extends State<NotesAcademiquesPage> {
  final _source = SourceEtudiantDistante(ClientApiHttp());
  final _telechargeur = const TelechargeurDocumentApi();
  late Future<List<Map<String, dynamic>>> _chargement;
  String? _documentEnCours;

  @override
  void initState() {
    super.initState();
    _chargement = _charger();
  }

  Future<List<Map<String, dynamic>>> _charger() => Future.wait([
    _source.notes(widget.academicEnrollmentId),
    _source.resultatsStage(perPage: 100),
  ]);

  Future<void> _actualiser() async {
    final futur = _charger();
    setState(() => _chargement = futur);
    await futur;
  }

  Future<void> _ouvrirCertificat(Map<String, dynamic> document) async {
    final uuid = document['uuid']?.toString().trim() ?? '';
    if (uuid.isEmpty || document['available'] != true) return;
    setState(() => _documentEnCours = uuid);
    try {
      final chemin = await _telechargeur.enregistrerFichier(
        contenu: await _source.fichierCertificat(uuid),
        nom: document['reference']?.toString() ?? 'resultat-stage',
      );
      final resultat = await OpenFilex.open(chemin);
      if (resultat.type != ResultType.done) {
        throw ErreurApi(
          code: 'OUVERTURE_IMPOSSIBLE',
          message: resultat.message,
        );
      }
    } on ErreurApi catch (erreur) {
      if (!mounted) return;
      AlertInfo.show(
        context: context,
        text: erreur.message,
        typeInfo: TypeInfo.error,
      );
    } finally {
      if (mounted) setState(() => _documentEnCours = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final sombre = Theme.of(context).brightness == Brightness.dark;
    final fond = sombre ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC);
    return Scaffold(
      backgroundColor: fond,
      appBar: AppBar(
        backgroundColor: fond,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        title: Text(
          'Notes académiques',
          style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w800),
        ),
      ),
      body: ContenuAdaptatif(
        largeurMaximale: 680,
        enfant: FutureBuilder<List<Map<String, dynamic>>>(
          future: _chargement,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(color: Color(0xFF1D61F2)),
              );
            }
            if (snapshot.hasError) {
              return ErreurChargementApi(
                erreur: snapshot.error,
                onReessayer: _actualiser,
              );
            }
            final notesData = snapshot.data![0];
            final resultatsData = snapshot.data![1];
            final notes = _items(notesData['notes'] ?? notesData['items']);
            final resultats = _items(resultatsData['items']);
            final stats = _map(notesData['stats']);
            final moyenne = stats['average'] ?? stats['moyenne'];
            return RefreshIndicator(
              color: const Color(0xFF1D61F2),
              onRefresh: _actualiser,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(18),
                children: [
                  const _TitreSection(
                    titre: 'Résultats académiques',
                    description: 'Notes publiées dans votre parcours',
                  ),
                  const SizedBox(height: 12),
                  if (notes.isEmpty)
                    const _Vide('Aucune note académique publiée.')
                  else ...[
                    if (moyenne != null) ...[
                      _CarteMoyenne(moyenne: moyenne, total: notes.length),
                      const SizedBox(height: 12),
                    ],
                    for (final note in notes) ...[
                      _CarteNote(note),
                      const SizedBox(height: 12),
                    ],
                  ],
                  const SizedBox(height: 18),
                  const _TitreSection(
                    titre: 'Résultats de stage',
                    description: 'Décisions validées par l’université',
                  ),
                  const SizedBox(height: 12),
                  if (resultats.isEmpty)
                    const _Vide('Aucun résultat de stage publié.')
                  else
                    for (final resultat in resultats) ...[
                      _CarteResultatStage(
                        resultat: resultat,
                        documentEnCours: _documentEnCours,
                        onDocument: _ouvrirCertificat,
                      ),
                      const SizedBox(height: 12),
                    ],
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _TitreSection extends StatelessWidget {
  const _TitreSection({required this.titre, required this.description});
  final String titre;
  final String description;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        titre,
        style: GoogleFonts.inter(fontSize: 19, fontWeight: FontWeight.w900),
      ),
      const SizedBox(height: 3),
      Text(
        description,
        style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
      ),
    ],
  );
}

class _CarteMoyenne extends StatelessWidget {
  const _CarteMoyenne({required this.moyenne, required this.total});
  final Object moyenne;
  final int total;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      color: const Color(0xFF1D61F2),
      borderRadius: BorderRadius.circular(20),
    ),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          '$total matières évaluées',
          style: GoogleFonts.inter(color: Colors.white70),
        ),
        Text(
          '$moyenne / 20',
          style: GoogleFonts.inter(
            fontSize: 24,
            fontWeight: FontWeight.w900,
            color: Colors.white,
          ),
        ),
      ],
    ),
  );
}

class _CarteNote extends StatelessWidget {
  const _CarteNote(this.note);
  final Map<String, dynamic> note;
  @override
  Widget build(BuildContext context) {
    final valeur = note['note_sur_20'] ?? note['note'] ?? '-';
    final resultat =
        note['result']?.toString() ?? note['resultat']?.toString() ?? '';
    return _CarteBase(
      enfant: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  note['subject_name']?.toString() ??
                      note['matiere']?.toString() ??
                      'Matière',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                if (resultat.isNotEmpty) ...[
                  const SizedBox(height: 5),
                  Text(
                    resultat,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ],
            ),
          ),
          Text(
            '$valeur / 20',
            style: GoogleFonts.inter(
              fontSize: 17,
              fontWeight: FontWeight.w900,
              color: const Color(0xFF1D61F2),
            ),
          ),
        ],
      ),
    );
  }
}

class _CarteResultatStage extends StatelessWidget {
  const _CarteResultatStage({
    required this.resultat,
    required this.documentEnCours,
    required this.onDocument,
  });
  final Map<String, dynamic> resultat;
  final String? documentEnCours;
  final ValueChanged<Map<String, dynamic>> onDocument;
  @override
  Widget build(BuildContext context) {
    final campaign = _map(resultat['campaign']);
    final hospital = _map(resultat['hospital']);
    final document = _map(resultat['document']);
    final decision = resultat['decision']?.toString();
    final score = resultat['score'];
    final processus = _map(resultat['administrative_process']);
    final statut = decision ?? processus['status']?.toString() ?? 'EN_ATTENTE';
    final chargement = documentEnCours == document['uuid']?.toString();
    return _CarteBase(
      enfant: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            campaign['title']?.toString() ?? 'Stage',
            style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w900),
          ),
          if (hospital['name'] != null) ...[
            const SizedBox(height: 4),
            Text(
              hospital['name'].toString(),
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 8,
            children: [
              _Pastille(statut),
              if (score != null) _Pastille('Score : $score'),
            ],
          ),
          if ((resultat['appreciation']?.toString() ?? '').isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(resultat['appreciation'].toString()),
          ],
          if (document['available'] == true) ...[
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: chargement ? null : () => onDocument(document),
              icon: chargement
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.description_outlined),
              label: const Text('Ouvrir l’attestation'),
            ),
          ],
        ],
      ),
    );
  }
}

class _Pastille extends StatelessWidget {
  const _Pastille(this.texte);
  final String texte;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
    decoration: BoxDecoration(
      color: const Color(0xFF1D61F2).withValues(alpha: .1),
      borderRadius: BorderRadius.circular(18),
    ),
    child: Text(
      texte,
      style: const TextStyle(
        color: Color(0xFF1D61F2),
        fontWeight: FontWeight.w800,
        fontSize: 12,
      ),
    ),
  );
}

class _CarteBase extends StatelessWidget {
  const _CarteBase({required this.enfant});
  final Widget enfant;
  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.surface,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
    ),
    child: enfant,
  );
}

class _Vide extends StatelessWidget {
  const _Vide(this.texte);
  final String texte;
  @override
  Widget build(BuildContext context) => _CarteBase(
    enfant: Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Text(
        texte,
        textAlign: TextAlign.center,
        style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
      ),
    ),
  );
}

List<Map<String, dynamic>> _items(Object? valeur) => valeur is List
    ? valeur.whereType<Map>().map(Map<String, dynamic>.from).toList()
    : <Map<String, dynamic>>[];

Map<String, dynamic> _map(Object? valeur) =>
    valeur is Map ? Map<String, dynamic>.from(valeur) : <String, dynamic>{};
