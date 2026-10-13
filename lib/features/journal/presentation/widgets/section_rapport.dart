import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:open_filex/open_filex.dart';

class SectionRapport extends StatefulWidget {
  const SectionRapport({super.key});
  @override
  State<SectionRapport> createState() => _SectionRapportState();
}

class _SectionRapportState extends State<SectionRapport> {
  PlatformFile? _rapport;
  String _statut = 'Non déposé';
  int _version = 0;

  Future<void> _selectionnerRapport() async {
    final fichiers = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['pdf', 'doc', 'docx'],
    );
    if (!mounted || fichiers.isEmpty) return;
    setState(() {
      _rapport = fichiers.first;
      _statut = 'Brouillon';
      _version++;
    });
  }

  void _soumettre() {
    if (_rapport == null) return;
    setState(() => _statut = 'En vérification');
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Le rapport a été soumis pour vérification.'),
      ),
    );
  }

  Future<void> _ouvrir() async {
    final chemin = _rapport?.path;
    if (chemin != null) await OpenFilex.open(chemin);
  }

  @override
  Widget build(BuildContext context) {
    final marge = MediaQuery.sizeOf(context).width < 360 ? 14.0 : 18.0;
    final modeSombre = Theme.of(context).brightness == Brightness.dark;
    final fondCarte = modeSombre ? const Color(0xFF111C2E) : Colors.white;
    final bordure = modeSombre
        ? const Color(0xFF334155)
        : const Color(0xFFE2E8F0);
    final textePrincipal = modeSombre ? Colors.white : const Color(0xFF0F172A);
    final texteSecondaire = modeSombre
        ? const Color(0xFF94A3B8)
        : const Color(0xFF64748B);
    return ListView(
      padding: EdgeInsets.fromLTRB(marge, 16, marge, 28),
      children: [
        const SizedBox(height: 14),
        const _BlocConsignes(),
        const SizedBox(height: 16),
        _EtatRapport(statut: _statut, version: _version),
        const SizedBox(height: 16),
        if (_rapport != null)
          Card(
            color: fondCarte,
            surfaceTintColor: Colors.transparent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: bordure),
            ),
            child: ListTile(
              leading: const Icon(Icons.description, color: Color(0xFFFF7417)),
              title: Text(
                _rapport!.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: textePrincipal),
              ),
              subtitle: Text(
                'Version $_version · ${_rapport!.extension?.toUpperCase() ?? 'DOCUMENT'}',
                style: TextStyle(color: texteSecondaire),
              ),
              trailing: IconButton(
                onPressed: _ouvrir,
                icon: const Icon(Icons.open_in_new),
              ),
            ),
          ),
        if (_statut == 'À corriger') ...[
          const SizedBox(height: 12),
          Card(
            color: modeSombre
                ? const Color(0xFF3B2416)
                : const Color(0xFFFFF3E0),
            surfaceTintColor: Colors.transparent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
              side: BorderSide(
                color: modeSombre
                    ? const Color(0xFF7C3A12)
                    : const Color(0xFFFFD7B5),
              ),
            ),
            child: ListTile(
              leading: const Icon(
                Icons.rate_review_outlined,
                color: Color(0xFFE85D00),
              ),
              title: Text(
                'Corrections demandées',
                style: TextStyle(color: textePrincipal),
              ),
              subtitle: Text(
                'Revoir la présentation des résultats et compléter la conclusion.',
                style: TextStyle(color: texteSecondaire),
              ),
            ),
          ),
        ],
        const SizedBox(height: 18),
        OutlinedButton.icon(
          onPressed: _selectionnerRapport,
          icon: const Icon(Icons.upload_file),
          label: Text(
            _rapport == null
                ? 'Importer le rapport'
                : 'Déposer une nouvelle version',
          ),
          style: OutlinedButton.styleFrom(
            foregroundColor: modeSombre
                ? const Color(0xFF93C5FD)
                : const Color(0xFF1D61F2),
            side: BorderSide(color: bordure),
          ),
        ),
        const SizedBox(height: 10),
        FilledButton.icon(
          onPressed: _rapport != null && _statut == 'Brouillon'
              ? _soumettre
              : null,
          label: const Text('Soumettre le rapport'),
        ),
        if (_statut == 'Validé') ...[
          const SizedBox(height: 10),
          TextButton.icon(
            onPressed: _ouvrir,
            icon: const Icon(Icons.download),
            label: const Text('Télécharger la version validée'),
          ),
        ],
      ],
    );
  }
}

class _BlocConsignes extends StatelessWidget {
  const _BlocConsignes();
  @override
  Widget build(BuildContext context) {
    final modeSombre = Theme.of(context).brightness == Brightness.dark;
    final couleurTexte = modeSombre ? Colors.white : const Color(0xFF0F172A);
    final fond = modeSombre ? const Color(0xFF111C2E) : Colors.white;
    final bordure = modeSombre
        ? const Color(0xFF334155)
        : const Color(0xFFE2E8F0);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: fond,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: bordure),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.info_outline, color: Color(0xFFE85D00)),
              const SizedBox(width: 8),
              Text(
                'Consignes',
                style: TextStyle(
                  color: couleurTexte,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            '• Format accepté : PDF, DOC ou DOCX\n'
            '• Respecter le modèle de l’établissement\n'
            '• Inclure introduction, développement et conclusion\n'
            '• Vérifier le document avant la soumission',
            style: TextStyle(color: couleurTexte, height: 1.45),
          ),
        ],
      ),
    );
  }
}

class _EtatRapport extends StatelessWidget {
  const _EtatRapport({required this.statut, required this.version});
  final String statut;
  final int version;
  @override
  Widget build(BuildContext context) {
    final modeSombre = Theme.of(context).brightness == Brightness.dark;
    final fond = modeSombre ? const Color(0xFF111C2E) : Colors.white;
    final bordure = modeSombre
        ? const Color(0xFF334155)
        : const Color(0xFFE2E8F0);
    final textePrincipal = modeSombre ? Colors.white : const Color(0xFF0F172A);
    final texteSecondaire = modeSombre
        ? const Color(0xFF94A3B8)
        : const Color(0xFF4B5563);
    return Container(
      constraints: const BoxConstraints(minHeight: 96),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: fond,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: bordure),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const CircleAvatar(
            radius: 22,
            backgroundColor: Color(0xFFFFE3D1),
            child: Icon(Icons.assignment_outlined, color: Color(0xFFE85D00)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'État du rapport',
                  style: TextStyle(
                    color: textePrincipal,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  version == 0
                      ? 'Aucune version enregistrée'
                      : 'Version $version',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: texteSecondaire, fontSize: 13),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 110),
            child: Chip(
              backgroundColor: modeSombre
                  ? const Color(0xFF1E3A5F)
                  : const Color(0xFFEFF6FF),
              side: BorderSide(
                color: modeSombre
                    ? const Color(0xFF315F8C)
                    : const Color(0xFFBFDBFE),
              ),
              label: Text(statut, maxLines: 1, overflow: TextOverflow.ellipsis),
              labelStyle: TextStyle(
                color: modeSombre
                    ? const Color(0xFFBFDBFE)
                    : const Color(0xFF1D4ED8),
                fontWeight: FontWeight.w700,
              ),
              visualDensity: VisualDensity.compact,
            ),
          ),
        ],
      ),
    );
  }
}
