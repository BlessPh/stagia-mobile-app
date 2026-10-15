import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/network/client_api_http.dart';
import '../../../../core/network/reponse_api.dart';
import '../../../../core/network/source_etudiant_distante.dart';
import '../../../../core/services/session_authentification_service.dart';
import '../../../../core/services/sse_notifications_service.dart';
import '../../../../core/widgets/contenu_adaptatif.dart';

class SupprimerComptePage extends StatefulWidget {
  const SupprimerComptePage({super.key, this.source});

  final SourceEtudiantDistante? source;

  @override
  State<SupprimerComptePage> createState() => _SupprimerComptePageState();
}

class _SupprimerComptePageState extends State<SupprimerComptePage> {
  final _formKey = GlobalKey<FormState>();
  final _motDePasseController = TextEditingController();
  final _confirmationController = TextEditingController();

  late final SourceEtudiantDistante _source =
      widget.source ?? SourceEtudiantDistante(ClientApiHttp());

  bool _masquerMotDePasse = true;
  bool _chargement = false;
  String? _erreur;

  @override
  void dispose() {
    _motDePasseController.dispose();
    _confirmationController.dispose();
    super.dispose();
  }

  Future<void> _confirmer() async {
    FocusScope.of(context).unfocus();
    setState(() => _erreur = null);
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _chargement = true);
    try {
      await _source.desactiverCompte(
        password: _motDePasseController.text,
        confirmation: _confirmationController.text,
      );
      SseNotificationsService.instance.arreter();
      await SessionAuthentificationService.supprimer();
      if (!mounted) return;
      await SystemNavigator.pop();
    } on ErreurApi catch (erreur) {
      if (!mounted) return;
      setState(() {
        _erreur = erreur.message;
        _chargement = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _erreur =
            'La désactivation du compte a échoué. Vérifiez votre connexion et réessayez.';
        _chargement = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final modeSombre = Theme.of(context).brightness == Brightness.dark;
    final fondPage = modeSombre
        ? const Color(0xFF0F172A)
        : const Color(0xFFF4F5F7);
    final fondCarte = modeSombre ? const Color(0xFF1E293B) : Colors.white;
    final texte = modeSombre ? Colors.white : const Color(0xFF1E293B);
    final texteSecondaire = modeSombre
        ? const Color(0xFFCBD5E1)
        : const Color(0xFF64748B);
    final bordure = modeSombre
        ? const Color(0xFF334155)
        : const Color(0xFFCBD5E1);

    final decorationChamp = InputDecoration(
      filled: true,
      fillColor: fondCarte,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: bordure),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: bordure),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFFEF4444), width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFFEF4444)),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFFEF4444), width: 1.5),
      ),
    );

    return Scaffold(
      backgroundColor: fondPage,
      appBar: AppBar(
        backgroundColor: fondPage,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        centerTitle: true,
        leading: IconButton(
          onPressed: _chargement ? null : () => Navigator.of(context).pop(),
          icon: Icon(Icons.arrow_back_ios_new_rounded, size: 20, color: texte),
        ),
        title: Text(
          'Supprimer le compte',
          style: GoogleFonts.inter(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: texte,
            letterSpacing: -0.3,
          ),
        ),
      ),
      body: SafeArea(
        child: ContenuAdaptatif(
          largeurMaximale: 520,
          enfant: Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 36),
              children: [
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: modeSombre
                        ? const Color(0xFF3F2025)
                        : const Color(0xFFFEF2F2),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: modeSombre
                          ? const Color(0xFF7F1D1D)
                          : const Color(0xFFFECACA),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.warning_amber_rounded,
                        color: Color(0xFFEF4444),
                        size: 30,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Avant de continuer',
                        style: GoogleFonts.inter(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          color: texte,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Votre compte sera immédiatement désactivé et sa suppression définitive sera programmée dans 30 jours. Pendant cette période, vous ne pourrez plus accéder à l’application.',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          height: 1.5,
                          color: texteSecondaire,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Si vous vous reconnectez avec vos identifiants avant la fin des 30 jours, la suppression sera annulée et votre compte sera automatiquement réactivé.',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          height: 1.5,
                          fontWeight: FontWeight.w600,
                          color: texte,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 28),
                _LibelleChamp(texte: 'Mot de passe actuel', couleur: texte),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _motDePasseController,
                  obscureText: _masquerMotDePasse,
                  enabled: !_chargement,
                  autofillHints: const [AutofillHints.password],
                  textInputAction: TextInputAction.next,
                  style: GoogleFonts.inter(color: texte),
                  decoration: decorationChamp.copyWith(
                    hintText: 'Saisissez votre mot de passe',
                    hintStyle: GoogleFonts.inter(color: texteSecondaire),
                    suffixIcon: IconButton(
                      onPressed: _chargement
                          ? null
                          : () => setState(
                              () => _masquerMotDePasse = !_masquerMotDePasse,
                            ),
                      icon: Icon(
                        _masquerMotDePasse
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                        color: texteSecondaire,
                      ),
                    ),
                  ),
                  validator: (valeur) => (valeur ?? '').isEmpty
                      ? 'Le mot de passe actuel est requis.'
                      : null,
                ),
                const SizedBox(height: 20),
                _LibelleChamp(texte: 'Phrase de confirmation', couleur: texte),
                const SizedBox(height: 6),
                Text(
                  'Saisissez exactement DESACTIVER',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: texteSecondaire,
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _confirmationController,
                  enabled: !_chargement,
                  textCapitalization: TextCapitalization.characters,
                  textInputAction: TextInputAction.done,
                  onFieldSubmitted: (_) => _chargement ? null : _confirmer(),
                  style: GoogleFonts.inter(
                    color: texte,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                  ),
                  decoration: decorationChamp.copyWith(
                    hintText: 'DESACTIVER',
                    hintStyle: GoogleFonts.inter(color: texteSecondaire),
                  ),
                  validator: (valeur) => valeur == 'DESACTIVER'
                      ? null
                      : 'Saisissez exactement DESACTIVER pour confirmer.',
                ),
                if (_erreur != null) ...[
                  const SizedBox(height: 18),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: modeSombre
                          ? const Color(0xFF3F2025)
                          : const Color(0xFFFEF2F2),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.error_outline_rounded,
                          color: Color(0xFFEF4444),
                          size: 20,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            _erreur!,
                            style: GoogleFonts.inter(
                              fontSize: 13.5,
                              height: 1.4,
                              color: const Color(0xFFEF4444),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 28),
                SizedBox(
                  height: 52,
                  child: FilledButton(
                    onPressed: _chargement ? null : _confirmer,
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFFEF4444),
                      disabledBackgroundColor: const Color(0xFFEF4444),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: _chargement
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: Colors.white,
                            ),
                          )
                        : Text(
                            'Confirmer la désactivation',
                            style: GoogleFonts.inter(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _LibelleChamp extends StatelessWidget {
  const _LibelleChamp({required this.texte, required this.couleur});

  final String texte;
  final Color couleur;

  @override
  Widget build(BuildContext context) => Text(
    texte,
    style: GoogleFonts.inter(
      fontSize: 14,
      fontWeight: FontWeight.w700,
      color: couleur,
    ),
  );
}
