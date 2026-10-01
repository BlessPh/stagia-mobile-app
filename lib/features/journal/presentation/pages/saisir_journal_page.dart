import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/network/client_api_http.dart';
import '../../../../core/network/configuration_api.dart';
import '../../../../core/network/source_etudiant_distante.dart';

class SaisirJournalPage extends StatefulWidget {
  const SaisirJournalPage({
    this.dateInitiale,
    this.assignmentUuid,
    this.logbookUuid,
    this.donneesJournal,
    this.estLectureSeule = false,
    super.key,
  });

  final String? dateInitiale;
  final String? assignmentUuid;
  final String? logbookUuid;
  final Map<String, dynamic>? donneesJournal;
  final bool estLectureSeule;

  @override
  State<SaisirJournalPage> createState() => _SaisirJournalPageState();
}

class _SaisirJournalPageState extends State<SaisirJournalPage> {
  final _source = SourceEtudiantDistante(ClientApiHttp());
  bool _envoiEnCours = false;
  late final TextEditingController _dateController;
  late final TextEditingController _apprentissageController;
  late final TextEditingController _difficultesController;
  String? _assignmentUuidApi;

  final List<Map<String, String>> _activitesCliniques = [];

  @override
  void initState() {
    super.initState();
    final donnees = widget.donneesJournal ?? const <String, dynamic>{};
    final date = widget.dateInitiale?.trim().isNotEmpty == true
        ? widget.dateInitiale!.trim()
        : donnees['date']?.toString().trim().isNotEmpty == true
        ? donnees['date'].toString().trim()
        : _formaterDateDuJour(DateTime.now());
    _dateController = TextEditingController(text: date);
    _apprentissageController = TextEditingController(
      text: (donnees['learning'] ?? donnees['summary'])?.toString() ?? '',
    );
    _difficultesController = TextEditingController(
      text: donnees['difficulties']?.toString() ?? '',
    );
    for (final activite in _items(donnees['activities'])) {
      final titre =
          (activite['activity'] ?? activite['title'])?.toString().trim() ?? '';
      if (titre.isEmpty) continue;
      _activitesCliniques.add({
        'type':
            (activite['involvement_level'] ?? activite['category'])
                ?.toString()
                .toUpperCase() ??
            '',
        'titre': titre,
      });
    }
    _chargerAffectationActive();
  }

  @override
  void dispose() {
    _dateController.dispose();
    _apprentissageController.dispose();
    _difficultesController.dispose();
    super.dispose();
  }

  void _ajouterActiviteDialog() {
    String? typeSelectionne;
    final titreCtrl = TextEditingController();

    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          'Ajouter une activité',
          style: GoogleFonts.inter(fontWeight: FontWeight.w800, fontSize: 17),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<String>(
              initialValue: null,
              items: [
                'RÉALISATION',
                'OBSERVATION',
                'ASSISTANCE',
              ].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
              onChanged: (v) => typeSelectionne = v,
              decoration: const InputDecoration(labelText: 'Type'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: titreCtrl,
              decoration: const InputDecoration(
                labelText: 'Intitulé de l\'activité',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () {
              if (typeSelectionne != null && titreCtrl.text.trim().isNotEmpty) {
                setState(() {
                  _activitesCliniques.add({
                    'type': typeSelectionne!,
                    'titre': titreCtrl.text.trim(),
                  });
                });
              }
              Navigator.pop(ctx);
            },
            child: const Text('Ajouter'),
          ),
        ],
      ),
    );
  }

  String? get _assignmentUuidEffectif {
    final direct = widget.assignmentUuid?.trim() ?? '';
    if (direct.isNotEmpty) return direct;
    final assignment = _map(widget.donneesJournal?['assignment']);
    final depuisJournal = assignment['uuid']?.toString().trim() ?? '';
    if (depuisJournal.isNotEmpty) return depuisJournal;
    if ((_assignmentUuidApi ?? '').isNotEmpty) return _assignmentUuidApi;
    return ConfigurationApi.utiliserDonneesMockees
        ? 'default-assignment'
        : null;
  }

  Future<void> _chargerAffectationActive() async {
    if (ConfigurationApi.utiliserDonneesMockees ||
        _assignmentUuidEffectif != null) {
      return;
    }
    try {
      final reponse = await _source.stages();
      final stages = _items(reponse['items']);
      for (final stage in stages) {
        final statut = (stage['assignment_status'] ?? stage['workflow_status'])
            ?.toString()
            .toUpperCase();
        if (statut == 'ACTIVE' || statut == 'EN_COURS') {
          final uuid = stage['assignment_uuid']?.toString().trim() ?? '';
          if (uuid.isNotEmpty && mounted) {
            setState(() => _assignmentUuidApi = uuid);
          }
          return;
        }
      }
    } catch (_) {
      // L'absence de contexte sera expliquée au moment de l'enregistrement.
    }
  }

  List<Map<String, dynamic>> get _activitesPourApi => _activitesCliniques
      .where((activite) => (activite['titre'] ?? '').trim().isNotEmpty)
      .map(
        (activite) => <String, dynamic>{
          'category': activite['type'] ?? '',
          'activity': activite['titre'] ?? '',
          'description': activite['titre'] ?? '',
        },
      )
      .toList();

  String get _datePourApi {
    if ((widget.logbookUuid ?? '').isNotEmpty) {
      final dateExistante = widget.donneesJournal?['date']?.toString() ?? '';
      if (DateTime.tryParse(dateExistante) != null) return dateExistante;
    }
    return DateTime.now().toIso8601String().split('T').first;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF8FAFC),
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(
            CupertinoIcons.chevron_left,
            color: Color(0xFF0F172A),
            size: 24,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Saisir un journal',
          style: GoogleFonts.inter(
            fontSize: 18.5,
            fontWeight: FontWeight.w800,
            color: const Color(0xFF0F172A),
          ),
        ),
      ),
      body: SafeArea(
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
          children: [
            // Date du journal
            Text(
              'Date du journal',
              style: GoogleFonts.inter(
                fontSize: 13.5,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _dateController.text,
                    style: GoogleFonts.inter(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF0F172A),
                    ),
                  ),
                  const Icon(
                    CupertinoIcons.calendar,
                    size: 20,
                    color: Color(0xFF64748B),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 18),

            // Principaux apprentissages
            Text(
              'Principaux apprentissages',
              style: GoogleFonts.inter(
                fontSize: 13.5,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              padding: const EdgeInsets.all(14),
              child: TextField(
                controller: _apprentissageController,
                maxLines: 3,
                style: GoogleFonts.inter(
                  fontSize: 13.5,
                  color: const Color(0xFF0F172A),
                ),
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ),

            const SizedBox(height: 18),

            // Difficultés rencontrées
            Text(
              'Difficultés rencontrées',
              style: GoogleFonts.inter(
                fontSize: 13.5,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              padding: const EdgeInsets.all(14),
              child: TextField(
                controller: _difficultesController,
                maxLines: 3,
                style: GoogleFonts.inter(
                  fontSize: 13.5,
                  color: const Color(0xFF0F172A),
                ),
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ),

            const SizedBox(height: 20),

            // En-tête Activités cliniques (2) + Ajouter
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Activités cliniques (${_activitesCliniques.length})',
                  style: GoogleFonts.inter(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF0F172A),
                  ),
                ),
                GestureDetector(
                  onTap: _ajouterActiviteDialog,
                  child: Text(
                    '+ Ajouter',
                    style: GoogleFonts.inter(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF1D61F2),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Liste des pilules d'activités
            for (final act in _activitesCliniques)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE0F2FE),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          act['type']!,
                          style: GoogleFonts.inter(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF0284C7),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          act['titre']!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF0F172A),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            const SizedBox(height: 24),

            if (!widget.estLectureSeule) ...[
              // Bouton Soumettre à l'encadreur (Bleu)
              SizedBox(
                width: double.infinity,
                height: 48,
                child: FilledButton(
                  onPressed: _envoiEnCours
                      ? null
                      : () async {
                          final messenger = ScaffoldMessenger.of(context);
                          final navigator = Navigator.of(context);
                          setState(() => _envoiEnCours = true);
                          try {
                            // 1. Sauvegarder d'abord le brouillon
                            final assignUuid = _assignmentUuidEffectif;
                            if (assignUuid == null) {
                              throw StateError(
                                'Aucun stage actif ne permet de saisir un journal.',
                              );
                            }
                            final res = await _source.sauvegarderJournal(
                              assignmentUuid: assignUuid,
                              date: _datePourApi,
                              summary: _apprentissageController.text.trim(),
                              learning: _apprentissageController.text.trim(),
                              difficulties: _difficultesController.text.trim(),
                              activities: _activitesPourApi,
                              logbookUuid: widget.logbookUuid,
                            );
                            final uuidJournal =
                                res['uuid']?.toString() ??
                                res['logbook_uuid']?.toString() ??
                                widget.logbookUuid;
                            if (uuidJournal != null) {
                              await _source.soumettreJournal(
                                logbookUuid: uuidJournal,
                              );
                            }
                            messenger.showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Journal soumis à l’encadreur avec succès !',
                                ),
                                backgroundColor: Color(0xFF16A34A),
                              ),
                            );
                            navigator.pop(true);
                          } catch (e) {
                            messenger.showSnackBar(
                              SnackBar(
                                content: Text('Échec de la soumission: $e'),
                                backgroundColor: const Color(0xFFDC2626),
                              ),
                            );
                          } finally {
                            if (mounted) setState(() => _envoiEnCours = false);
                          }
                        },
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF1D61F2),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 0,
                  ),
                  child: _envoiEnCours
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : Text(
                          'Soumettre à l\'encadreur',
                          style: GoogleFonts.inter(
                            fontSize: 14.5,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),

              const SizedBox(height: 10),

              // Bouton Enregistrer en Brouillon (Blanc bordé)
              SizedBox(
                width: double.infinity,
                height: 48,
                child: OutlinedButton(
                  onPressed: _envoiEnCours
                      ? null
                      : () async {
                          final messenger = ScaffoldMessenger.of(context);
                          final navigator = Navigator.of(context);
                          setState(() => _envoiEnCours = true);
                          try {
                            final assignUuid = _assignmentUuidEffectif;
                            if (assignUuid == null) {
                              throw StateError(
                                'Aucun stage actif ne permet de saisir un journal.',
                              );
                            }
                            await _source.sauvegarderJournal(
                              assignmentUuid: assignUuid,
                              date: _datePourApi,
                              summary: _apprentissageController.text.trim(),
                              learning: _apprentissageController.text.trim(),
                              difficulties: _difficultesController.text.trim(),
                              activities: _activitesPourApi,
                              logbookUuid: widget.logbookUuid,
                            );
                            messenger.showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Journal enregistré en brouillon avec succès !',
                                ),
                              ),
                            );
                            navigator.pop(true);
                          } catch (e) {
                            messenger.showSnackBar(
                              SnackBar(
                                content: Text('Échec de l\'enregistrement: $e'),
                                backgroundColor: const Color(0xFFDC2626),
                              ),
                            );
                          } finally {
                            if (mounted) setState(() => _envoiEnCours = false);
                          }
                        },
                  style: OutlinedButton.styleFrom(
                    backgroundColor: Colors.white,
                    side: const BorderSide(color: Color(0xFFE2E8F0)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: Text(
                    'Enregistrer en Brouillon',
                    style: GoogleFonts.inter(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF475569),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

String _formaterDateDuJour(DateTime date) {
  const mois = [
    'Janvier',
    'Février',
    'Mars',
    'Avril',
    'Mai',
    'Juin',
    'Juillet',
    'Août',
    'Septembre',
    'Octobre',
    'Novembre',
    'Décembre',
  ];
  return '${date.day} ${mois[date.month - 1]} ${date.year}';
}

List<Map<String, dynamic>> _items(Object? valeur) => valeur is List
    ? valeur
          .whereType<Map>()
          .map((item) => Map<String, dynamic>.from(item))
          .toList()
    : <Map<String, dynamic>>[];

Map<String, dynamic> _map(Object? valeur) =>
    valeur is Map ? Map<String, dynamic>.from(valeur) : <String, dynamic>{};
