import 'dart:io';
import 'package:alert_info/alert_info.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../../core/services/photo_profil_service.dart';
import '../../../../core/services/preferences_application_service.dart';
import '../../../../core/widgets/contenu_adaptatif.dart';
import '../../data/models/etudiant_profil.dart';
import '../pages/modifier_informations_personnelles_page.dart';

class SectionParametresProfil extends StatefulWidget {
  const SectionParametresProfil({super.key, this.profil});

  final EtudiantProfil? profil;

  @override
  State<SectionParametresProfil> createState() =>
      _SectionParametresProfilState();
}

class _SectionParametresProfilState extends State<SectionParametresProfil> {
  late EtudiantProfil _profil;

  @override
  void initState() {
    super.initState();
    _profil = widget.profil ?? EtudiantProfil.vide();
  }

  void _ouvrirInformationsPersonnelles() async {
    final resultat = await Navigator.of(context, rootNavigator: true)
        .push<EtudiantProfil>(
          MaterialPageRoute(
            builder: (_) =>
                ModifierInformationsPersonnellesPage(profil: _profil),
          ),
        );
    if (resultat != null && mounted) {
      setState(() => _profil = resultat);
    }
  }

  void _ouvrirChangerMotDePasse() {
    final motDePasseActuelController = TextEditingController();
    final nouveauMotDePasseController = TextEditingController();
    final confirmationController = TextEditingController();
    bool masqueActuel = true;
    bool masqueNouveau = true;

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Padding(
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
                'Changer le mot de passe',
                style: GoogleFonts.inter(
                  fontSize: 19,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Mettez à jour vos identifiants pour sécuriser votre compte.',
                style: GoogleFonts.inter(
                  fontSize: 13.5,
                  color: const Color(0xFF64748B),
                ),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: motDePasseActuelController,
                obscureText: masqueActuel,
                decoration: InputDecoration(
                  labelText: 'Mot de passe actuel',
                  prefixIcon: const Icon(Icons.lock_outline_rounded),
                  suffixIcon: IconButton(
                    icon: Icon(
                      masqueActuel
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                    ),
                    onPressed: () =>
                        setSheetState(() => masqueActuel = !masqueActuel),
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: nouveauMotDePasseController,
                obscureText: masqueNouveau,
                decoration: InputDecoration(
                  labelText: 'Nouveau mot de passe',
                  prefixIcon: const Icon(Icons.lock_reset_rounded),
                  suffixIcon: IconButton(
                    icon: Icon(
                      masqueNouveau
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                    ),
                    onPressed: () =>
                        setSheetState(() => masqueNouveau = !masqueNouveau),
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: confirmationController,
                obscureText: masqueNouveau,
                decoration: InputDecoration(
                  labelText: 'Confirmer le nouveau mot de passe',
                  prefixIcon: const Icon(Icons.check_circle_outline_rounded),
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
                    final actuel = motDePasseActuelController.text;
                    final nouveau = nouveauMotDePasseController.text;
                    final confirmation = confirmationController.text;

                    if (actuel.isEmpty ||
                        nouveau.isEmpty ||
                        confirmation.isEmpty) {
                      AlertInfo.show(
                        context: context,
                        text: 'Veuillez remplir tous les champs.',
                        typeInfo: TypeInfo.warning,
                      );
                      return;
                    }

                    if (nouveau != confirmation) {
                      AlertInfo.show(
                        context: context,
                        text: 'Les nouveaux mots de passe ne correspondent pas.',
                        typeInfo: TypeInfo.error,
                      );
                      return;
                    }

                    Navigator.pop(ctx);
                    AlertInfo.show(
                      context: context,
                      text: 'Mot de passe modifié avec succès.',
                      typeInfo: TypeInfo.success,
                    );
                  },
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF1D61FF),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: const Text('Mettre à jour le mot de passe'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _ouvrirParametresNotifications() {
    showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        final preferences = ctx.watch<PreferencesApplicationService>();
        return Padding(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
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
                'Notifications',
                style: GoogleFonts.inter(
                  fontSize: 19,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Gérez la façon dont STAGIA vous informe.',
                style: GoogleFonts.inter(
                  fontSize: 13.5,
                  color: const Color(0xFF64748B),
                ),
              ),
              const SizedBox(height: 16),
              SwitchListTile.adaptive(
                contentPadding: EdgeInsets.zero,
                title: const Text('Toutes les notifications'),
                subtitle: const Text('Recevoir les alertes importantes.'),
                value: preferences.notificationsAutorisees,
                activeThumbColor: Colors.white,
                activeTrackColor: const Color(0xFF1D61FF),
                onChanged: (val) {
                  ctx
                      .read<PreferencesApplicationService>()
                      .autoriserNotifications(val);
                },
              ),
              const Divider(height: 1),
              SwitchListTile.adaptive(
                contentPadding: EdgeInsets.zero,
                title: const Text('Offres et candidatures'),
                subtitle: const Text('Suivi des réponses des entreprises.'),
                value: preferences.notificationsAutorisees,
                activeThumbColor: Colors.white,
                activeTrackColor: const Color(0xFF1D61FF),
                onChanged: (val) {
                  ctx
                      .read<PreferencesApplicationService>()
                      .autoriserNotifications(val);
                },
              ),
              const Divider(height: 1),
              SwitchListTile.adaptive(
                contentPadding: EdgeInsets.zero,
                title: const Text('Rappels du carnet de stage'),
                subtitle: const Text('Rappels pour compléter vos activités.'),
                value: preferences.notificationsAutorisees,
                activeThumbColor: Colors.white,
                activeTrackColor: const Color(0xFF1D61FF),
                onChanged: (val) {
                  ctx
                      .read<PreferencesApplicationService>()
                      .autoriserNotifications(val);
                },
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: FilledButton(
                  onPressed: () => Navigator.pop(ctx),
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF1D61FF),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('Fermer'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _ouvrirAPropos() {
    showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFCBD5E1),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: const Color(0xFF1D61FF),
                borderRadius: BorderRadius.circular(18),
              ),
              child: const Icon(
                Icons.school_rounded,
                color: Colors.white,
                size: 36,
              ),
            ),
            const SizedBox(height: 14),
            Text(
              'STAGIA Mobile',
              style: GoogleFonts.inter(
                fontSize: 20,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Version 1.0.0 (Build 2026.1)',
              style: GoogleFonts.inter(
                fontSize: 13.5,
                color: const Color(0xFF64748B),
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Plateforme numérique complète pour la gestion, le suivi et la validation des stages académiques et professionnels.',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 14,
                color: const Color(0xFF64748B),
                height: 1.45,
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: FilledButton(
                onPressed: () => Navigator.pop(ctx),
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF1D61FF),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Fermer'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _ouvrirAideFaq() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.92,
        minChildSize: 0.5,
        expand: false,
        builder: (ctx, scrollController) => Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
          child: ListView(
            controller: scrollController,
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
              const SizedBox(height: 18),
              Text(
                'Aide & Questions fréquentes',
                style: GoogleFonts.inter(
                  fontSize: 19,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Retrouvez les réponses à vos questions courantes.',
                style: GoogleFonts.inter(
                  fontSize: 13.5,
                  color: const Color(0xFF64748B),
                ),
              ),
              const SizedBox(height: 18),
              const _ElementFaq(
                question: 'Comment postuler à une offre de stage ?',
                reponse:
                    'Rendez-vous dans l\'onglet "Stages", sélectionnez l\'offre qui vous intéresse et appuyez sur "Postuler". Vous pourrez y joindre votre CV et lettre de motivation.',
              ),
              const _ElementFaq(
                question: 'Comment valider les présences au stage ?',
                reponse:
                    'Dans votre carnet de stage, enregistrez vos présences quotidiennes ou hebdomadaires. Votre encadreur recevra une notification pour signature.',
              ),
              const _ElementFaq(
                question: 'Comment modifier mes informations académiques ?',
                reponse:
                    'Accédez à votre profil puis cliquez sur "Informations académiques" pour mettre à jour votre établissement, filière et cycle.',
              ),
              const _ElementFaq(
                question: 'Qui contacter en cas de problème technique ?',
                reponse:
                    'Envoyez un e-mail à support@stagia.app ou contactez le bureau des stages de votre faculté.',
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _confirmerDesactivation() {
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
                'Désactiver le compte ?',
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
        content: Text(
          'Attention : la désactivation suspendra l\'accès à toutes vos candidatures, conventions et carnets de stage.',
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
              AlertInfo.show(
                context: context,
                text: 'Demande de désactivation envoyée.',
                typeInfo: TypeInfo.warning,
              );
            },
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
            ),
            child: const Text('Désactiver'),
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

    final nomAffiche = _profil.nomComplet.trim().isNotEmpty
        ? _profil.nomComplet
        : 'Alfred Daniel';

    final roleAffiche = _profil.filiere.trim().isNotEmpty
        ? _profil.filiere
        : 'Product/UI Designer';

    final preferences = context.watch<PreferencesApplicationService>();

    return Scaffold(
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
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Paramètres',
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
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 36),
          children: [
            // 1. CARTE PROFIL RÉSUMÉ
            AnimatedBuilder(
              animation: PhotoProfilService.instance,
              builder: (context, _) {
                final cheminPhoto = PhotoProfilService.instance.cheminPhoto;
                final photoValide =
                    cheminPhoto != null && File(cheminPhoto).existsSync();

                return Container(
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
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(22),
                      onTap: _ouvrirInformationsPersonnelles,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                        child: Row(
                          children: [
                            // Avatar circulaire 3D
                            Container(
                              width: 58,
                              height: 58,
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                color: Color(0xFFD4B28C),
                              ),
                              child: ClipOval(
                                child: photoValide
                                    ? Image.file(
                                        File(cheminPhoto),
                                        width: 58,
                                        height: 58,
                                        fit: BoxFit.cover,
                                      )
                                    : Image.asset(
                                        'assets/images/avatar_etudiant.jpg',
                                        width: 58,
                                        height: 58,
                                        fit: BoxFit.cover,
                                        errorBuilder:
                                            (context, error, stackTrace) =>
                                                const Icon(
                                          Icons.person,
                                          size: 36,
                                          color: Colors.white,
                                        ),
                                      ),
                              ),
                            ),
                            const SizedBox(width: 14),
                            // Nom et rôle
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    nomAffiche,
                                    style: GoogleFonts.inter(
                                      fontSize: 16.5,
                                      fontWeight: FontWeight.w700,
                                      color: texteCouleur,
                                      letterSpacing: -0.2,
                                    ),
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    roleAffiche,
                                    style: GoogleFonts.inter(
                                      fontSize: 13.5,
                                      fontWeight: FontWeight.w400,
                                      color: const Color(0xFF8F9BB3),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Icon(
                              Icons.chevron_right_rounded,
                              size: 22,
                              color: Color(0xFF8F9BB3),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),

            // 2. TITRE DE SECTION "AUTRES PARAMÈTRES"
            Padding(
              padding: const EdgeInsets.only(top: 24, bottom: 10, left: 4),
              child: Text(
                'AUTRES PARAMÈTRES',
                style: GoogleFonts.inter(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF8F9BB3),
                  letterSpacing: 0.6,
                ),
              ),
            ),

            // 3. PREMIER GROUPE DE PARAMÈTRES
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
                  _LigneParametre(
                    icone: Icons.person_outline_rounded,
                    titre: 'Informations personnelles',
                    onTap: _ouvrirInformationsPersonnelles,
                  ),
                  Divider(
                    height: 1,
                    indent: 54,
                    endIndent: 16,
                    color: separateurCouleur,
                  ),
                  _LigneParametre(
                    icone: Icons.lock_outline_rounded,
                    titre: 'Mot de passe',
                    onTap: _ouvrirChangerMotDePasse,
                  ),
                  Divider(
                    height: 1,
                    indent: 54,
                    endIndent: 16,
                    color: separateurCouleur,
                  ),
                  _LigneParametre(
                    icone: Icons.notifications_none_rounded,
                    titre: 'Notifications',
                    onTap: _ouvrirParametresNotifications,
                  ),
                  Divider(
                    height: 1,
                    indent: 54,
                    endIndent: 16,
                    color: separateurCouleur,
                  ),
                  _LigneParametreSwitch(
                    icone: Icons.dark_mode_outlined,
                    titre: 'Mode sombre',
                    valeur: preferences.modeSombre,
                    onChanged: (valeur) {
                      context
                          .read<PreferencesApplicationService>()
                          .activerModeSombre(valeur);
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: 18),

            // 4. SECOND GROUPE DE PARAMÈTRES
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
                  _LigneParametre(
                    icone: Icons.info_outline_rounded,
                    titre: 'A propos application',
                    onTap: _ouvrirAPropos,
                  ),
                  Divider(
                    height: 1,
                    indent: 54,
                    endIndent: 16,
                    color: separateurCouleur,
                  ),
                  _LigneParametre(
                    icone: Icons.help_outline_rounded,
                    titre: 'Aide/FAQ',
                    onTap: _ouvrirAideFaq,
                  ),
                  Divider(
                    height: 1,
                    indent: 54,
                    endIndent: 16,
                    color: separateurCouleur,
                  ),
                  _LigneParametre(
                    icone: Icons.delete_outline_rounded,
                    couleurIcone: const Color(0xFFEF4444),
                    titre: 'Désactiver mon compte',
                    couleurTexte: const Color(0xFFEF4444),
                    onTap: _confirmerDesactivation,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Ligne de paramètre interactive avec icône, titre et chevron
class _LigneParametre extends StatelessWidget {
  const _LigneParametre({
    required this.icone,
    required this.titre,
    required this.onTap,
    this.couleurIcone,
    this.couleurTexte,
  });

  final IconData icone;
  final String titre;
  final VoidCallback onTap;
  final Color? couleurIcone;
  final Color? couleurTexte;

  @override
  Widget build(BuildContext context) {
    final modeSombre = Theme.of(context).brightness == Brightness.dark;
    final defautIcone = modeSombre ? Colors.white : const Color(0xFF1E293B);
    final defautTexte = modeSombre ? Colors.white : const Color(0xFF1E293B);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
          child: Row(
            children: [
              Icon(
                icone,
                size: 22,
                color: couleurIcone ?? defautIcone,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  titre,
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: couleurTexte ?? defautTexte,
                  ),
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                size: 20,
                color: Color(0xFF8F9BB3),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Ligne de paramètre avec basculeur Switch (pour le mode sombre)
class _LigneParametreSwitch extends StatelessWidget {
  const _LigneParametreSwitch({
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
              activeTrackColor: const Color(0xFF1D61FF),
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

/// Élément dépliable pour la FAQ
class _ElementFaq extends StatelessWidget {
  const _ElementFaq({
    required this.question,
    required this.reponse,
  });

  final String question;
  final String reponse;

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        tilePadding: EdgeInsets.zero,
        title: Text(
          question,
          style: GoogleFonts.inter(
            fontSize: 14.5,
            fontWeight: FontWeight.w600,
          ),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Text(
              reponse,
              style: GoogleFonts.inter(
                fontSize: 13.5,
                color: const Color(0xFF64748B),
                height: 1.45,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
