import 'package:alert_info/alert_info.dart';
import 'package:flutter/material.dart';
import 'package:open_filex/open_filex.dart';
import '../../../../core/network/client_api_http.dart';
import '../../../../core/network/reponse_api.dart';
import '../../../../core/network/source_etudiant_distante.dart';
import '../../../../core/network/telechargeur_document_api.dart';
import '../../../../core/widgets/contenu_adaptatif.dart';
import '../../../../core/widgets/erreur_chargement_api.dart';
import '../../data/mappers/mappeur_affectation_stage_api.dart';
import '../widgets/onglets_stage.dart';

class MonStagePage extends StatefulWidget {
  const MonStagePage({this.assignmentReference, super.key});

  final String? assignmentReference;
  @override
  State<MonStagePage> createState() => _MonStagePageState();
}

class _MonStagePageState extends State<MonStagePage> {
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
    _source.stages(),
    _source.cloturesStage(perPage: 100),
    _source.documents(perPage: 100),
    _source.conventions(),
  ]);

  Future<void> _actualiser() async {
    final futur = _charger();
    setState(() => _chargement = futur);
    await futur;
  }

  Future<void> _ouvrirDocument(Map<String, dynamic> document) async {
    final uuid = document['uuid']?.toString().trim() ?? '';
    final endpoint =
        document['file_endpoint']?.toString() ??
        document['view_endpoint']?.toString() ??
        document['download_endpoint']?.toString() ??
        document['pdf_endpoint']?.toString();
    final typeDocument =
        (document['type'] ?? document['type_document'])
            ?.toString()
            .toUpperCase() ??
        '';
    final estDocumentOfficiel =
        (endpoint?.contains('/certificates/') ?? false) ||
        typeDocument.contains('ATTESTATION') ||
        typeDocument.contains('CERTIFICAT');
    final cheminLocal = document['local_path']?.toString();
    if (estDocumentOfficiel && document['available'] != true) {
      AlertInfo.show(
        context: context,
        text:
            document['availability_reason']?.toString() ??
            'Ce document n’est pas encore disponible.',
        typeInfo: TypeInfo.warning,
      );
      return;
    }
    if ((endpoint == null || endpoint.isEmpty) &&
        uuid.isEmpty &&
        (cheminLocal == null || cheminLocal.isEmpty)) {
      AlertInfo.show(
        context: context,
        text: 'Ce document ne possède aucun fichier accessible.',
        typeInfo: TypeInfo.warning,
      );
      return;
    }
    setState(() => _documentEnCours = document['uuid']?.toString());
    try {
      final chemin = cheminLocal != null && cheminLocal.isNotEmpty
          ? cheminLocal
          : estDocumentOfficiel && uuid.isNotEmpty
          ? await _telechargeur.enregistrerFichier(
              contenu: await _source.fichierCertificat(uuid),
              nom: document['reference']?.toString() ?? 'document-stagia',
            )
          : await _telechargeur.telechargerPdf(
              endpoint: endpoint!,
              nom:
                  document['reference']?.toString() ??
                  document['title']?.toString() ??
                  'document-stagia',
            );
      final resultat = await OpenFilex.open(chemin);
      if (!mounted || resultat.type == ResultType.done) return;
      throw ErreurApi(code: 'OUVERTURE_IMPOSSIBLE', message: resultat.message);
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
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      automaticallyImplyLeading: false,
      bottom: const PreferredSize(
        preferredSize: Size.fromHeight(44),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: OngletsStage(ongletActif: OngletStage.mesStages),
        ),
      ),
    ),
    body: ContenuAdaptatif(
      enfant: FutureBuilder<List<Map<String, dynamic>>>(
        future: _chargement,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFFFF7417)),
            );
          }
          if (snapshot.hasError) {
            return ErreurChargementApi(
              erreur: snapshot.error,
              onReessayer: _actualiser,
            );
          }
          final reponses = snapshot.data!;
          final stages = _items(reponses[0]['items']);
          final completions = _items(reponses[1]['items']);
          final documentsOfficiels = _items(reponses[2]['items']);
          final conventions = _items(reponses[3]['items']);
          final stage = _selectionnerStage(stages);
          final reference = stage?['assignment_uuid']?.toString();
          final completion = completions
              .cast<Map<String, dynamic>?>()
              .firstWhere(
                (item) =>
                    _map(item?['assignment'])['uuid']?.toString() == reference,
                orElse: () => null,
              );
          final documentsDuStage = documentsOfficiels.where((document) {
            final assignment = _map(document['assignment']);
            final stageDocument = _map(document['stage']);
            final documentReference =
                assignment['uuid']?.toString() ??
                stageDocument['assignment_uuid']?.toString() ??
                document['assignment_uuid']?.toString();
            return reference == null ||
                documentReference == null ||
                documentReference == reference;
          });
          final conventionsDuStage = conventions.where((document) {
            final assignment = _map(document['assignment']);
            final documentReference =
                assignment['uuid']?.toString() ??
                document['assignment_uuid']?.toString();
            return reference == null ||
                documentReference == null ||
                documentReference == reference;
          });
          final tousDocuments = [...documentsDuStage, ...conventionsDuStage];

          return _ContenuStage(
            stage: stage,
            completion: completion,
            documents: tousDocuments,
            documentEnCours: _documentEnCours,
            onDocument: _ouvrirDocument,
            onRefresh: _actualiser,
          );
        },
      ),
    ),
  );

  Map<String, dynamic>? _selectionnerStage(List<Map<String, dynamic>> stages) {
    final reference = widget.assignmentReference?.trim() ?? '';
    if (reference.isNotEmpty) {
      for (final stage in stages) {
        if (stage['assignment_uuid']?.toString() == reference ||
            stage['assignment_id']?.toString() == reference) {
          return stage;
        }
      }
    }
    return MappeurAffectationStageApi.selectionnerAffectationPrincipale(stages);
  }
}

class _ContenuStage extends StatelessWidget {
  const _ContenuStage({
    required this.stage,
    required this.completion,
    required this.documents,
    required this.documentEnCours,
    required this.onDocument,
    required this.onRefresh,
  });
  final Map<String, dynamic>? stage;
  final Map<String, dynamic>? completion;
  final List<Map<String, dynamic>> documents;
  final String? documentEnCours;
  final ValueChanged<Map<String, dynamic>> onDocument;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    final marge = MediaQuery.sizeOf(context).width < 360 ? 14.0 : 18.0;
    final rotations = _rotationsDuStage(stage);
    final hospital = _map(stage?['hospital']);
    final campaign = _map(stage?['campaign']);
    final department = _map(stage?['department']);
    final period = _map(stage?['period']);
    return RefreshIndicator(
      color: const Color(0xFFFF7417),
      onRefresh: onRefresh,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.fromLTRB(marge, 12, marge, 28),
        children: [
          if (stage == null)
            const _Vide('Aucun stage affecté.')
          else ...[
            const _TitreSection(
              titre: 'Stage actuel',
              description: 'Affectation et informations administratives',
            ),
            const SizedBox(height: 12),
            _BlocFiche(
              lignes: [
                _DonneeFiche(
                  'Statut',
                  '${stage!['assignment_status'] ?? stage!['workflow_status'] ?? ''}',
                ),
                _DonneeFiche('Établissement', '${hospital['name'] ?? ''}'),
                _DonneeFiche('Campagne', '${campaign['title'] ?? ''}'),
                _DonneeFiche('Département', '${department['name'] ?? ''}'),
                _DonneeFiche('Période', _periodeTexte(period)),
              ],
            ),
            const SizedBox(height: 12),
            _CarteClotureStage(stage: stage!, completion: completion),
            const SizedBox(height: 18),
            const _TitreSection(
              titre: 'Services et rotations',
              description: 'Parcours publié pour ce stage',
            ),
            const SizedBox(height: 12),
            if (rotations.isEmpty)
              const _Vide('Aucun parcours de rotation publié.')
            else
              for (var index = 0; index < rotations.length; index++)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _CarteServiceRotation(
                    rotation: rotations[index],
                    numero: index + 1,
                  ),
                ),
          ],
          const SizedBox(height: 22),
          const _TitreSection(
            titre: 'Documents du stage',
            description: 'Documents transmis et disponibles',
          ),
          const SizedBox(height: 12),
          if (documents.isEmpty)
            const _Vide('Aucun document disponible.')
          else
            for (final document in documents)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _CarteDocument(
                  document: document,
                  chargement: documentEnCours == document['uuid']?.toString(),
                  onOuvrir: () => onDocument(document),
                ),
              ),
        ],
      ),
    );
  }
}

class _CarteServiceRotation extends StatelessWidget {
  const _CarteServiceRotation({required this.rotation, required this.numero});

  final Map<String, dynamic> rotation;
  final int numero;

  @override
  Widget build(BuildContext context) {
    final serviceMap = _map(rotation['service']);
    final unitMap = _map(rotation['unit']);
    final supervisorMap = _map(rotation['supervisor']);
    final period = _map(rotation['period']);
    final service = [
      serviceMap['name']?.toString() ?? '',
      unitMap['name']?.toString() ?? '',
    ].where((valeur) => valeur.isNotEmpty).join(' • ');
    final encadreur = supervisorMap['name']?.toString() ?? '';
    final periode = _periodeTexte(period);
    final statut = rotation['status']?.toString() ?? '';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 14),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: .45),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            service,
            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 14),
          _LigneService(libelle: 'Encadreur', valeur: encadreur.toString()),
          const SizedBox(height: 9),
          _LigneService(libelle: 'Période', valeur: periode),
          const SizedBox(height: 14),
          Divider(
            height: 1,
            color: Theme.of(
              context,
            ).colorScheme.outlineVariant.withValues(alpha: .45),
          ),
          const SizedBox(height: 12),
          _LigneService(
            libelle: 'Rotation $numero',
            valeur: statut.toString(),
            valeurEnEvidence: true,
          ),
        ],
      ),
    );
  }
}

class _CarteClotureStage extends StatelessWidget {
  const _CarteClotureStage({required this.stage, required this.completion});

  final Map<String, dynamic> stage;
  final Map<String, dynamic>? completion;

  @override
  Widget build(BuildContext context) {
    final statutAffectation =
        stage['assignment_status']?.toString().toUpperCase() ?? '';
    final statutCloture = completion?['status']?.toString().toUpperCase() ?? '';
    final validation = _map(completion?['university_validation']);
    final statutValidation =
        validation['status']?.toString().toUpperCase() ?? '';
    final stageTermine =
        statutAffectation == 'TERMINEE' ||
        statutAffectation == 'CLOTUREE' ||
        completion != null;
    if (!stageTermine) return const SizedBox.shrink();

    final validationFinale = const {
      'VALIDE',
      'ARCHIVE',
    }.contains(statutValidation);
    final titre = validationFinale
        ? 'Stage validé par l’université'
        : statutCloture == 'VALIDE'
        ? 'Validation universitaire en attente'
        : 'Clôture du stage en cours';
    final description = validationFinale
        ? 'La clôture et le résultat de ce stage sont définitifs.'
        : statutCloture == 'VALIDE'
        ? 'Le stage est clôturé par l’établissement et attend la validation de l’université.'
        : 'Le dossier de fin de stage est en cours de préparation.';
    final couleur = validationFinale
        ? const Color(0xFF16A34A)
        : const Color(0xFFF59E0B);
    final score = statutCloture == 'VALIDE' ? (completion?['score']) : null;
    final presence = completion?['attendance_rate'];
    final blockers = (_map(completion?['readiness'])['blockers'] as List? ?? [])
        .map((item) => item.toString())
        .where((item) => item.isNotEmpty)
        .toList(growable: false);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: couleur.withValues(alpha: .08),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: couleur.withValues(alpha: .35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                validationFinale ? Icons.verified_outlined : Icons.schedule,
                color: couleur,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  titre,
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(description),
          if (presence != null || score != null) ...[
            const SizedBox(height: 10),
            Text(
              [
                if (presence != null) 'Présence : $presence %',
                if (score != null) 'Score : $score',
              ].join('  •  '),
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ],
          if (blockers.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              blockers.join('\n'),
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _LigneService extends StatelessWidget {
  const _LigneService({
    required this.libelle,
    required this.valeur,
    this.valeurEnEvidence = false,
  });

  final String libelle;
  final String valeur;
  final bool valeurEnEvidence;

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      SizedBox(
        width: 104,
        child: Text(
          libelle,
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      const SizedBox(width: 12),
      Expanded(
        child: Text(
          valeur,
          style: TextStyle(
            fontWeight: valeurEnEvidence ? FontWeight.w900 : FontWeight.w700,
          ),
        ),
      ),
    ],
  );
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
        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
      ),
      const SizedBox(height: 3),
      Text(
        description,
        style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
      ),
    ],
  );
}

class _BlocFiche extends StatelessWidget {
  const _BlocFiche({required this.lignes});
  final List<_DonneeFiche> lignes;

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 4),
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.surface,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(
        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: .45),
      ),
    ),
    child: Column(
      children: List.generate(
        lignes.length,
        (index) => Column(
          children: [
            _LigneFiche(donnee: lignes[index]),
            if (index < lignes.length - 1)
              Divider(
                height: 1,
                color: Theme.of(
                  context,
                ).colorScheme.outlineVariant.withValues(alpha: .45),
              ),
          ],
        ),
      ),
    ),
  );
}

class _LigneFiche extends StatelessWidget {
  const _LigneFiche({required this.donnee});
  final _DonneeFiche donnee;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 14),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 118,
          child: Text(
            donnee.libelle,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            donnee.valeur,
            textAlign: TextAlign.left,
            style: const TextStyle(fontWeight: FontWeight.w800, height: 1.35),
          ),
        ),
      ],
    ),
  );
}

class _DonneeFiche {
  const _DonneeFiche(this.libelle, this.valeur);
  final String libelle;
  final String valeur;
}

class _CarteDocument extends StatelessWidget {
  const _CarteDocument({
    required this.document,
    required this.chargement,
    required this.onOuvrir,
  });
  final Map<String, dynamic> document;
  final bool chargement;
  final VoidCallback onOuvrir;

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.surface,
      borderRadius: BorderRadius.circular(18),
      border: Border.all(
        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: .45),
      ),
    ),
    child: Row(
      children: [
        Container(
          constraints: const BoxConstraints(minWidth: 54),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            '${document['type_document'] ?? 'DOC'}',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w900),
          ),
        ),
        const SizedBox(width: 13),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                document['reference']?.toString() ?? 'Document',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 3),
              Text(
                '${document['status'] ?? 'Disponible'}',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 10),
        chargement
            ? const SizedBox.square(
                dimension: 22,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : TextButton(onPressed: onOuvrir, child: const Text('Ouvrir')),
      ],
    ),
  );
}

class _Vide extends StatelessWidget {
  const _Vide(this.texte);
  final String texte;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: Theme.of(context).brightness == Brightness.dark
          ? const Color(0xFF242424)
          : Theme.of(context).colorScheme.surfaceContainerLow,
      borderRadius: BorderRadius.circular(17),
    ),
    child: Text(texte, textAlign: TextAlign.center),
  );
}

List<Map<String, dynamic>> _items(Object? valeur) => valeur is List
    ? valeur.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList()
    : <Map<String, dynamic>>[];

List<Map<String, dynamic>> _rotationsDuStage(Map<String, dynamic>? stage) {
  if (stage == null) return const [];
  final planning = _map(stage['planning']);
  final parcours = stage['parcours'];
  final rotations =
      planning['rotations'] ??
      stage['rotations'] ??
      stage['rotation_items'] ??
      (parcours is Map ? parcours['rotations'] : null);
  return _items(rotations);
}

Map<String, dynamic> _map(Object? valeur) =>
    valeur is Map ? Map<String, dynamic>.from(valeur) : <String, dynamic>{};

String _periodeTexte(Map<String, dynamic> periode) {
  final debut = periode['start_date']?.toString() ?? '';
  final fin = periode['end_date']?.toString() ?? '';
  if (debut.isEmpty) return fin;
  if (fin.isEmpty) return debut;
  return '$debut au $fin';
}
