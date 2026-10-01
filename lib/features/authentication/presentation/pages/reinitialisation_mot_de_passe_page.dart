import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/network/client_api_http.dart';
import '../../../../core/network/reponse_api.dart';
import '../../data/datasources/source_authentification_distante.dart';
import '../widgets/champ_authentification.dart';

class ReinitialisationMotDePassePage extends StatefulWidget {
  const ReinitialisationMotDePassePage({super.key, required this.token});

  /// Token extrait directement du lien e-mail (?token=...)
  final String token;

  @override
  State<ReinitialisationMotDePassePage> createState() =>
      _ReinitialisationMotDePassePageState();
}

class _ReinitialisationMotDePassePageState
    extends State<ReinitialisationMotDePassePage> {
  final _cleFormulaire = GlobalKey<FormState>();
  final _motDePasse = TextEditingController();
  final _confirmation = TextEditingController();

  final _sourceAuthentification = SourceAuthentificationDistante(
    ClientApiHttp(),
  );

  bool _chargement = false;
  bool _masquerMotDePasse = true;
  bool _masquerConfirmation = true;
  String? _erreur;

  @override
  void dispose() {
    _motDePasse.dispose();
    _confirmation.dispose();
    super.dispose();
  }

  Future<void> _soumettre() async {
    setState(() => _erreur = null);
    if (!(_cleFormulaire.currentState?.validate() ?? false)) return;

    if (widget.token.trim().isEmpty) {
      setState(
        () => _erreur = 'Lien de réinitialisation invalide ou manquant.',
      );
      return;
    }

    FocusScope.of(context).unfocus();
    setState(() => _chargement = true);

    try {
      await _sourceAuthentification.reinitialiserMotDePasse(
        token: widget.token.trim(),
        password: _motDePasse.text,
        passwordConfirmation: _confirmation.text,
      );

      if (!mounted) return;
      // Rediriger vers l'écran de connexion
      Navigator.of(context).popUntil((route) => route.isFirst);
    } on ErreurApi catch (e) {
      if (!mounted) return;
      setState(() => _erreur = e.message);
    } catch (_) {
      if (!mounted) return;
      setState(
        () => _erreur =
            'Impossible de contacter le serveur. Vérifiez votre connexion.',
      );
    } finally {
      if (mounted) setState(() => _chargement = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final tokenValide = widget.token.trim().isNotEmpty;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Color(0xFF1E293B),
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Form(
                key: _cleFormulaire,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        color: const Color(0xFFFF7417).withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.key_rounded,
                        color: Color(0xFFFF7417),
                        size: 32,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Nouveau mot de passe',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 26,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Définissez votre nouveau mot de passe pour sécuriser votre compte.',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: const Color(0xFF64748B),
                        height: 1.45,
                      ),
                    ),
                    const SizedBox(height: 28),
                    if (!tokenValide) ...[
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEE2E2),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFFCA5A5)),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.error_outline_rounded,
                              color: Color(0xFFDC2626),
                              size: 20,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'Le lien de réinitialisation est incomplet ou invalide. Veuillez refaire une demande.',
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  color: const Color(0xFF991B1B),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],
                    if (_erreur != null) ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEE2E2),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFFCA5A5)),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.error_outline_rounded,
                              color: Color(0xFFDC2626),
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _erreur!,
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  color: const Color(0xFF991B1B),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],
                    ChampAuthentification(
                      libelle: 'Nouveau mot de passe',
                      indication:
                          'Min. 8 car., majuscule, minuscule, chiffre & symbole',
                      controleur: _motDePasse,
                      icone: Icons.lock_outline_rounded,
                      masquerTexte: _masquerMotDePasse,
                      iconeSuffixe: _masquerMotDePasse
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                      actionSuffixe: () => setState(
                        () => _masquerMotDePasse = !_masquerMotDePasse,
                      ),
                      validateur: (v) {
                        if (v == null || v.isEmpty) {
                          return 'Le mot de passe est obligatoire';
                        }
                        if (v.length < 8) {
                          return 'Au moins 8 caractères requis';
                        }
                        final hasUpper = v.contains(RegExp(r'[A-Z]'));
                        final hasLower = v.contains(RegExp(r'[a-z]'));
                        final hasDigit = v.contains(RegExp(r'[0-9]'));
                        final hasSpecial = v.contains(
                          RegExp(r'[!@#$%^&*(),.?":{}|<>_\-]'),
                        );
                        if (!hasUpper ||
                            !hasLower ||
                            !hasDigit ||
                            !hasSpecial) {
                          return 'Doit contenir majuscule, minuscule, chiffre et symbole';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    ChampAuthentification(
                      libelle: 'Confirmer le mot de passe',
                      indication: 'Retapez le mot de passe',
                      controleur: _confirmation,
                      icone: Icons.lock_outline_rounded,
                      masquerTexte: _masquerConfirmation,
                      iconeSuffixe: _masquerConfirmation
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                      actionSuffixe: () => setState(
                        () => _masquerConfirmation = !_masquerConfirmation,
                      ),
                      validateur: (v) {
                        if (v == null || v.isEmpty) {
                          return 'Veuillez confirmer le mot de passe';
                        }
                        if (v != _motDePasse.text) {
                          return 'Les mots de passe ne correspondent pas';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 28),
                    SizedBox(
                      height: 52,
                      child: FilledButton(
                        onPressed: (_chargement || !tokenValide)
                            ? null
                            : _soumettre,
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFF0F172A),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: _chargement
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.white,
                                  ),
                                ),
                              )
                            : Text(
                                'Enregistrer le nouveau mot de passe',
                                style: GoogleFonts.inter(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
