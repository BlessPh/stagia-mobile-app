import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/network/client_api_http.dart';
import '../../../../core/network/reponse_api.dart';
import '../../data/datasources/source_authentification_distante.dart';
import '../widgets/champ_authentification.dart';

class MotDePasseOubliePage extends StatefulWidget {
  const MotDePasseOubliePage({super.key});

  @override
  State<MotDePasseOubliePage> createState() => _MotDePasseOubliePageState();
}

class _MotDePasseOubliePageState extends State<MotDePasseOubliePage> {
  final _cleFormulaire = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _sourceAuthentification = SourceAuthentificationDistante(
    ClientApiHttp(),
  );

  bool _chargement = false;
  String? _erreur;
  bool _emailEnvoye = false;

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  Future<void> _envoyerDemande() async {
    setState(() => _erreur = null);
    if (!(_cleFormulaire.currentState?.validate() ?? false)) return;

    FocusScope.of(context).unfocus();
    setState(() => _chargement = true);

    try {
      await _sourceAuthentification.demanderReinitialisation(
        _email.text.trim(),
      );
      if (!mounted) return;
      setState(() => _emailEnvoye = true);
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
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF1E293B)),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: _emailEnvoye ? _buildSucces() : _buildFormulaire(),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFormulaire() {
    return Form(
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
              Icons.lock_reset_rounded,
              color: Color(0xFFFF7417),
              size: 32,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Mot de passe oublié ?',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 26,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Entrez votre adresse e-mail. Vous recevrez un lien de réinitialisation sécurisé pour définir votre nouveau mot de passe.',
            style: GoogleFonts.inter(
              fontSize: 14,
              color: const Color(0xFF64748B),
              height: 1.45,
            ),
          ),
          const SizedBox(height: 32),
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
                  const Icon(Icons.error_outline_rounded, color: Color(0xFFDC2626), size: 20),
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
            libelle: 'Adresse e-mail',
            indication: 'ex: etudiant@domaine.cd',
            controleur: _email,
            icone: Icons.email_outlined,
            typeClavier: TextInputType.emailAddress,
            actionClavier: TextInputAction.done,
            validateur: (v) {
              if (v == null || v.trim().isEmpty) {
                return 'Veuillez saisir votre adresse e-mail';
              }
              final emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
              if (!emailRegex.hasMatch(v.trim())) {
                return 'Veuillez saisir une adresse e-mail valide';
              }
              return null;
            },
          ),
          const SizedBox(height: 28),
          SizedBox(
            height: 52,
            child: FilledButton(
              onPressed: _chargement ? null : _envoyerDemande,
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
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : Text(
                      'Envoyer le lien',
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
    );
  }

  Widget _buildSucces() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          width: 72,
          height: 72,
          decoration: const BoxDecoration(
            color: Color(0xFFDCFCE7),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.mark_email_read_outlined,
            color: Color(0xFF16A34A),
            size: 38,
          ),
        ),
        const SizedBox(height: 24),
        Text(
          'Vérifiez votre boîte de réception',
          textAlign: TextAlign.center,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF0F172A),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Si un compte actif correspond à « ${_email.text.trim()} », un e-mail avec un lien direct de réinitialisation a été envoyé.\n\nCliquez sur ce lien depuis votre téléphone pour ouvrir automatiquement l\'application et définir votre nouveau mot de passe.',
          style: GoogleFonts.inter(
            fontSize: 14,
            color: const Color(0xFF64748B),
            height: 1.5,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 32),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(
            'Retour à la connexion',
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: const Color(0xFFFF7417),
            ),
          ),
        ),
      ],
    );
  }
}
