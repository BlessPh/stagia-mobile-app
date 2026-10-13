import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/network/client_api_http.dart';
import '../../../../core/network/reponse_api.dart';
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
  String? _dateContexteApi;
  String? _raisonBlocageJournal;
  bool _contexteCharge = false;
  bool _journalAutorise = false;
  late final String _resumeInitial;

  final List<Map<String, dynamic>> _activitesCliniques = [];

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
    _resumeInitial = donnees['summary']?.toString() ?? '';
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
        'category': activite['category']?.toString(),
        'involvement_level': activite['involvement_level']?.toString(),
        'description': activite['description']?.toString(),
        'quantity': activite['quantity'],
        'observation': activite['observation']?.toString(),
      });
    }
    _chargerContexteExecution();
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
                    ..._valeursActivite(typeSelectionne!),
                    'description': titreCtrl.text.trim(),
                    'quantity': 1,
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
    return null;
  }

  bool get _estNouveauJournal => (widget.logbookUuid ?? '').trim().isEmpty;

  Map<String, dynamic> get _actionsJournal =>
      _map(widget.donneesJournal?['actions']);

  bool get _journalModifiable {
    if (_estNouveauJournal) return _journalAutorise;
    final action = _map(_actionsJournal['edit']);
    return action.containsKey('allowed')
        ? action['allowed'] == true
        : widget.donneesJournal?['editable'] == true;
  }

  bool get _journalSoumissible {
    if (_estNouveauJournal) return _journalAutorise;
    final action = _map(_actionsJournal['submit']);
    final soumissionDirecte = action.containsKey('allowed')
        ? action['allowed'] == true
        : widget.donneesJournal?['can_submit'] == true;
    return soumissionDirecte || _journalModifiable;
  }

  bool get _saisieVerrouillee =>
      widget.estLectureSeule || (!_estNouveauJournal && !_journalModifiable);

  Future<void> _chargerContexteExecution() async {
    final assignmentJournal = _map(widget.donneesJournal?['assignment']);
    final reference = widget.assignmentUuid?.trim().isNotEmpty == true
        ? widget.assignmentUuid!.trim()
        : assignmentJournal['uuid']?.toString().trim();

    try {
      final reponse = await _source.contexteExecution(
        assignmentUuid: reference?.isNotEmpty == true ? reference : null,
      );
      final context = _map(reponse['context']);
      final execution = _map(reponse['execution']);
      final punch = _map(reponse['punch']);
      final assignment = _map(context['assignment']);
      final actions = _map(context['actions']);
      final actionJournal = _map(actions['logbook']);
      final capabilities = _map(context['capabilities']);
      final uuid = assignment['uuid']?.toString().trim() ?? '';
      final dateApi = context['date']?.toString().trim() ?? '';
      final autorise =
          actionJournal['allowed'] == true && capabilities['logbook'] == true;

      if (!mounted) return;
      setState(() {
        _assignmentUuidApi = uuid.isEmpty ? null : uuid;
        _dateContexteApi = DateTime.tryParse(dateApi) == null ? null : dateApi;
        _raisonBlocageJournal =
            (context['reason'] ?? execution['reason'] ?? punch['reason'])
                ?.toString();
        _journalAutorise = autorise;
        _contexteCharge = true;
        final dateContexte = DateTime.tryParse(dateApi);
        if (_estNouveauJournal && dateContexte != null) {
          _dateController.text = _formaterDateDuJour(dateContexte);
        }
      });
    } on ErreurApi catch (erreur) {
      if (!mounted) return;
      setState(() {
        _raisonBlocageJournal = erreur.message;
        _journalAutorise = false;
        _contexteCharge = true;
      });
    }
  }

  bool _verifierAutorisationJournal({required bool soumettre}) {
    if (!_estNouveauJournal) {
      final autorise = soumettre ? _journalSoumissible : _journalModifiable;
      if (autorise) return true;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ce journal ne peut plus être modifié.'),
          backgroundColor: Color(0xFFDC2626),
        ),
      );
      return false;
    }
    if (_contexteCharge &&
        _journalAutorise &&
        _assignmentUuidEffectif != null) {
      return true;
    }
    final message = !_contexteCharge
        ? 'Vérification du contexte de stage en cours.'
        : (_raisonBlocageJournal?.trim().isNotEmpty == true
              ? _raisonBlocageJournal!.trim()
              : 'Aucune rotation active ne permet de saisir un journal.');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: const Color(0xFFDC2626),
      ),
    );
    return false;
  }

  List<Map<String, dynamic>> get _activitesPourApi => _activitesCliniques
      .where((activite) => (activite['titre'] ?? '').trim().isNotEmpty)
      .map(
        (activite) => <String, dynamic>{
          'category':
              activite['category'] ??
              _valeursActivite(activite['type']?.toString() ?? '')['category'],
          'activity': activite['titre'] ?? '',
          'description': activite['description'] ?? activite['titre'] ?? '',
          'involvement_level':
              activite['involvement_level'] ??
              _valeursActivite(
                activite['type']?.toString() ?? '',
              )['involvement_level'],
          'quantity': activite['quantity'] ?? 1,
          if ((activite['observation']?.toString().trim() ?? '').isNotEmpty)
            'observation': activite['observation'].toString().trim(),
        },
      )
      .toList();

  String get _datePourApi {
    if ((widget.logbookUuid ?? '').isNotEmpty) {
      final dateExistante = widget.donneesJournal?['date']?.toString() ?? '';
      if (DateTime.tryParse(dateExistante) != null) return dateExistante;
    }
    return _dateContexteApi ??
        DateTime.now().toIso8601String().split('T').first;
  }

  String get _resumePourApi {
    if (!_estNouveauJournal && _resumeInitial.trim().isNotEmpty) {
      return _resumeInitial.trim();
    }
    return _apprentissageController.text.trim();
  }

  @override
  Widget build(BuildContext context) {
    final modeSombre = Theme.of(context).brightness == Brightness.dark;
    final fondPage = modeSombre
        ? const Color(0xFF0F172A)
        : const Color(0xFFF8FAFC);
    final fondCarte = modeSombre ? const Color(0xFF1E293B) : Colors.white;
    final bordure = modeSombre
        ? const Color(0xFF334155)
        : const Color(0xFFE2E8F0);
    final textePrincipal = modeSombre ? Colors.white : const Color(0xFF0F172A);
    final texteSecondaire = modeSombre
        ? const Color(0xFFCBD5E1)
        : const Color(0xFF475569);
    return Scaffold(
      backgroundColor: fondPage,
      appBar: AppBar(
        backgroundColor: fondPage,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: Icon(
            CupertinoIcons.chevron_left,
            color: textePrincipal,
            size: 24,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Saisir un journal',
          style: GoogleFonts.inter(
            fontSize: 18.5,
            fontWeight: FontWeight.w800,
            color: textePrincipal,
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
                color: textePrincipal,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: fondCarte,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: bordure),
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
                      color: textePrincipal,
                    ),
                  ),
                  Icon(
                    CupertinoIcons.calendar,
                    size: 20,
                    color: texteSecondaire,
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
                color: textePrincipal,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: fondCarte,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: bordure),
              ),
              padding: const EdgeInsets.all(14),
              child: TextField(
                controller: _apprentissageController,
                readOnly: _saisieVerrouillee,
                maxLines: 3,
                style: GoogleFonts.inter(fontSize: 13.5, color: textePrincipal),
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
                color: textePrincipal,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: fondCarte,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: bordure),
              ),
              padding: const EdgeInsets.all(14),
              child: TextField(
                controller: _difficultesController,
                readOnly: _saisieVerrouillee,
                maxLines: 3,
                style: GoogleFonts.inter(fontSize: 13.5, color: textePrincipal),
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
                    color: textePrincipal,
                  ),
                ),
                GestureDetector(
                  onTap: _saisieVerrouillee ? null : _ajouterActiviteDialog,
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
                    color: fondCarte,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: bordure),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: modeSombre
                              ? const Color(0xFF0C4A6E)
                              : const Color(0xFFE0F2FE),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          act['type']?.toString() ?? '',
                          style: GoogleFonts.inter(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w800,
                            color: modeSombre
                                ? const Color(0xFF7DD3FC)
                                : const Color(0xFF0284C7),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          act['titre']?.toString() ?? '',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: textePrincipal,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            const SizedBox(height: 24),

            if (!_saisieVerrouillee) ...[
              // Bouton Soumettre à l'encadreur (Bleu)
              SizedBox(
                width: double.infinity,
                height: 48,
                child: FilledButton(
                  onPressed: _envoiEnCours
                      ? null
                      : () async {
                          if (!_verifierAutorisationJournal(soumettre: true)) {
                            return;
                          }
                          final messenger = ScaffoldMessenger.of(context);
                          final navigator = Navigator.of(context);
                          setState(() => _envoiEnCours = true);
                          try {
                            // 1. Sauvegarder d'abord le brouillon
                            final assignUuid = _assignmentUuidEffectif;
                            if (assignUuid == null) {
                              throw const ErreurApi(
                                code: 'CONTEXTE_STAGE_ABSENT',
                                message:
                                    'Aucun stage actif ne permet de saisir un journal.',
                              );
                            }
                            final res = await _source.sauvegarderJournal(
                              assignmentUuid: assignUuid,
                              date: _datePourApi,
                              summary: _resumePourApi,
                              learning: _apprentissageController.text.trim(),
                              difficulties: _difficultesController.text.trim(),
                              activities: _activitesPourApi,
                              logbookUuid: widget.logbookUuid,
                            );
                            final entree = _map(res['entry']);
                            final uuidJournal = entree['uuid']?.toString();
                            if (uuidJournal == null || uuidJournal.isEmpty) {
                              throw const ErreurApi(
                                code: 'DONNEES_API_INVALIDES',
                                message:
                                    'Le serveur n’a pas retourné le journal enregistré.',
                              );
                            }
                            final soumission = await _source.soumettreJournal(
                              logbookUuid: uuidJournal,
                            );
                            final message =
                                soumission['message']?.toString().trim() ?? '';
                            messenger.showSnackBar(
                              SnackBar(
                                content: Text(
                                  message.isNotEmpty
                                      ? message
                                      : 'Journal soumis à l’encadreur avec succès !',
                                ),
                                backgroundColor: const Color(0xFF16A34A),
                              ),
                            );
                            navigator.pop(true);
                          } on ErreurApi catch (erreur) {
                            messenger.showSnackBar(
                              SnackBar(
                                content: Text(erreur.message),
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
                          if (!_verifierAutorisationJournal(soumettre: false)) {
                            return;
                          }
                          final messenger = ScaffoldMessenger.of(context);
                          final navigator = Navigator.of(context);
                          setState(() => _envoiEnCours = true);
                          try {
                            final assignUuid = _assignmentUuidEffectif;
                            if (assignUuid == null) {
                              throw const ErreurApi(
                                code: 'CONTEXTE_STAGE_ABSENT',
                                message:
                                    'Aucun stage actif ne permet de saisir un journal.',
                              );
                            }
                            final resultat = await _source.sauvegarderJournal(
                              assignmentUuid: assignUuid,
                              date: _datePourApi,
                              summary: _resumePourApi,
                              learning: _apprentissageController.text.trim(),
                              difficulties: _difficultesController.text.trim(),
                              activities: _activitesPourApi,
                              logbookUuid: widget.logbookUuid,
                            );
                            final message =
                                resultat['message']?.toString().trim() ?? '';
                            messenger.showSnackBar(
                              SnackBar(
                                content: Text(
                                  message.isNotEmpty
                                      ? message
                                      : 'Journal enregistré en brouillon avec succès !',
                                ),
                              ),
                            );
                            navigator.pop(true);
                          } on ErreurApi catch (erreur) {
                            messenger.showSnackBar(
                              SnackBar(
                                content: Text(erreur.message),
                                backgroundColor: const Color(0xFFDC2626),
                              ),
                            );
                          } finally {
                            if (mounted) setState(() => _envoiEnCours = false);
                          }
                        },
                  style: OutlinedButton.styleFrom(
                    backgroundColor: fondCarte,
                    side: BorderSide(color: bordure),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: Text(
                    'Enregistrer en Brouillon',
                    style: GoogleFonts.inter(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w700,
                      color: texteSecondaire,
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

Map<String, dynamic> _valeursActivite(String libelle) =>
    switch (libelle.toUpperCase()) {
      'OBSERVATION' ||
      'OBSERVE' => {'category': 'OBSERVATION', 'involvement_level': 'OBSERVE'},
      'ASSISTANCE' || 'ASSISTE' => {
        'category': 'PARTICIPATION',
        'involvement_level': 'ASSISTE',
      },
      'RÉALISATION' || 'REALISATION' || 'REALISE_SUPERVISE' => {
        'category': 'REALISATION',
        'involvement_level': 'REALISE_SUPERVISE',
      },
      'REALISE_AUTONOME' => {
        'category': 'REALISATION',
        'involvement_level': 'REALISE_AUTONOME',
      },
      _ => {'category': 'AUTRE', 'involvement_level': ''},
    };
