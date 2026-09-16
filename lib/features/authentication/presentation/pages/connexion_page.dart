import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../app/navigation/main_shell.dart';
import '../../../../core/network/client_api_http.dart';
import '../../../../core/network/configuration_api.dart';
import '../../../../core/network/reponse_api.dart';
import '../../../../core/services/session_authentification_service.dart';
import '../../../../core/theme/app_theme.dart';
import '../../data/datasources/source_authentification_distante.dart';

class ConnexionPage extends StatefulWidget {
  const ConnexionPage({super.key});

  @override
  State<ConnexionPage> createState() => _ConnexionPageState();
}

class _ConnexionPageState extends State<ConnexionPage> {
  final _cleFormulaire = GlobalKey<FormState>();
  final _identifiant = TextEditingController();
  final _motDePasse = TextEditingController();
  final _sourceAuthentification = SourceAuthentificationDistante(
    ClientApiHttp(),
  );
  bool _motDePasseMasque = true;
  bool _resterConnecte = false;
  bool _connexionEnCours = false;
  String? _erreurMotDePasse;
  String? _erreurIdentifiant;

  @override
  void dispose() {
    _identifiant.dispose();
    _motDePasse.dispose();
    super.dispose();
  }

  Future<void> _seConnecter() async {
    setState(() {
      _erreurIdentifiant = null;
      _erreurMotDePasse = null;
    });
    if (!(_cleFormulaire.currentState?.validate() ?? false)) return;

    if (!ConfigurationApi.utiliserAuthentificationApi) {
      if (_connexionEnCours) return;
      FocusScope.of(context).unfocus();
      setState(() => _connexionEnCours = true);
      await Future<void>.delayed(const Duration(seconds: 3));
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          behavior: SnackBarBehavior.floating,
          margin: EdgeInsets.all(16),
          duration: Duration(seconds: 2),
          backgroundColor: Color(0xFF16803C),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(16)),
          ),
          content: Row(
            children: [
              Icon(Icons.check_circle_outline_rounded, color: Colors.white),
              SizedBox(width: 10),
              Text('Connexion réussie.'),
            ],
          ),
        ),
      );
      await Future<void>.delayed(const Duration(milliseconds: 500));
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(builder: (_) => const MainShell()),
      );
      if (mounted) setState(() => _connexionEnCours = false);
      return;
    }

    FocusScope.of(context).unfocus();
    setState(() => _connexionEnCours = true);

    try {
      final session = await _sourceAuthentification.connecter(
        identifiant: _identifiant.text.trim(),
        motDePasse: _motDePasse.text,
      );
      await SessionAuthentificationService.enregistrer(session);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          behavior: SnackBarBehavior.floating,
          margin: EdgeInsets.all(16),
          duration: Duration(seconds: 2),
          backgroundColor: Color(0xFF16803C),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(16)),
          ),
          content: Row(
            children: [
              Icon(Icons.check_circle_outline_rounded, color: Colors.white),
              SizedBox(width: 10),
              Text('Connexion réussie.'),
            ],
          ),
        ),
      );
      await Future<void>.delayed(const Duration(milliseconds: 500));
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(builder: (_) => const MainShell()),
      );
    } on ErreurApi catch (erreur) {
      if (!mounted) return;
      if (_erreurReseau(erreur)) {
        _afficherMessage(_messageErreurConnexion(erreur), erreur: true);
      } else {
        setState(() {
          if (_erreurConcerneIdentifiant(erreur)) {
            _erreurIdentifiant = _messageErreurConnexion(erreur);
          } else {
            _erreurMotDePasse = _messageErreurConnexion(erreur);
          }
        });
      }
    } catch (_) {
      if (!mounted) return;
      _afficherMessage(
        'Connexion impossible. Vérifiez votre connexion internet.',
      );
    } finally {
      if (mounted) setState(() => _connexionEnCours = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final tailleEcran = MediaQuery.sizeOf(context);
    final clavierOuvert = MediaQuery.viewInsetsOf(context).bottom > 0;
    final petitEcran = tailleEcran.height < 700;
    final modeTablette = tailleEcran.width >= 600;
    final margeHorizontale = tailleEcran.width < 360 ? 20.0 : 28.0;

    return Theme(
      data: AppTheme.light,
      child: Scaffold(
        backgroundColor: const Color(0xFFFFFFFF),
        body: SafeArea(
          child: LayoutBuilder(
            builder: (context, contraintes) {
              return SingleChildScrollView(
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                physics: petitEcran || clavierOuvert
                    ? const ClampingScrollPhysics()
                    : const AlwaysScrollableScrollPhysics(),
                padding: EdgeInsets.symmetric(
                  horizontal: margeHorizontale,
                  vertical: 24.0,
                ),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: contraintes.maxHeight - 48.0,
                  ),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        maxWidth: modeTablette ? 400 : 440,
                      ),
                      child: Form(
                        key: _cleFormulaire,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // Cercle pastel supérieur
                            Center(
                              child: Container(
                                width: 88,
                                height: 88,
                                decoration: const BoxDecoration(
                                  color: Color(0xFFECEBFE),
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ),
                            const SizedBox(height: 30),

                            // Titre "Connexion"
                            Text(
                              'Connexion',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.inter(
                                fontSize: 32,
                                fontWeight: FontWeight.w800,
                                color: const Color(0xFF0F172A),
                                letterSpacing: -0.6,
                              ),
                            ),
                            const SizedBox(height: 8),

                            // Sous-titre
                            Text(
                              'Veillez vous connecter à votre éspace Stagia',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.inter(
                                fontSize: 14.5,
                                fontWeight: FontWeight.w400,
                                color: const Color(0xFF64748B),
                                height: 1.4,
                              ),
                            ),
                            const SizedBox(height: 36),

                            // Champ 1: E-mail ou matricule
                            Text(
                              'E-mail ou matricule',
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF0F172A),
                              ),
                            ),
                            const SizedBox(height: 8),
                            TextFormField(
                              controller: _identifiant,
                              keyboardType: TextInputType.emailAddress,
                              textInputAction: TextInputAction.next,
                              style: GoogleFonts.inter(
                                fontSize: 14.5,
                                fontWeight: FontWeight.w500,
                                color: const Color(0xFF0F172A),
                              ),
                              decoration: InputDecoration(
                                hintText: 'Entrez votre identifiant',
                                hintStyle: GoogleFonts.inter(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w400,
                                  color: const Color(0xFF94A3B8),
                                ),
                                filled: true,
                                fillColor: Colors.white,
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 16,
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(
                                    color: Color(0xFFE2E8F0),
                                    width: 1.2,
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(
                                    color: Color(0xFF0F172A),
                                    width: 1.5,
                                  ),
                                ),
                                errorBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(
                                    color: Color(0xFFEF4444),
                                    width: 1.2,
                                  ),
                                ),
                                focusedErrorBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(
                                    color: Color(0xFFEF4444),
                                    width: 1.5,
                                  ),
                                ),
                              ),
                              onChanged: (_) {
                                if (_erreurIdentifiant != null) {
                                  setState(() => _erreurIdentifiant = null);
                                }
                              },
                              validator: (valeur) =>
                                  _erreurIdentifiant ??
                                  _identifiantValide(valeur),
                            ),
                            const SizedBox(height: 18),

                            // Champ 2: Mot de passe
                            Text(
                              'Mot de passe',
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF0F172A),
                              ),
                            ),
                            const SizedBox(height: 8),
                            TextFormField(
                              controller: _motDePasse,
                              obscureText: _motDePasseMasque,
                              textInputAction: TextInputAction.done,
                              onFieldSubmitted: (_) => _seConnecter(),
                              style: GoogleFonts.inter(
                                fontSize: 14.5,
                                fontWeight: FontWeight.w500,
                                color: const Color(0xFF0F172A),
                              ),
                              decoration: InputDecoration(
                                hintText: 'Entrez votre mot de passe',
                                hintStyle: GoogleFonts.inter(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w400,
                                  color: const Color(0xFF94A3B8),
                                ),
                                filled: true,
                                fillColor: Colors.white,
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 16,
                                ),
                                suffixIcon: IconButton(
                                  splashRadius: 20,
                                  icon: Icon(
                                    _motDePasseMasque
                                        ? Icons.visibility_outlined
                                        : Icons.visibility_off_outlined,
                                    color: const Color(0xFF64748B),
                                    size: 20,
                                  ),
                                  onPressed: () {
                                    setState(
                                      () => _motDePasseMasque = !_motDePasseMasque,
                                    );
                                  },
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(
                                    color: Color(0xFFE2E8F0),
                                    width: 1.2,
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(
                                    color: Color(0xFF0F172A),
                                    width: 1.5,
                                  ),
                                ),
                                errorBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(
                                    color: Color(0xFFEF4444),
                                    width: 1.2,
                                  ),
                                ),
                                focusedErrorBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(
                                    color: Color(0xFFEF4444),
                                    width: 1.5,
                                  ),
                                ),
                              ),
                              onChanged: (_) {
                                if (_erreurMotDePasse != null) {
                                  setState(() => _erreurMotDePasse = null);
                                }
                              },
                              validator: _motDePasseValide,
                            ),
                            const SizedBox(height: 14),

                            // Ligne options: Rester connecté & Mot de passe oublié ?
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                InkWell(
                                  onTap: () {
                                    setState(
                                      () => _resterConnecte = !_resterConnecte,
                                    );
                                  },
                                  borderRadius: BorderRadius.circular(6),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 4,
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        SizedBox(
                                          width: 18,
                                          height: 18,
                                          child: Checkbox(
                                            value: _resterConnecte,
                                            onChanged: (val) {
                                              setState(
                                                () => _resterConnecte =
                                                    val ?? false,
                                              );
                                            },
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(4),
                                            ),
                                            side: const BorderSide(
                                              color: Color(0xFF94A3B8),
                                              width: 1.3,
                                            ),
                                            activeColor: const Color(0xFF0F172A),
                                            checkColor: Colors.white,
                                            materialTapTargetSize:
                                                MaterialTapTargetSize.shrinkWrap,
                                            visualDensity:
                                                VisualDensity.compact,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          'Rester connecté',
                                          style: GoogleFonts.inter(
                                            fontSize: 13.5,
                                            fontWeight: FontWeight.w400,
                                            color: const Color(0xFF64748B),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                GestureDetector(
                                  onTap: _connexionEnCours
                                      ? null
                                      : _motDePasseOublie,
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 4,
                                    ),
                                    child: Text(
                                      'Mot de passe oublié ?',
                                      style: GoogleFonts.inter(
                                        fontSize: 13.5,
                                        fontWeight: FontWeight.w600,
                                        color: const Color(0xFFFF7417),
                                        decoration: TextDecoration.underline,
                                        decorationColor: const Color(0xFFFF7417),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 24),

                            // Bouton principal Se connecter
                            Container(
                              width: double.infinity,
                              height: 52,
                              decoration: BoxDecoration(
                                color: const Color(0xFF000000),
                                borderRadius: BorderRadius.circular(14),
                                boxShadow: const [
                                  BoxShadow(
                                    color: Color(0x386366F1),
                                    blurRadius: 22,
                                    offset: Offset(0, 8),
                                    spreadRadius: 0,
                                  ),
                                  BoxShadow(
                                    color: Color(0x18000000),
                                    blurRadius: 10,
                                    offset: Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(14),
                                  onTap:
                                      _connexionEnCours ? null : _seConnecter,
                                  child: Center(
                                    child: _connexionEnCours
                                        ? const SizedBox.square(
                                            dimension: 22,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2.5,
                                              color: Colors.white,
                                            ),
                                          )
                                        : Text(
                                            'Se connecter',
                                            style: GoogleFonts.inter(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w700,
                                              color: Colors.white,
                                            ),
                                          ),
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
              );
            },
          ),
        ),
      ),
    );
  }

  static String? _champObligatoire(String? valeur) {
    if (valeur == null || valeur.trim().isEmpty) {
      return 'Ce champ est obligatoire';
    }
    return null;
  }

  static String? _emailValide(String? valeur) {
    final erreur = _champObligatoire(valeur);
    if (erreur != null) return erreur;
    final email = valeur!.trim();
    if (!RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(email)) {
      return 'Entrez une adresse e-mail valide';
    }
    return null;
  }

  static String? _identifiantValide(String? valeur) {
    final identifiant = valeur?.trim() ?? '';
    if (identifiant.isEmpty) return 'Ce champ est obligatoire';
    return identifiant.contains('@')
        ? _emailValide(identifiant)
        : _matriculeValide(identifiant);
  }

  static String? _matriculeValide(String? valeur) {
    final erreur = _champObligatoire(valeur);
    if (erreur != null) return erreur;
    if (valeur!.trim().length < 3) return 'Entrez un matricule valide';
    return null;
  }

  String? _motDePasseValide(String? valeur) =>
      _erreurMotDePasse ?? _champObligatoire(valeur);

  Future<void> _motDePasseOublie() async {
    final identifiant = _identifiant.text.trim();
    final erreur = _identifiantValide(identifiant);
    if (erreur != null) {
      setState(() => _erreurIdentifiant = erreur);
      return;
    }

    final confirmation = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Mot de passe oublié ?'),
        content: Text(
          'Un lien de réinitialisation sera envoyé pour « $identifiant ».',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Envoyer'),
          ),
        ],
      ),
    );
    if (confirmation != true || !mounted) return;

    try {
      await _sourceAuthentification.demanderReinitialisation(identifiant);
      if (!mounted) return;
      _afficherMessage('Le lien de réinitialisation a été envoyé.');
    } on ErreurApi catch (erreur) {
      if (!mounted) return;
      _afficherMessage(erreur.message, erreur: true);
    } catch (_) {
      if (!mounted) return;
      _afficherMessage(
        'Impossible de contacter le serveur. Vérifiez votre connexion internet.',
        erreur: true,
      );
    }
  }

  void _afficherMessage(String message, {bool erreur = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        backgroundColor: erreur
            ? const Color(0xFFB3261E)
            : const Color(0xFF16803C),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: Text(message),
      ),
    );
  }

  static bool _erreurConcerneIdentifiant(ErreurApi erreur) {
    final message = erreur.message.toLowerCase();
    return message.contains('identifiant') ||
        message.contains('email') ||
        message.contains('e-mail') ||
        message.contains('matricule');
  }

  static bool _erreurReseau(ErreurApi erreur) => const {
    'DELAI_DEPASSE',
    'SERVEUR_INJOIGNABLE',
    'SERVEUR_NGROK_HORS_LIGNE',
    'URL_API_ABSENTE',
    'REPONSE_INVALIDE',
  }.contains(erreur.code);

  static String _messageErreurConnexion(ErreurApi erreur) {
    if (erreur.code == 'DELAI_DEPASSE') {
      return 'Vérifiez votre connexion internet.';
    }
    if (erreur.code == 'SERVEUR_INJOIGNABLE' ||
        erreur.code == 'SERVEUR_NGROK_HORS_LIGNE') {
      return 'Impossible de se connecter';
    }
    final message = erreur.message.toLowerCase();
    if ((erreur.code == 'CONNEXION_REFUSEE' ||
            erreur.code == 'HTTP_401' ||
            erreur.code == 'HTTP_403') &&
        (message.contains('password') ||
            message.contains('mot de passe') ||
            message.contains('credential'))) {
      return 'Identifiant ou mot de passe incorrect.';
    }
    if (erreur.code == 'CONNEXION_REFUSEE' ||
        erreur.code == 'HTTP_401' ||
        erreur.code == 'HTTP_403') {
      return 'Identifiant ou mot de passe incorrect.';
    }
    if (erreur.code == 'CONNEXION_REFUSEE' &&
        (message.contains('email') ||
            message.contains('e-mail') ||
            message.contains('identifiant'))) {
      return 'Identifiant incorrect.';
    }
    return erreur.message.isEmpty
        ? 'Identifiant ou mot de passe incorrect.'
        : erreur.message;
  }
}
