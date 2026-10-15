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

class DocumentsOfficielsPage extends StatefulWidget {
  const DocumentsOfficielsPage({super.key});

  @override
  State<DocumentsOfficielsPage> createState() => _DocumentsOfficielsPageState();
}

class _DocumentsOfficielsPageState extends State<DocumentsOfficielsPage> {
  final _source = SourceEtudiantDistante(ClientApiHttp());
  final _telechargeur = const TelechargeurDocumentApi();
  late Future<Map<String, dynamic>> _chargement;
  String _filtre = 'Tous';
  String? _documentEnCours;

  @override
  void initState() {
    super.initState();
    _chargement = _source.documents(perPage: 100);
  }

  Future<void> _actualiser() async {
    final futur = _source.documents(perPage: 100);
    setState(() => _chargement = futur);
    await futur;
  }

  Future<void> _ouvrir(
    Map<String, dynamic> document, {
    bool download = false,
  }) async {
    final uuid = document['uuid']?.toString().trim() ?? '';
    if (uuid.isEmpty || document['available'] != true) return;
    setState(() => _documentEnCours = uuid);
    try {
      final chemin = await _telechargeur.enregistrerFichier(
        contenu: await _source.fichierCertificat(uuid, download: download),
        nom: document['reference']?.toString() ?? 'document-stage',
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
        surfaceTintColor: Colors.transparent,
        title: Text(
          'Attestations et certificats',
          style: GoogleFonts.inter(fontWeight: FontWeight.w800),
        ),
      ),
      body: ContenuAdaptatif(
        largeurMaximale: 680,
        enfant: FutureBuilder<Map<String, dynamic>>(
          future: _chargement,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return ErreurChargementApi(
                erreur: snapshot.error,
                onReessayer: _actualiser,
              );
            }
            final documents = _items(snapshot.data?['items'])
                .where((document) {
                  return switch (_filtre) {
                    'Disponibles' => document['available'] == true,
                    'En attente' => document['available'] != true,
                    _ => true,
                  };
                })
                .toList(growable: false);
            return RefreshIndicator(
              onRefresh: _actualiser,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(18),
                children: [
                  Text(
                    'Documents officiels liés à vos stages',
                    style: GoogleFonts.inter(
                      fontSize: 19,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    children: ['Tous', 'Disponibles', 'En attente']
                        .map(
                          (filtre) => ChoiceChip(
                            label: Text(filtre),
                            selected: _filtre == filtre,
                            showCheckmark: false,
                            onSelected: (_) => setState(() => _filtre = filtre),
                          ),
                        )
                        .toList(growable: false),
                  ),
                  const SizedBox(height: 16),
                  if (documents.isEmpty)
                    const _DocumentVide()
                  else
                    for (final document in documents) ...[
                      _CarteDocumentOfficiel(
                        document: document,
                        chargement:
                            _documentEnCours == document['uuid']?.toString(),
                        onOuvrir: () => _ouvrir(document),
                        onTelecharger: () => _ouvrir(document, download: true),
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

class _CarteDocumentOfficiel extends StatelessWidget {
  const _CarteDocumentOfficiel({
    required this.document,
    required this.chargement,
    required this.onOuvrir,
    required this.onTelecharger,
  });
  final Map<String, dynamic> document;
  final bool chargement;
  final VoidCallback onOuvrir;
  final VoidCallback onTelecharger;

  @override
  Widget build(BuildContext context) {
    final campaign = _map(document['campaign']);
    final hospital = _map(document['hospital']);
    final disponible = document['available'] == true;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.workspace_premium_outlined,
                color: Color(0xFF1D61F2),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  document['type_label']?.toString() ??
                      document['type_document']?.toString() ??
                      document['type']?.toString() ??
                      'Document de stage',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(campaign['title']?.toString() ?? 'Stage'),
          if (hospital['name'] != null) Text(hospital['name'].toString()),
          if (document['reference'] != null) ...[
            const SizedBox(height: 6),
            Text(
              document['reference'].toString(),
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
          const SizedBox(height: 12),
          if (!disponible)
            Text(
              document['availability_reason']?.toString() ??
                  'Document en attente de validation.',
              style: const TextStyle(
                color: Color(0xFFF59E0B),
                fontWeight: FontWeight.w700,
              ),
            )
          else
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: chargement ? null : onOuvrir,
                    icon: const Icon(Icons.visibility_outlined),
                    label: const Text('Ouvrir'),
                  ),
                ),
                const SizedBox(width: 10),
                IconButton.outlined(
                  tooltip: 'Télécharger',
                  onPressed: chargement ? null : onTelecharger,
                  icon: chargement
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.download_outlined),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

class _DocumentVide extends StatelessWidget {
  const _DocumentVide();
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(24),
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.surface,
      borderRadius: BorderRadius.circular(20),
    ),
    child: const Center(child: Text('Aucun document officiel à afficher.')),
  );
}

List<Map<String, dynamic>> _items(Object? valeur) => valeur is List
    ? valeur.whereType<Map>().map(Map<String, dynamic>.from).toList()
    : <Map<String, dynamic>>[];

Map<String, dynamic> _map(Object? valeur) =>
    valeur is Map ? Map<String, dynamic>.from(valeur) : <String, dynamic>{};
