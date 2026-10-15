import 'package:alert_info/alert_info.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:open_filex/open_filex.dart';

import '../../../../core/network/client_api_http.dart';
import '../../../../core/network/reponse_api.dart';
import '../../../../core/network/source_etudiant_distante.dart';
import '../../../../core/network/telechargeur_document_api.dart';
import '../../../../core/widgets/erreur_chargement_api.dart';

class SectionRapport extends StatefulWidget {
  const SectionRapport({super.key});

  @override
  State<SectionRapport> createState() => _SectionRapportState();
}

class _SectionRapportState extends State<SectionRapport> {
  final _source = SourceEtudiantDistante(ClientApiHttp());
  final _telechargeur = const TelechargeurDocumentApi();
  late Future<List<Map<String, dynamic>>> _chargement;
  String _filtre = 'TOUS';
  String? _fichierEnCours;

  static const _statuts = [
    'TOUS',
    'SOUMIS',
    'RECU',
    'ACCEPTE',
    'A_CORRIGER',
    'REJETE',
    'ARCHIVE',
  ];

  @override
  void initState() {
    super.initState();
    _chargement = _charger();
  }

  Future<List<Map<String, dynamic>>> _charger() =>
      Future.wait([_source.rapportsStage(perPage: 100), _source.stages()]);

  Future<void> _actualiser() async {
    final futur = _charger();
    setState(() => _chargement = futur);
    await futur;
  }

  Future<void> _ouvrirDepot(
    List<Map<String, dynamic>> stages, {
    String? assignmentUuid,
  }) async {
    final soumis = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      enableDrag: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _DepotRapportSheet(
        source: _source,
        stages: stages,
        assignmentUuidInitial: assignmentUuid,
      ),
    );
    if (soumis == true && mounted) await _actualiser();
  }

  Future<void> _ouvrirDetail(String uuid) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      enableDrag: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _DetailRapportSheet(
        chargement: _source.detailRapportStage(uuid),
        fichierEnCours: () => _fichierEnCours,
        onFichier: (download) => _ouvrirFichier(uuid, download: download),
        onNouvelleVersion: (assignmentUuid) async {
          Navigator.of(context).pop();
          final reponses = await _chargement;
          if (!mounted) return;
          await _ouvrirDepot(
            _items(reponses[1]['items']),
            assignmentUuid: assignmentUuid,
          );
        },
      ),
    );
  }

  Future<void> _ouvrirFichier(String uuid, {required bool download}) async {
    setState(() => _fichierEnCours = uuid);
    try {
      final chemin = await _telechargeur.enregistrerFichier(
        contenu: await _source.fichierRapportStage(uuid, download: download),
        nom: 'rapport-stage-$uuid',
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
      if (mounted) setState(() => _fichierEnCours = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final sombre = Theme.of(context).brightness == Brightness.dark;
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _chargement,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: Color(0xFFFF751F)),
          );
        }
        if (snapshot.hasError) {
          return ErreurChargementApi(
            erreur: snapshot.error,
            onReessayer: _actualiser,
          );
        }

        final rapportsData = snapshot.data![0];
        final stages = _items(snapshot.data![1]['items']);
        final rapports = _items(rapportsData['items']);
        final stats = _map(rapportsData['stats']);
        final filtres = _statuts
            .where((statut) {
              if (statut == 'TOUS') return true;
              final disponibles = _map(
                rapportsData['available_filters'],
              )['statuses'];
              return disponibles is! List || disponibles.contains(statut);
            })
            .toList(growable: false);
        final rapportsFiltres = rapports
            .where((rapport) {
              return _filtre == 'TOUS' ||
                  rapport['status']?.toString().toUpperCase() == _filtre;
            })
            .toList(growable: false);
        final groupes = _grouperParAffectation(rapportsFiltres);

        return RefreshIndicator(
          color: const Color(0xFFFF751F),
          onRefresh: _actualiser,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics(),
            ),
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
            children: [
              _CarteSyntheseRapports(
                total: stats['total'] ?? rapports.length,
                assignments:
                    stats['assignments'] ??
                    _grouperParAffectation(rapports).length,
                onDeposer: stages.isEmpty ? null : () => _ouvrirDepot(stages),
              ),
              const SizedBox(height: 16),
              const _ConsignesRapport(),
              const SizedBox(height: 18),
              SizedBox(
                height: 40,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: filtres.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 8),
                  itemBuilder: (context, index) {
                    final statut = filtres[index];
                    return _FiltreRapport(
                      texte: _libelleStatut(statut),
                      actif: _filtre == statut,
                      sombre: sombre,
                      onTap: () => setState(() => _filtre = statut),
                    );
                  },
                ),
              ),
              const SizedBox(height: 18),
              if (rapports.isEmpty)
                _EtatVideRapports(
                  texte: 'Aucun rapport de stage déposé.',
                  onDeposer: stages.isEmpty ? null : () => _ouvrirDepot(stages),
                )
              else if (groupes.isEmpty)
                const _EtatVideRapports(
                  texte: 'Aucun rapport ne correspond à ce filtre.',
                )
              else
                for (final groupe in groupes.entries) ...[
                  _CarteGroupeRapports(
                    rapports: groupe.value,
                    onDetail: _ouvrirDetail,
                    onNouvelleVersion: stages.isEmpty
                        ? null
                        : () =>
                              _ouvrirDepot(stages, assignmentUuid: groupe.key),
                  ),
                  const SizedBox(height: 12),
                ],
            ],
          ),
        );
      },
    );
  }
}

class _CarteSyntheseRapports extends StatelessWidget {
  const _CarteSyntheseRapports({
    required this.total,
    required this.assignments,
    required this.onDeposer,
  });
  final Object total;
  final Object assignments;
  final VoidCallback? onDeposer;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      gradient: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF172554), Color(0xFF1D4ED8)],
      ),
      borderRadius: BorderRadius.circular(22),
      boxShadow: [
        BoxShadow(
          color: const Color(0xFF1D4ED8).withValues(alpha: .22),
          blurRadius: 16,
          offset: const Offset(0, 8),
        ),
      ],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Dossier de rapports',
          style: GoogleFonts.inter(
            color: Colors.white,
            fontSize: 19,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 5),
        Text(
          '$total version(s) · $assignments stage(s)',
          style: GoogleFonts.inter(color: Colors.white70),
        ),
        const SizedBox(height: 18),
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: onDeposer,
            style: FilledButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: const Color(0xFF172554),
            ),
            icon: const Icon(Icons.upload_file_rounded),
            label: const Text('Déposer un rapport'),
          ),
        ),
      ],
    ),
  );
}

class _ConsignesRapport extends StatelessWidget {
  const _ConsignesRapport();

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.surface,
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
    ),
    child: const Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CircleAvatar(
          radius: 21,
          backgroundColor: Color(0xFFFFE8D8),
          child: Icon(Icons.description_outlined, color: Color(0xFFFF751F)),
        ),
        SizedBox(width: 13),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Formats acceptés',
                style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15),
              ),
              SizedBox(height: 5),
              Text(
                'PDF, DOC ou DOCX · 15 Mo maximum par version.',
                style: TextStyle(height: 1.4),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class _FiltreRapport extends StatelessWidget {
  const _FiltreRapport({
    required this.texte,
    required this.actif,
    required this.sombre,
    required this.onTap,
  });
  final String texte;
  final bool actif;
  final bool sombre;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(12),
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
      decoration: BoxDecoration(
        color: actif
            ? const Color(0xFFFF751F)
            : sombre
            ? const Color(0xFF1E293B)
            : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: actif
              ? Colors.transparent
              : sombre
              ? const Color(0xFF334155)
              : const Color(0xFFE2E8F0),
        ),
      ),
      child: Text(
        texte,
        style: GoogleFonts.inter(
          color: actif
              ? Colors.white
              : Theme.of(context).colorScheme.onSurfaceVariant,
          fontSize: 13,
          fontWeight: FontWeight.w700,
        ),
      ),
    ),
  );
}

class _CarteGroupeRapports extends StatelessWidget {
  const _CarteGroupeRapports({
    required this.rapports,
    required this.onDetail,
    required this.onNouvelleVersion,
  });
  final List<Map<String, dynamic>> rapports;
  final ValueChanged<String> onDetail;
  final VoidCallback? onNouvelleVersion;

  @override
  Widget build(BuildContext context) {
    final ordonnes = [...rapports]
      ..sort(
        (a, b) => ((b['version'] as num?)?.toInt() ?? 0).compareTo(
          (a['version'] as num?)?.toInt() ?? 0,
        ),
      );
    final dernier = ordonnes.first;
    final campagne = _map(dernier['campaign']);
    final hopital = _map(dernier['hospital']);
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.fromLTRB(16, 10, 12, 10),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        shape: const Border(),
        collapsedShape: const Border(),
        leading: const CircleAvatar(
          backgroundColor: Color(0xFFEFF6FF),
          child: Icon(Icons.article_outlined, color: Color(0xFF1D4ED8)),
        ),
        title: Text(
          campagne['title']?.toString() ?? 'Stage',
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: GoogleFonts.inter(fontWeight: FontWeight.w900),
        ),
        subtitle: Text(
          [
            if (hopital['name'] != null) hopital['name'].toString(),
            'Version ${dernier['version'] ?? '-'}',
          ].join(' · '),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: _BadgeStatut(dernier['status']?.toString() ?? ''),
        children: [
          if ((dernier['university_comment']?.toString() ?? '').isNotEmpty)
            _CommentaireUniversite(
              commentaire: dernier['university_comment'].toString(),
            ),
          for (final rapport in ordonnes) ...[
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(
                rapport['title']?.toString() ?? 'Rapport de stage',
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
              subtitle: Text(
                'Version ${rapport['version'] ?? '-'} · ${_date(rapport['submitted_at'])}',
              ),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: () => onDetail(rapport['uuid'].toString()),
            ),
            if (rapport != ordonnes.last) const Divider(height: 1),
          ],
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: onNouvelleVersion,
              icon: const Icon(Icons.upload_file_outlined),
              label: const Text('Déposer une nouvelle version'),
            ),
          ),
        ],
      ),
    );
  }
}

class _CommentaireUniversite extends StatelessWidget {
  const _CommentaireUniversite({required this.commentaire});
  final String commentaire;
  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    margin: const EdgeInsets.only(bottom: 8),
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: const Color(0xFFFF751F).withValues(alpha: .08),
      borderRadius: BorderRadius.circular(14),
    ),
    child: Text(commentaire),
  );
}

class _BadgeStatut extends StatelessWidget {
  const _BadgeStatut(this.statut);
  final String statut;
  @override
  Widget build(BuildContext context) {
    final couleur = _couleurStatut(statut);
    return Container(
      constraints: const BoxConstraints(maxWidth: 95),
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: couleur.withValues(alpha: .1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        _libelleStatut(statut),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: couleur,
          fontWeight: FontWeight.w800,
          fontSize: 11,
        ),
      ),
    );
  }
}

class _EtatVideRapports extends StatelessWidget {
  const _EtatVideRapports({required this.texte, this.onDeposer});
  final String texte;
  final VoidCallback? onDeposer;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(28),
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.surface,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
    ),
    child: Column(
      children: [
        const Icon(Icons.article_outlined, size: 44, color: Color(0xFF94A3B8)),
        const SizedBox(height: 12),
        Text(texte, textAlign: TextAlign.center),
        if (onDeposer != null) ...[
          const SizedBox(height: 14),
          FilledButton.icon(
            onPressed: onDeposer,
            icon: const Icon(Icons.upload_file_outlined),
            label: const Text('Déposer un rapport'),
          ),
        ],
      ],
    ),
  );
}

class _DepotRapportSheet extends StatefulWidget {
  const _DepotRapportSheet({
    required this.source,
    required this.stages,
    this.assignmentUuidInitial,
  });
  final SourceEtudiantDistante source;
  final List<Map<String, dynamic>> stages;
  final String? assignmentUuidInitial;

  @override
  State<_DepotRapportSheet> createState() => _DepotRapportSheetState();
}

class _DepotRapportSheetState extends State<_DepotRapportSheet> {
  final _titre = TextEditingController();
  final _description = TextEditingController();
  PlatformFile? _fichier;
  int? _taille;
  String? _assignmentUuid;
  String? _erreur;
  bool _soumission = false;

  @override
  void initState() {
    super.initState();
    final references = widget.stages
        .map((stage) => stage['assignment_uuid']?.toString())
        .whereType<String>()
        .toSet();
    _assignmentUuid = references.contains(widget.assignmentUuidInitial)
        ? widget.assignmentUuidInitial
        : references.length == 1
        ? references.first
        : null;
  }

  @override
  void dispose() {
    _titre.dispose();
    _description.dispose();
    super.dispose();
  }

  Future<void> _selectionnerFichier() async {
    final fichier = await FilePicker.pickFile(
      type: FileType.custom,
      allowedExtensions: const ['pdf', 'doc', 'docx'],
    );
    if (!mounted || fichier == null) return;
    final taille = await fichier.length();
    if (!mounted) return;
    if (taille > 15 * 1024 * 1024) {
      setState(() => _erreur = 'Le fichier dépasse la limite de 15 Mo.');
      return;
    }
    final extension = fichier.extension?.toLowerCase();
    if (!const {'pdf', 'doc', 'docx'}.contains(extension)) {
      setState(() => _erreur = 'Sélectionnez un fichier PDF, DOC ou DOCX.');
      return;
    }
    if (fichier.path == null || fichier.path!.trim().isEmpty) {
      setState(() => _erreur = 'Le fichier sélectionné est inaccessible.');
      return;
    }
    setState(() {
      _fichier = fichier;
      _taille = taille;
      _erreur = null;
    });
  }

  Future<void> _soumettre() async {
    if (_assignmentUuid == null || _fichier?.path == null) {
      setState(
        () => _erreur = 'Sélectionnez le stage et le rapport à envoyer.',
      );
      return;
    }
    setState(() {
      _soumission = true;
      _erreur = null;
    });
    try {
      await widget.source.soumettreRapportStage(
        assignmentUuid: _assignmentUuid!,
        cheminFichier: _fichier!.path!,
        title: _titre.text,
        description: _description.text,
      );
      if (mounted) Navigator.of(context).pop(true);
    } on ErreurApi catch (erreur) {
      if (mounted) setState(() => _erreur = erreur.message);
    } finally {
      if (mounted) setState(() => _soumission = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final sombre = Theme.of(context).brightness == Brightness.dark;
    final fond = sombre ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC);
    final champs = sombre ? const Color(0xFF1E293B) : Colors.white;
    final decoration = InputDecoration(
      filled: true,
      fillColor: champs,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(
          color: Theme.of(context).colorScheme.outlineVariant,
        ),
      ),
    );
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: .82,
      minChildSize: .48,
      maxChildSize: .96,
      builder: (context, scrollController) => Material(
        color: fond,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(26)),
        clipBehavior: Clip.antiAlias,
        child: ListView(
          controller: scrollController,
          padding: EdgeInsets.fromLTRB(
            20,
            10,
            20,
            MediaQuery.viewInsetsOf(context).bottom + 24,
          ),
          children: [
            Center(
              child: Container(
                width: 44,
                height: 5,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.outlineVariant,
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
            ),
            const SizedBox(height: 18),
            Text(
              'Déposer un rapport',
              style: GoogleFonts.inter(
                fontSize: 21,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 20),
            const _LibelleChamp('Stage concerné'),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              initialValue: _assignmentUuid,
              isExpanded: true,
              decoration: decoration,
              items: widget.stages
                  .map((stage) {
                    final campagne = _map(stage['campaign']);
                    final hopital = _map(stage['hospital']);
                    return DropdownMenuItem(
                      value: stage['assignment_uuid']?.toString(),
                      child: Text(
                        [
                          campagne['title']?.toString() ?? 'Stage',
                          if (hopital['name'] != null)
                            hopital['name'].toString(),
                        ].join(' · '),
                        overflow: TextOverflow.ellipsis,
                      ),
                    );
                  })
                  .toList(growable: false),
              onChanged: _soumission
                  ? null
                  : (valeur) => setState(() => _assignmentUuid = valeur),
            ),
            const SizedBox(height: 18),
            const _LibelleChamp('Fichier du rapport'),
            const SizedBox(height: 8),
            InkWell(
              onTap: _soumission ? null : _selectionnerFichier,
              borderRadius: BorderRadius.circular(16),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: champs,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Theme.of(context).colorScheme.outlineVariant,
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.folder_open_outlined,
                      color: Color(0xFFFF751F),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _fichier?.name ?? 'Choisir dans le stockage',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontWeight: FontWeight.w800),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            _fichier == null
                                ? 'PDF, DOC ou DOCX · 15 Mo maximum'
                                : _tailleFichier(_taille ?? 0),
                            style: TextStyle(
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurfaceVariant,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right_rounded),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 18),
            const _LibelleChamp('Titre (facultatif)'),
            const SizedBox(height: 8),
            TextField(
              controller: _titre,
              enabled: !_soumission,
              decoration: decoration,
            ),
            const SizedBox(height: 18),
            const _LibelleChamp('Description (facultative)'),
            const SizedBox(height: 8),
            TextField(
              controller: _description,
              enabled: !_soumission,
              minLines: 3,
              maxLines: 5,
              decoration: decoration,
            ),
            if (_erreur != null) ...[
              const SizedBox(height: 14),
              Text(
                _erreur!,
                style: const TextStyle(
                  color: Color(0xFFDC2626),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
            const SizedBox(height: 22),
            FilledButton.icon(
              onPressed: _soumission ? null : _soumettre,
              icon: _soumission
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.cloud_upload_outlined),
              label: Text(_soumission ? 'Envoi en cours…' : 'Valider le dépôt'),
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(52),
                backgroundColor: const Color(0xFFFF751F),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DetailRapportSheet extends StatelessWidget {
  const _DetailRapportSheet({
    required this.chargement,
    required this.fichierEnCours,
    required this.onFichier,
    required this.onNouvelleVersion,
  });
  final Future<Map<String, dynamic>> chargement;
  final String? Function() fichierEnCours;
  final ValueChanged<bool> onFichier;
  final ValueChanged<String> onNouvelleVersion;

  @override
  Widget build(BuildContext context) {
    final sombre = Theme.of(context).brightness == Brightness.dark;
    final fond = sombre ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC);
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: .72,
      minChildSize: .42,
      maxChildSize: .96,
      builder: (context, scrollController) => Material(
        color: fond,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(26)),
        clipBehavior: Clip.antiAlias,
        child: FutureBuilder<Map<String, dynamic>>(
          future: chargement,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return ErreurChargementApi(
                erreur: snapshot.error,
                onReessayer: () => Navigator.of(context).pop(),
              );
            }
            final rapport = _map(snapshot.data?['report']);
            final assignment = _map(rapport['assignment']);
            final campagne = _map(rapport['campaign']);
            final hopital = _map(rapport['hospital']);
            final universite = _map(rapport['university']);
            final reviewer = _map(rapport['reviewer']);
            final file = _map(rapport['file']);
            return ListView(
              controller: scrollController,
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 28),
              children: [
                Center(
                  child: Container(
                    width: 44,
                    height: 5,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.outlineVariant,
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        rapport['title']?.toString() ?? 'Rapport de stage',
                        style: GoogleFonts.inter(
                          fontSize: 21,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    _BadgeStatut(rapport['status']?.toString() ?? ''),
                  ],
                ),
                const SizedBox(height: 18),
                _BlocDetail(
                  lignes: {
                    'Version': '${rapport['version'] ?? '-'}',
                    'Campagne': campagne['title']?.toString() ?? '—',
                    'Hôpital': hopital['name']?.toString() ?? '—',
                    'Université': universite['name']?.toString() ?? '—',
                    'Soumis le': _date(rapport['submitted_at']),
                    if (rapport['received_at'] != null)
                      'Reçu le': _date(rapport['received_at']),
                    if (rapport['reviewed_at'] != null)
                      'Évalué le': _date(rapport['reviewed_at']),
                    if (reviewer['name'] != null)
                      'Responsable': reviewer['name'].toString(),
                    if (file['original_name'] != null)
                      'Fichier': file['original_name'].toString(),
                  },
                ),
                if ((rapport['description']?.toString() ?? '').isNotEmpty) ...[
                  const SizedBox(height: 14),
                  _BlocTexte(
                    titre: 'Description',
                    texte: rapport['description'].toString(),
                  ),
                ],
                if ((rapport['university_comment']?.toString() ?? '')
                    .isNotEmpty) ...[
                  const SizedBox(height: 14),
                  _BlocTexte(
                    titre: 'Commentaire de l’université',
                    texte: rapport['university_comment'].toString(),
                    accent: const Color(0xFFFF751F),
                  ),
                ],
                const SizedBox(height: 18),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: fichierEnCours() == rapport['uuid']
                            ? null
                            : () => onFichier(false),
                        icon: const Icon(Icons.visibility_outlined),
                        label: const Text('Ouvrir'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: fichierEnCours() == rapport['uuid']
                            ? null
                            : () => onFichier(true),
                        icon: const Icon(Icons.download_outlined),
                        label: const Text('Télécharger'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                FilledButton.icon(
                  onPressed: assignment['uuid'] == null
                      ? null
                      : () => onNouvelleVersion(assignment['uuid'].toString()),
                  icon: const Icon(Icons.upload_file_outlined),
                  label: const Text('Déposer une nouvelle version'),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _BlocDetail extends StatelessWidget {
  const _BlocDetail({required this.lignes});
  final Map<String, String> lignes;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.surface,
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
    ),
    child: Column(
      children: lignes.entries
          .map(
            (ligne) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 92,
                    child: Text(
                      ligne.key,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      ligne.value,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                ],
              ),
            ),
          )
          .toList(growable: false),
    ),
  );
}

class _BlocTexte extends StatelessWidget {
  const _BlocTexte({required this.titre, required this.texte, this.accent});
  final String titre;
  final String texte;
  final Color? accent;
  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: (accent ?? Theme.of(context).colorScheme.primary).withValues(
        alpha: .07,
      ),
      borderRadius: BorderRadius.circular(18),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(titre, style: const TextStyle(fontWeight: FontWeight.w900)),
        const SizedBox(height: 7),
        Text(texte),
      ],
    ),
  );
}

class _LibelleChamp extends StatelessWidget {
  const _LibelleChamp(this.texte);
  final String texte;
  @override
  Widget build(BuildContext context) => Text(
    texte,
    style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w800),
  );
}

Map<String, List<Map<String, dynamic>>> _grouperParAffectation(
  List<Map<String, dynamic>> rapports,
) {
  final groupes = <String, List<Map<String, dynamic>>>{};
  for (final rapport in rapports) {
    final uuid = _map(rapport['assignment'])['uuid']?.toString();
    if (uuid == null || uuid.isEmpty) continue;
    groupes.putIfAbsent(uuid, () => []).add(rapport);
  }
  return groupes;
}

List<Map<String, dynamic>> _items(Object? valeur) => valeur is List
    ? valeur.whereType<Map>().map(Map<String, dynamic>.from).toList()
    : <Map<String, dynamic>>[];

Map<String, dynamic> _map(Object? valeur) =>
    valeur is Map ? Map<String, dynamic>.from(valeur) : <String, dynamic>{};

String _libelleStatut(String statut) => switch (statut.toUpperCase()) {
  'TOUS' => 'Tous',
  'SOUMIS' => 'Soumis',
  'RECU' => 'Reçu',
  'ACCEPTE' => 'Accepté',
  'A_CORRIGER' => 'À corriger',
  'REJETE' => 'Rejeté',
  'ARCHIVE' => 'Archivé',
  _ => statut,
};

Color _couleurStatut(String statut) => switch (statut.toUpperCase()) {
  'ACCEPTE' => const Color(0xFF16A34A),
  'A_CORRIGER' => const Color(0xFFF59E0B),
  'REJETE' => const Color(0xFFDC2626),
  'ARCHIVE' => const Color(0xFF64748B),
  _ => const Color(0xFF1D61F2),
};

String _date(Object? valeur) {
  final texte = valeur?.toString() ?? '';
  final date = DateTime.tryParse(texte);
  if (date == null) return texte.isEmpty ? '—' : texte;
  const mois = [
    'janv.',
    'févr.',
    'mars',
    'avr.',
    'mai',
    'juin',
    'juil.',
    'août',
    'sept.',
    'oct.',
    'nov.',
    'déc.',
  ];
  return '${date.day} ${mois[date.month - 1]} ${date.year}';
}

String _tailleFichier(int octets) {
  if (octets >= 1024 * 1024) {
    return '${(octets / (1024 * 1024)).toStringAsFixed(1)} Mo';
  }
  return '${(octets / 1024).ceil()} Ko';
}
