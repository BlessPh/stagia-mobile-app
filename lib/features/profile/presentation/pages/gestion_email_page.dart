import 'package:alert_info/alert_info.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/widgets/contenu_adaptatif.dart';

class GestionEmailPage extends StatefulWidget {
  const GestionEmailPage({
    super.key,
    required this.email,
  });

  final String email;

  @override
  State<GestionEmailPage> createState() => _GestionEmailPageState();
}

class _GestionEmailPageState extends State<GestionEmailPage> {
  late String _emailActuel;
  bool _notifEmail = true;
  bool _newsletter = false;
  bool _alertesSecurite = true;

  @override
  void initState() {
    super.initState();
    _emailActuel = widget.email.trim().isNotEmpty
        ? widget.email
        : 'alfred.daniel@gmail.com';
  }

  void _ouvrirModifierEmail() {
    final controleur = TextEditingController(text: _emailActuel);
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(
          24,
          20,
          24,
          32 + MediaQuery.of(ctx).viewInsets.bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFCBD5E1),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              "Modifier l'adresse e-mail",
              style: GoogleFonts.inter(
                fontSize: 19,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Un code de vérification vous sera envoyé pour valider la nouvelle adresse.',
              style: GoogleFonts.inter(
                fontSize: 13.5,
                color: const Color(0xFF64748B),
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: controleur,
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(
                labelText: 'Nouvelle adresse e-mail',
                prefixIcon: const Icon(Icons.mail_outline_rounded),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: FilledButton(
                onPressed: () {
                  final saisie = controleur.text.trim();
                  if (saisie.isEmpty || !saisie.contains('@')) {
                    AlertInfo.show(
                      context: context,
                      text: 'Veuillez saisir une adresse e-mail valide.',
                      typeInfo: TypeInfo.warning,
                    );
                    return;
                  }
                  setState(() => _emailActuel = saisie);
                  Navigator.pop(ctx);
                  AlertInfo.show(
                    context: context,
                    text: 'Adresse e-mail mise à jour avec succès.',
                    typeInfo: TypeInfo.success,
                  );
                },
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFFE86311),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: const Text('Enregistrer'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmerSuppression() {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFFEE2E2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.warning_amber_rounded,
                color: Color(0xFFEF4444),
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                "Supprimer l'e-mail ?",
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
        content: Text(
          "Êtes-vous sûr de vouloir supprimer votre adresse e-mail ? Vous ne recevrez plus d'alertes concernant vos stages.",
          style: GoogleFonts.inter(
            fontSize: 14,
            color: const Color(0xFF64748B),
            height: 1.4,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              setState(() => _emailActuel = '');
              AlertInfo.show(
                context: context,
                text: 'Adresse e-mail supprimée.',
                typeInfo: TypeInfo.warning,
              );
            },
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
            ),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final modeSombre = Theme.of(context).brightness == Brightness.dark;
    final fondPage =
        modeSombre ? const Color(0xFF0F172A) : const Color(0xFFF4F5F7);
    final fondCarte = modeSombre ? const Color(0xFF1E293B) : Colors.white;
    final texteCouleur = modeSombre ? Colors.white : const Color(0xFF1E293B);
    final separateurCouleur =
        modeSombre ? const Color(0xFF334155) : const Color(0xFFF1F5F9);
    const orangeAccent = Color(0xFFE86311);

    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, result) {
        // Retourne la nouvelle adresse lors du retour
      },
      child: Scaffold(
        backgroundColor: fondPage,
        appBar: AppBar(
          backgroundColor: fondPage,
          elevation: 0,
          surfaceTintColor: Colors.transparent,
          centerTitle: true,
          leading: IconButton(
            icon: Icon(
              Icons.arrow_back_ios_new_rounded,
              size: 20,
              color: texteCouleur,
            ),
            onPressed: () => Navigator.of(context).pop(_emailActuel),
          ),
          title: Text(
            'Adresse e-mail',
            style: GoogleFonts.inter(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: texteCouleur,
              letterSpacing: -0.3,
            ),
          ),
        ),
        body: ContenuAdaptatif(
          largeurMaximale: 520,
          enfant: ListView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 36),
            children: [
              // 1. CARTE E-MAIL
              Container(
                decoration: BoxDecoration(
                  color: fondCarte,
                  borderRadius: BorderRadius.circular(22),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x06000000),
                      blurRadius: 12,
                      offset: Offset(0, 3),
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Ligne supérieure : Label, email et badge Vérifié
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'E-MAIL',
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFF8F9BB3),
                                  letterSpacing: 0.5,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                _emailActuel.isEmpty
                                    ? 'Non renseignée'
                                    : _emailActuel,
                                style: GoogleFonts.inter(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: texteCouleur,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (_emailActuel.isNotEmpty)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFDCFCE7),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.check_rounded,
                                  size: 14,
                                  color: Color(0xFF16A34A),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'Vérifié',
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: const Color(0xFF16A34A),
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                    Divider(height: 28, color: separateurCouleur),

                    // Ligne d'action : Modifier l'adresse e-mail ->
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: _ouvrirModifierEmail,
                        borderRadius: BorderRadius.circular(8),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                "Modifier l'adresse e-mail",
                                style: GoogleFonts.inter(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: orangeAccent,
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Icon(
                                Icons.arrow_forward_rounded,
                                size: 18,
                                color: orangeAccent,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // 2. TITRE DE SECTION PRÉFÉRENCES
              Padding(
                padding: const EdgeInsets.only(top: 26, bottom: 10, left: 4),
                child: Text(
                  'PRÉFÉRENCES',
                  style: GoogleFonts.inter(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF8F9BB3),
                    letterSpacing: 0.6,
                  ),
                ),
              ),

              // 3. CARTE PRÉFÉRENCES (SWITCHES)
              Container(
                decoration: BoxDecoration(
                  color: fondCarte,
                  borderRadius: BorderRadius.circular(22),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x06000000),
                      blurRadius: 12,
                      offset: Offset(0, 3),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    _LigneSwitchEmail(
                      icone: Icons.notifications_none_rounded,
                      titre: 'Notifications par e-mail',
                      valeur: _notifEmail,
                      onChanged: (val) => setState(() => _notifEmail = val),
                    ),
                    Divider(
                      height: 1,
                      indent: 54,
                      endIndent: 16,
                      color: separateurCouleur,
                    ),
                    _LigneSwitchEmail(
                      icone: Icons.mail_outline_rounded,
                      titre: 'Newsletter et promotions',
                      valeur: _newsletter,
                      onChanged: (val) => setState(() => _newsletter = val),
                    ),
                    Divider(
                      height: 1,
                      indent: 54,
                      endIndent: 16,
                      color: separateurCouleur,
                    ),
                    _LigneSwitchEmail(
                      icone: Icons.shield_outlined,
                      titre: 'Alertes de sécurité',
                      valeur: _alertesSecurite,
                      onChanged: (val) =>
                          setState(() => _alertesSecurite = val),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 36),

              // 4. ACTION : SUPPRIMER MON ADRESSE E-MAIL
              Center(
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: _confirmerSuppression,
                    borderRadius: BorderRadius.circular(12),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.delete_outline_rounded,
                            size: 19,
                            color: Color(0xFFEF4444),
                          ),
                          const SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              'Supprimer mon adresse e-mail',
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFFEF4444),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Ligne de switch personnalisée assortie à la maquette
class _LigneSwitchEmail extends StatelessWidget {
  const _LigneSwitchEmail({
    required this.icone,
    required this.titre,
    required this.valeur,
    required this.onChanged,
  });

  final IconData icone;
  final String titre;
  final bool valeur;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final modeSombre = Theme.of(context).brightness == Brightness.dark;
    final texteCouleur = modeSombre ? Colors.white : const Color(0xFF1E293B);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          Icon(
            icone,
            size: 22,
            color: texteCouleur,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              titre,
              style: GoogleFonts.inter(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: texteCouleur,
              ),
            ),
          ),
          Transform.scale(
            scale: 0.85,
            child: Switch.adaptive(
              value: valeur,
              activeThumbColor: Colors.white,
              activeTrackColor: const Color(0xFFE86311),
              inactiveThumbColor: Colors.white,
              inactiveTrackColor: const Color(0xFFE2E8F0),
              trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
              onChanged: onChanged,
            ),
          ),
        ],
      ),
    );
  }
}
