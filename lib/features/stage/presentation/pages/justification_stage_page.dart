import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:open_filex/open_filex.dart';

import '../../../../core/network/client_api_http.dart';
import '../../../../core/network/reponse_api.dart';
import '../../../../core/network/source_etudiant_distante.dart';
import '../../../../core/network/telechargeur_document_api.dart';
import '../../../../core/widgets/contenu_adaptatif.dart';
import '../../../../core/widgets/erreur_chargement_api.dart';

class JustificationStagePage extends StatefulWidget {
  const JustificationStagePage({required this.assignmentUuid, super.key});

  final String assignmentUuid;

  @override
  State<JustificationStagePage> createState() => _JustificationStagePageState();
}

class _JustificationStagePageState extends State<JustificationStagePage> {
  final _source = SourceEtudiantDistante(ClientApiHttp());
  final _telechargeur = const TelechargeurDocumentApi();
  final _explication = TextEditingController();
  late Future<Map<String, dynamic>> _chargement;
  String? _motif;
  PlatformFile? _document;
  int? _tailleDocument;
  String? _erreurFormulaire;
  bool _envoi = false;
  bool _fichierEnCours = false;
  bool _formulaireInitialise = false;

  @override
  void initState() {
    super.initState();
    _chargement = _source.justificationsStage();
  }

  @override
  void dispose() {
    _explication.dispose();
    super.dispose();
  }

  Future<void> _actualiser() async {
    final futur = _source.justificationsStage();
    setState(() => _chargement = futur);
    await futur;
  }

  Future<void> _selectionnerDocument() async {
    final fichier = await FilePicker.pickFile(
      type: FileType.custom,
      allowedExtensions: const ['pdf', 'jpg', 'jpeg', 'png'],
    );
    if (!mounted || fichier == null) return;
    final taille = await fichier.length();
    if (!mounted) return;
    if (taille > 8 * 1024 * 1024) {
      setState(
        () => _erreurFormulaire = 'Le fichier dépasse la limite de 8 Mo.',
      );
      return;
    }
    final extension = fichier.extension?.toLowerCase();
    if (!const {'pdf', 'jpg', 'jpeg', 'png'}.contains(extension)) {
      setState(
        () => _erreurFormulaire = 'Sélectionnez un document PDF, JPG ou PNG.',
      );
      return;
    }
    if (fichier.path == null || fichier.path!.trim().isEmpty) {
      setState(
        () => _erreurFormulaire = 'Le document sélectionné est inaccessible.',
      );
      return;
    }
    setState(() {
      _document = fichier;
      _tailleDocument = taille;
      _erreurFormulaire = null;
    });
  }

  Future<void> _soumettre(Map<String, dynamic> item) async {
    final type = item['allowed_type']?.toString().trim() ?? '';
    if (type.isEmpty || _motif == null) {
      setState(() => _erreurFormulaire = 'Sélectionnez un motif.');
      return;
    }
    if (_motif == 'AUTRE' && _explication.text.trim().isEmpty) {
      setState(
        () => _erreurFormulaire =
            'Expliquez la situation lorsque le motif est « Autre ».',
      );
      return;
    }
    setState(() {
      _envoi = true;
      _erreurFormulaire = null;
    });
    try {
      await _source.soumettreJustificationStage(
        assignmentUuid: widget.assignmentUuid,
        typeSituation: type,
        motif: _motif!,
        explication: _explication.text,
        cheminDocument: _document?.path,
      );
      _formulaireInitialise = false;
      _document = null;
      _tailleDocument = null;
      await _actualiser();
    } on ErreurApi catch (erreur) {
      if (mounted) setState(() => _erreurFormulaire = erreur.message);
    } finally {
      if (mounted) setState(() => _envoi = false);
    }
  }

  Future<void> _ouvrirDocument(String uuid, {required bool download}) async {
    setState(() => _fichierEnCours = true);
    try {
      final chemin = await _telechargeur.enregistrerFichier(
        contenu: await _source.fichierJustificationStage(
          uuid,
          download: download,
        ),
        nom: 'justificatif-stage-$uuid',
      );
      final resultat = await OpenFilex.open(chemin);
      if (resultat.type != ResultType.done) {
        throw ErreurApi(
          code: 'OUVERTURE_IMPOSSIBLE',
          message: resultat.message,
        );
      }
    } on ErreurApi catch (erreur) {
      if (mounted) setState(() => _erreurFormulaire = erreur.message);
    } finally {
      if (mounted) setState(() => _fichierEnCours = false);
    }
  }

  Future<void> _marquerDecisionLue(String uuid) async {
    setState(() => _envoi = true);
    try {
      await _source.marquerDecisionJustificationLue(uuid);
      await _actualiser();
    } on ErreurApi catch (erreur) {
      if (mounted) setState(() => _erreurFormulaire = erreur.message);
    } finally {
      if (mounted) setState(() => _envoi = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final sombre = Theme.of(context).brightness == Brightness.dark;
    final fond = sombre ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC);
    final texte = sombre ? Colors.white : const Color(0xFF0F172A);
    return Scaffold(
      backgroundColor: fond,
      appBar: AppBar(
        backgroundColor: fond,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          onPressed: () => Navigator.of(context).maybePop(),
          icon: Icon(Icons.arrow_back_ios_new_rounded, size: 20, color: texte),
        ),
        title: Text(
          'Justification de stage',
          style: GoogleFonts.inter(
            color: texte,
            fontSize: 20,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      body: ContenuAdaptatif(
        largeurMaximale: 680,
        enfant: FutureBuilder<Map<String, dynamic>>(
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
            final data = snapshot.data ?? const <String, dynamic>{};
            final item = _itemAffectation(data['items'], widget.assignmentUuid);
            if (item == null) {
              return const _EtatVideJustification();
            }
            final allowed = _map(data['allowed_values']);
            final motifs = (allowed['reasons'] as List? ?? const [])
                .map((value) => value.toString())
                .toList(growable: false);
            if (!_formulaireInitialise) {
              _motif = motifs.contains(item['reason']?.toString())
                  ? item['reason']?.toString()
                  : null;
              _explication.text = item['explanation']?.toString() ?? '';
              _formulaireInitialise = true;
            }
            final status = item['justification_status']
                ?.toString()
                .toUpperCase();
            final uuid = item['justification_uuid']?.toString() ?? '';
            final actions = _map(item['actions']);
            final actionSoumission = _map(actions['submit']);
            final peutSoumettre =
                item['allowed_type']?.toString().trim().isNotEmpty == true &&
                status != 'ACCEPTEE' &&
                actionSoumission['allowed'] != false;
            final peutLire =
                uuid.isNotEmpty &&
                item['decision_seen'] != true &&
                const {'ACCEPTEE', 'REJETEE'}.contains(status) &&
                _map(actions['read'])['allowed'] != false;

            return RefreshIndicator(
              color: const Color(0xFFFF751F),
              onRefresh: _actualiser,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
                children: [
                  _ResumeSituation(item: item),
                  if ((item['decision_message']?.toString() ?? '')
                      .isNotEmpty) ...[
                    const SizedBox(height: 14),
                    _CarteDecision(
                      status: status ?? '',
                      message: item['decision_message'].toString(),
                      peutMarquerLue: peutLire,
                      enCours: _envoi,
                      onLire: () => _marquerDecisionLue(uuid),
                    ),
                  ],
                  if (uuid.isNotEmpty && item['file_endpoint'] != null) ...[
                    const SizedBox(height: 14),
                    _CarteDocumentJustificatif(
                      chargement: _fichierEnCours,
                      onOuvrir: () => _ouvrirDocument(uuid, download: false),
                      onTelecharger: () =>
                          _ouvrirDocument(uuid, download: true),
                    ),
                  ],
                  if (peutSoumettre) ...[
                    const SizedBox(height: 20),
                    _FormulaireJustification(
                      item: item,
                      motifs: motifs,
                      motif: _motif,
                      explication: _explication,
                      document: _document,
                      tailleDocument: _tailleDocument,
                      envoi: _envoi,
                      erreur: _erreurFormulaire,
                      onMotif: (value) => setState(() {
                        _motif = value;
                        _erreurFormulaire = null;
                      }),
                      onDocument: _selectionnerDocument,
                      onRetirerDocument: () => setState(() {
                        _document = null;
                        _tailleDocument = null;
                      }),
                      onSoumettre: () => _soumettre(item),
                    ),
                  ] else if (_erreurFormulaire != null) ...[
                    const SizedBox(height: 14),
                    Text(
                      _erreurFormulaire!,
                      style: const TextStyle(color: Color(0xFFDC2626)),
                    ),
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

class _ResumeSituation extends StatelessWidget {
  const _ResumeSituation({required this.item});
  final Map<String, dynamic> item;
  @override
  Widget build(BuildContext context) {
    final modeSombre = Theme.of(context).brightness == Brightness.dark;
    final campagne = _map(item['campaign']);
    final hospital = _map(item['hospital']);
    final couleurCarte = modeSombre ? const Color(0xFF1E293B) : Colors.white;
    final couleurBordure = modeSombre ? const Color(0xFF334155) : const Color(0xFFE2E8F0);
    final textePrincipal = modeSombre ? Colors.white : const Color(0xFF0F172A);
    final texteSecondaire = modeSombre ? const Color(0xFF94A3B8) : const Color(0xFF64748B);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: couleurCarte,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: couleurBordure),
        boxShadow: [
          BoxShadow(
            color: modeSombre ? const Color(0x30000000) : const Color(0x05000000),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: const Color(0xFFFF751F).withValues(alpha: modeSombre ? 0.2 : 0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                alignment: Alignment.center,
                child: const Icon(
                  Icons.warning_amber_rounded,
                  color: Color(0xFFFF751F),
                  size: 24,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _libelleSituation(item['situation']?.toString() ?? ''),
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: textePrincipal,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Stage nécessitant une action',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: texteSecondaire,
                      ),
                    ),
                  ],
                ),
              ),
              if (item['justification_status'] != null)
                _BadgeJustification(item['justification_status'].toString()),
            ],
          ),
          if (campagne['title'] != null) ...[
            const SizedBox(height: 14),
            Text(
              campagne['title'].toString(),
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: textePrincipal,
              ),
            ),
          ],
          if (hospital['name'] != null) ...[
            const SizedBox(height: 3),
            Text(
              hospital['name'].toString(),
              style: GoogleFonts.inter(
                fontSize: 12.5,
                fontWeight: FontWeight.w500,
                color: texteSecondaire,
              ),
            ),
          ],
          if ((item['message']?.toString() ?? '').isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: modeSombre ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: couleurBordure),
              ),
              child: Text(
                item['message'].toString(),
                style: GoogleFonts.inter(
                  fontSize: 12.5,
                  height: 1.4,
                  color: texteSecondaire,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _CarteDecision extends StatelessWidget {
  const _CarteDecision({
    required this.status,
    required this.message,
    required this.peutMarquerLue,
    required this.enCours,
    required this.onLire,
  });
  final String status;
  final String message;
  final bool peutMarquerLue;
  final bool enCours;
  final VoidCallback onLire;
  @override
  Widget build(BuildContext context) {
    final modeSombre = Theme.of(context).brightness == Brightness.dark;
    final acceptee = status == 'ACCEPTEE';
    final couleur = acceptee
        ? const Color(0xFF16A34A)
        : const Color(0xFFDC2626);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: couleur.withValues(alpha: modeSombre ? .16 : .08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: couleur.withValues(alpha: .3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                acceptee ? Icons.check_circle_outline_rounded : Icons.cancel_outlined,
                color: couleur,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                acceptee ? 'Justification acceptée' : 'Justification rejetée',
                style: GoogleFonts.inter(color: couleur, fontWeight: FontWeight.w800, fontSize: 14.5),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            message,
            style: GoogleFonts.inter(
              fontSize: 13,
              color: modeSombre ? Colors.white70 : const Color(0xFF334155),
              height: 1.35,
            ),
          ),
          if (peutMarquerLue) ...[
            const SizedBox(height: 12),
            FilledButton.tonal(
              onPressed: enCours ? null : onLire,
              style: FilledButton.styleFrom(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('J’ai pris connaissance'),
            ),
          ],
        ],
      ),
    );
  }
}

class _CarteDocumentJustificatif extends StatelessWidget {
  const _CarteDocumentJustificatif({
    required this.chargement,
    required this.onOuvrir,
    required this.onTelecharger,
  });
  final bool chargement;
  final VoidCallback onOuvrir;
  final VoidCallback onTelecharger;
  @override
  Widget build(BuildContext context) {
    final modeSombre = Theme.of(context).brightness == Brightness.dark;
    final couleurCarte = modeSombre ? const Color(0xFF1E293B) : Colors.white;
    final couleurBordure = modeSombre ? const Color(0xFF334155) : const Color(0xFFE2E8F0);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: couleurCarte,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: couleurBordure),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFF1D61F2).withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            alignment: Alignment.center,
            child: const Icon(Icons.attach_file_rounded, color: Color(0xFF1D61F2), size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Document justificatif',
              style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 14),
            ),
          ),
          IconButton(
            tooltip: 'Ouvrir',
            onPressed: chargement ? null : onOuvrir,
            icon: const Icon(Icons.visibility_outlined, size: 20),
          ),
          IconButton(
            tooltip: 'Télécharger',
            onPressed: chargement ? null : onTelecharger,
            icon: const Icon(Icons.download_outlined, size: 20),
          ),
        ],
      ),
    );
  }
}

class _FormulaireJustification extends StatelessWidget {
  const _FormulaireJustification({
    required this.item,
    required this.motifs,
    required this.motif,
    required this.explication,
    required this.document,
    required this.tailleDocument,
    required this.envoi,
    required this.erreur,
    required this.onMotif,
    required this.onDocument,
    required this.onRetirerDocument,
    required this.onSoumettre,
  });
  final Map<String, dynamic> item;
  final List<String> motifs;
  final String? motif;
  final TextEditingController explication;
  final PlatformFile? document;
  final int? tailleDocument;
  final bool envoi;
  final String? erreur;
  final ValueChanged<String?> onMotif;
  final VoidCallback onDocument;
  final VoidCallback onRetirerDocument;
  final VoidCallback onSoumettre;

  @override
  Widget build(BuildContext context) {
    final sombre = Theme.of(context).brightness == Brightness.dark;
    final champ = sombre ? const Color(0xFF1E293B) : Colors.white;
    final bordure = sombre ? const Color(0xFF334155) : const Color(0xFFE2E8F0);
    final decoration = InputDecoration(
      filled: true,
      fillColor: champ,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: bordure)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: bordure),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Color(0xFF1D61F2), width: 1.5),
      ),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          item['justification_uuid'] == null
              ? 'Fournir une justification'
              : 'Renvoyer la justification',
          style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 16),
        const _LibelleFormulaire('Type de situation'),
        const SizedBox(height: 8),
        TextFormField(
          initialValue: _libelleSituation(
            item['allowed_type']?.toString() ?? '',
          ),
          readOnly: true,
          decoration: decoration,
          style: GoogleFonts.inter(fontSize: 14),
        ),
        const SizedBox(height: 16),
        const _LibelleFormulaire('Motif'),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          initialValue: motif,
          decoration: decoration,
          items: motifs
              .map(
                (value) => DropdownMenuItem(
                  value: value,
                  child: Text(_libelleMotif(value), style: GoogleFonts.inter(fontSize: 14)),
                ),
              )
              .toList(growable: false),
          onChanged: envoi ? null : onMotif,
        ),
        if (motif == 'AUTRE') ...[
          const SizedBox(height: 16),
          const _LibelleFormulaire('Explication'),
          const SizedBox(height: 8),
          TextField(
            controller: explication,
            enabled: !envoi,
            minLines: 3,
            maxLines: 5,
            decoration: decoration,
            style: GoogleFonts.inter(fontSize: 14),
          ),
        ],
        const SizedBox(height: 16),
        const _LibelleFormulaire('Document justificatif (facultatif)'),
        const SizedBox(height: 8),
        ListTile(
          tileColor: champ,
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: bordure),
          ),
          leading: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFF1D61F2).withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            alignment: Alignment.center,
            child: const Icon(Icons.folder_open_outlined, color: Color(0xFF1D61F2), size: 22),
          ),
          title: Text(
            document?.name ?? 'Choisir dans le stockage',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.inter(fontSize: 13.5, fontWeight: FontWeight.w600),
          ),
          subtitle: Text(
            document == null
                ? 'PDF, JPG ou PNG · 8 Mo maximum'
                : _taille(tailleDocument ?? 0),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.inter(fontSize: 12, color: sombre ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
          ),
          trailing: document == null
              ? const Icon(Icons.chevron_right_rounded)
              : IconButton(
                  onPressed: envoi ? null : onRetirerDocument,
                  icon: const Icon(Icons.close_rounded),
                ),
          onTap: envoi ? null : onDocument,
        ),
        if (erreur != null) ...[
          const SizedBox(height: 12),
          Text(
            erreur!,
            style: GoogleFonts.inter(
              color: const Color(0xFFDC2626),
              fontWeight: FontWeight.w700,
              fontSize: 13,
            ),
          ),
        ],
        const SizedBox(height: 22),
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: envoi ? null : onSoumettre,
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(50),
              backgroundColor: const Color(0xFF1D61F2),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            icon: envoi
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : const Icon(Icons.send_rounded, size: 18),
            label: Text(
              envoi ? 'Envoi en cours…' : 'Envoyer la justification',
              style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 15),
            ),
          ),
        ),
      ],
    );
  }
}

class _BadgeJustification extends StatelessWidget {
  const _BadgeJustification(this.status);
  final String status;
  @override
  Widget build(BuildContext context) {
    final couleur = switch (status.toUpperCase()) {
      'ACCEPTEE' => const Color(0xFF16A34A),
      'REJETEE' => const Color(0xFFDC2626),
      _ => const Color(0xFFF59E0B),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: couleur.withValues(alpha: .1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        _libelleStatut(status),
        style: TextStyle(
          color: couleur,
          fontSize: 11,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _LibelleFormulaire extends StatelessWidget {
  const _LibelleFormulaire(this.texte);
  final String texte;
  @override
  Widget build(BuildContext context) => Text(
    texte,
    style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w800),
  );
}

class _EtatVideJustification extends StatelessWidget {
  const _EtatVideJustification();
  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Text(
        'Aucune demande de justification pour ce stage.',
        textAlign: TextAlign.center,
        style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
      ),
    ),
  );
}

Map<String, dynamic>? _itemAffectation(Object? valeur, String uuid) {
  if (valeur is! List) return null;
  for (final brut in valeur.whereType<Map>()) {
    if (brut['assignment_uuid']?.toString() == uuid) {
      return Map<String, dynamic>.from(brut);
    }
  }
  return null;
}

Map<String, dynamic> _map(Object? valeur) =>
    valeur is Map ? Map<String, dynamic>.from(valeur) : <String, dynamic>{};

String _libelleSituation(String valeur) => switch (valeur.toUpperCase()) {
  'NON_DEMARRAGE' => 'Non-démarrage du stage',
  'INTERRUPTION' => 'Interruption du stage',
  _ => valeur,
};

String _libelleMotif(String valeur) => switch (valeur.toUpperCase()) {
  'MALADIE' => 'Maladie',
  'ACCIDENT' => 'Accident',
  'CONTRAINTE_FAMILIALE' => 'Contrainte familiale',
  'AUTRE' => 'Autre',
  _ => valeur,
};

String _libelleStatut(String valeur) => switch (valeur.toUpperCase()) {
  'EN_ATTENTE' => 'En attente',
  'ACCEPTEE' => 'Acceptée',
  'REJETEE' => 'Rejetée',
  _ => valeur,
};

String _taille(int octets) => octets >= 1024 * 1024
    ? '${(octets / (1024 * 1024)).toStringAsFixed(1)} Mo'
    : '${(octets / 1024).ceil()} Ko';
