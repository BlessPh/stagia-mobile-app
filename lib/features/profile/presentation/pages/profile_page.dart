import 'dart:io';
import 'package:alert_info/alert_info.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../app/routes/routes_application.dart';
import '../../../../core/network/client_api_http.dart';
import '../../../../core/network/source_etudiant_distante.dart';
import '../../../../core/services/photo_profil_service.dart';
import '../../../../core/services/session_authentification_service.dart';
import '../../../../core/widgets/contenu_adaptatif.dart';
import '../../../journal/presentation/pages/journal_page.dart';
import '../../../stage/presentation/pages/candidatures_stage_page.dart';
import '../../data/models/etudiant_profil.dart';
import '../widgets/section_dossier_profil.dart';
import '../widgets/section_parametres_profil.dart';
import 'modifier_informations_academiques_page.dart';
import 'gestion_email_page.dart';
import 'modifier_informations_personnelles_page.dart';
import 'notes_academiques_page.dart';
import 'parcours_academique_page.dart';
import '../../../planning/presentation/pages/planning_page.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final _source = SourceEtudiantDistante(ClientApiHttp());
  EtudiantProfil _profil = EtudiantProfil.vide();
  bool _chargement = true;
  bool _erreurChargement = false;
  late final ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _chargerProfil();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _chargerProfil() async {
    setState(() {
      _chargement = true;
      _erreurChargement = false;
    });
    try {
      final donnees = await _source.profil();
      final profilApi = EtudiantProfil.fromApi(donnees);
      final emailSession = await SessionAuthentificationService.email();
      final matriculeSession = await SessionAuthentificationService.matricule();
      if (!mounted) return;
      setState(
        () => _profil = profilApi.copyWith(
          email: profilApi.email.isEmpty ? emailSession : null,
          matricule: profilApi.matricule.isEmpty ? matriculeSession : null,
        ),
      );
    } catch (_) {
      if (mounted) setState(() => _erreurChargement = true);
    } finally {
      if (mounted) setState(() => _chargement = false);
    }
  }

  Future<void> _choisirPhoto() async {
    try {
      final fichiers = await FilePicker.pickFiles(type: FileType.image);
      if (!mounted || fichiers.isEmpty) return;

      final chemin = fichiers.first.path;
      if (chemin == null || !await File(chemin).exists()) {
        throw const FileSystemException('Image inaccessible');
      }

      await PhotoProfilService.instance.definirPhoto(chemin);
      if (!mounted) return;
      AlertInfo.show(
        context: context,
        text: 'Photo de profil importée avec succès.',
        typeInfo: TypeInfo.success,
      );
    } catch (_) {
      if (!mounted) return;
      AlertInfo.show(
        context: context,
        text: 'Impossible d’importer cette image.',
        typeInfo: TypeInfo.error,
      );
    }
  }

  Future<void> _ouvrirModificationPersonnelle() async {
    final resultat = await Navigator.of(context, rootNavigator: true)
        .push<EtudiantProfil>(
          MaterialPageRoute(
            builder: (_) =>
                ModifierInformationsPersonnellesPage(profil: _profil),
          ),
        );
    if (resultat != null && mounted) setState(() => _profil = resultat);
  }

  Future<void> _ouvrirModificationAcademique() async {
    final resultat = await Navigator.of(context, rootNavigator: true)
        .push<EtudiantProfil>(
          MaterialPageRoute(
            builder: (_) =>
                ModifierInformationsAcademiquesPage(profil: _profil),
          ),
        );
    if (resultat != null && mounted) setState(() => _profil = resultat);
  }

  void _ouvrirPage(String titre, Widget contenu) {
    Navigator.of(context, rootNavigator: true).push(
      MaterialPageRoute<void>(
        builder: (_) => Scaffold(
          appBar: AppBar(
            title: Text(
              titre,
              style: GoogleFonts.inter(fontWeight: FontWeight.w700),
            ),
          ),
          body: ContenuAdaptatif(largeurMaximale: 640, enfant: contenu),
        ),
      ),
    );
  }

  Future<void> _ouvrirGestionEmail() async {
    final nouvelEmail = await Navigator.of(context, rootNavigator: true)
        .push<String>(
          MaterialPageRoute(
            builder: (_) => GestionEmailPage(
              email: _profil.email,
            ),
          ),
        );
    if (nouvelEmail != null && mounted) {
      setState(() => _profil = _profil.copyWith(email: nouvelEmail));
    }
  }

  void _ouvrirHistoriqueStage() {
    Navigator.of(context, rootNavigator: true).push(
      MaterialPageRoute<void>(
        builder: (_) => const CandidaturesStagePage(),
      ),
    );
  }

  void _ouvrirCarnetNumerique() {
    Navigator.of(context, rootNavigator: true).push(
      MaterialPageRoute<void>(
        builder: (_) => Scaffold(
          appBar: AppBar(
            title: Text(
              'Carnet numérique',
              style: GoogleFonts.inter(fontWeight: FontWeight.w700),
            ),
          ),
          body: const JournalPage(),
        ),
      ),
    );
  }

  void _ouvrirPlanning() {
    Navigator.of(context, rootNavigator: true).push(
      MaterialPageRoute<void>(
        builder: (_) => const PlanningPage(),
      ),
    );
  }

  Future<void> _deconnecter() async {
    final confirmer = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Se déconnecter ?'),
        content: const Text('Voulez-vous vraiment quitter votre session ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
            ),
            child: const Text('Confirmer'),
          ),
        ],
      ),
    );
    if (confirmer == true && mounted) {
      await SessionAuthentificationService.supprimer();
      if (!mounted) return;
      Navigator.of(
        context,
        rootNavigator: true,
      ).pushNamedAndRemoveUntil(RoutesApplication.connexion, (_) => false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_chargement) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: Color(0xFF1D61FF)),
        ),
      );
    }
    if (_erreurChargement) {
      return Scaffold(
        body: Center(
          child: TextButton(
            onPressed: _chargerProfil,
            child: const Text('Chargement impossible · Réessayer'),
          ),
        ),
      );
    }

    final modeSombre = Theme.of(context).brightness == Brightness.dark;
    final fondPage = modeSombre ? const Color(0xFF0F172A) : const Color(0xFFF4F6FA);
    final fondCarte = modeSombre ? const Color(0xFF1E293B) : Colors.white;
    final texteCouleur = modeSombre ? Colors.white : const Color(0xFF1E293B);
    final separateurCouleur =
        modeSombre ? const Color(0xFF334155) : const Color(0xFFF1F5F9);

    final nomAffiche = _profil.nomComplet.trim().isNotEmpty
        ? _profil.nomComplet
        : 'Alfred KALONJI';

    final topPadding = MediaQuery.paddingOf(context).top;
    const double hauteurContenuEnTete = 224.0;
    final double hauteurEnTete = topPadding + hauteurContenuEnTete;

    return Scaffold(
      backgroundColor: fondPage,
      body: ContenuAdaptatif(
        largeurMaximale: 520,
        enfant: AnimatedBuilder(
          animation: Listenable.merge([
            PhotoProfilService.instance,
            _scrollController,
          ]),
          builder: (context, _) {
            final cheminPhoto = PhotoProfilService.instance.cheminPhoto;
            final photoValide =
                cheminPhoto != null && File(cheminPhoto).existsSync();
            final offset =
                _scrollController.hasClients ? _scrollController.offset : 0.0;
            final masquerAvatar =
                offset >= (hauteurEnTete - (topPadding + 164));
            final masquerBoutonParametres =
                offset >= (hauteurEnTete - (topPadding + 52));

            return _StackInteractif(
              children: [
                // En-tête fixe en arrière-plan (ClipPath, Avatar, Titre, Paramètres, Nom)
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: SizedBox(
                    height: hauteurEnTete + 24,
                    child: Stack(
                      children: [
                        // Fond bleu avec ClipPath et cercles décoratifs
                        ClipPath(
                          clipper: _ClipperFondBleuProfil(),
                          child: Container(
                            height: hauteurEnTete + 24,
                            width: double.infinity,
                            decoration: const BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  Color(0xFF1E60FF),
                                  Color(0xFF1757F2),
                                ],
                              ),
                            ),
                            child: Stack(
                              children: [
                                Positioned(
                                  left: -60,
                                  top: -40,
                                  child: Container(
                                    width: 200,
                                    height: 200,
                                    decoration: const BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: Color(0x18FFFFFF),
                                    ),
                                  ),
                                ),
                                Positioned(
                                  left: 35,
                                  top: 130,
                                  child: Container(
                                    width: 75,
                                    height: 75,
                                    decoration: const BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: Color(0x18FFFFFF),
                                    ),
                                  ),
                                ),
                                Positioned(
                                  right: 110,
                                  top: 55,
                                  child: Container(
                                    width: 55,
                                    height: 55,
                                    decoration: const BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: Color(0x14FFFFFF),
                                    ),
                                  ),
                                ),
                                Positioned(
                                  right: -50,
                                  top: 90,
                                  child: Container(
                                    width: 140,
                                    height: 140,
                                    decoration: const BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: Color(0x18FFFFFF),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        // Éléments d'en-tête (Titre, Bouton Paramètres, Avatar et Nom)
                        SafeArea(
                          bottom: false,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Padding(
                                padding:
                                    const EdgeInsets.fromLTRB(20, 12, 20, 0),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    Text(
                                      'Mon profil',
                                      style: GoogleFonts.inter(
                                        fontSize: 24,
                                        fontWeight: FontWeight.w800,
                                        color: Colors.white,
                                      ),
                                    ),
                                    IgnorePointer(
                                      ignoring: masquerBoutonParametres,
                                      child: Material(
                                        color: Colors.transparent,
                                        child: InkWell(
                                          onTap: () => Navigator.of(
                                              context,
                                              rootNavigator: true,
                                            ).push(
                                              MaterialPageRoute<void>(
                                                builder: (_) =>
                                                    SectionParametresProfil(
                                                  profil: _profil,
                                                ),
                                              ),
                                            ),
                                          borderRadius:
                                              BorderRadius.circular(20),
                                          child: Container(
                                            width: 40,
                                            height: 40,
                                            decoration: const BoxDecoration(
                                              color: Color(0x38FFFFFF),
                                              shape: BoxShape.circle,
                                            ),
                                            child: const Icon(
                                              Icons.settings_rounded,
                                              color: Colors.white,
                                              size: 22,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 14),

                              Center(
                                child: Column(
                                  children: [
                                    IgnorePointer(
                                      ignoring: masquerAvatar,
                                      child: GestureDetector(
                                        onTap: _choisirPhoto,
                                        child: Container(
                                          width: 98,
                                          height: 98,
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            color: const Color(0xFFD4B28C),
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors.black
                                                    .withValues(alpha: 0.18),
                                                blurRadius: 14,
                                                offset: const Offset(0, 4),
                                              ),
                                            ],
                                          ),
                                          child: ClipOval(
                                            child: photoValide
                                                ? Image.file(
                                                    File(cheminPhoto),
                                                    width: 98,
                                                    height: 98,
                                                    fit: BoxFit.cover,
                                                  )
                                                : Image.asset(
                                                    'assets/images/avatar_etudiant.jpg',
                                                    width: 98,
                                                    height: 98,
                                                    fit: BoxFit.cover,
                                                    errorBuilder: (context,
                                                            error,
                                                            stackTrace) =>
                                                        const Icon(
                                                      Icons.person,
                                                      size: 56,
                                                      color: Colors.white,
                                                    ),
                                                  ),
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    Text(
                                      nomAffiche,
                                      textAlign: TextAlign.center,
                                      style: GoogleFonts.inter(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w800,
                                        color: Colors.white,
                                        letterSpacing: -0.2,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Contenu défilable : la feuille de ListTiles qui glisse par-dessus l'en-tête
                ListView(
                  controller: _scrollController,
                  padding: EdgeInsets.zero,
                  physics: const ClampingScrollPhysics(),
                  children: [
                    // Espace transparent réservé pour laisser l'en-tête visible à l'état initial
                    SizedBox(height: hauteurEnTete),

                    // Feuille arrondie avec les menus
                    Container(
                      decoration: BoxDecoration(
                        color: fondPage,
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(28),
                          topRight: Radius.circular(28),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.08),
                            blurRadius: 16,
                            offset: const Offset(0, -4),
                          ),
                        ],
                      ),
                      padding: EdgeInsets.fromLTRB(
                        16,
                        16,
                        16,
                        32 + MediaQuery.paddingOf(context).bottom,
                      ),
                      child: Column(
                        children: [
                          // GROUPE 1: Informations personnelles & Adresse e-mail
                          _CarteMenuProfil(
                            couleurFond: fondCarte,
                            enfants: [
                              _ItemMenu(
                                icone: Icons.person_outline_rounded,
                                titre: 'Informations personnelles',
                                couleurTexte: texteCouleur,
                                onTap: _ouvrirModificationPersonnelle,
                              ),
                              Divider(height: 1, color: separateurCouleur),
                              _ItemMenu(
                                icone: Icons.mail_outline_rounded,
                                titre: 'Adresse e-mail',
                                couleurTexte: texteCouleur,
                                onTap: _ouvrirGestionEmail,
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),

                          // GROUPE 2: Informations académiques, Parcours, Notes
                          _CarteMenuProfil(
                            couleurFond: fondCarte,
                            enfants: [
                              _ItemMenu(
                                icone: Icons.school_outlined,
                                titre: 'Informations académiques',
                                couleurTexte: texteCouleur,
                                onTap: _ouvrirModificationAcademique,
                              ),
                              Divider(height: 1, color: separateurCouleur),
                              _ItemMenu(
                                icone: Icons.school_outlined,
                                titre: 'Parcours académique',
                                couleurTexte: texteCouleur,
                                onTap: () => Navigator.of(
                                  context,
                                  rootNavigator: true,
                                ).push(
                                  MaterialPageRoute<void>(
                                    builder: (_) => ParcoursAcademiquePage(
                                      profil: _profil,
                                    ),
                                  ),
                                ),
                              ),
                              Divider(height: 1, color: separateurCouleur),
                              _ItemMenu(
                                icone: Icons.assignment_outlined,
                                titre: 'Notes académique',
                                couleurTexte: texteCouleur,
                                onTap: () => Navigator.of(
                                  context,
                                  rootNavigator: true,
                                ).push(
                                  MaterialPageRoute<void>(
                                    builder: (_) =>
                                        const NotesAcademiquesPage(),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),

                          // GROUPE 3: Historique de stage, Carnet numérique, Planning, Rapports
                          _CarteMenuProfil(
                            couleurFond: fondCarte,
                            enfants: [
                              _ItemMenu(
                                icone: Icons.history_rounded,
                                titre: 'Historique de stage',
                                couleurTexte: texteCouleur,
                                onTap: _ouvrirHistoriqueStage,
                              ),
                              Divider(height: 1, color: separateurCouleur),
                              _ItemMenu(
                                icone: Icons.menu_book_rounded,
                                titre: 'Mon carnet numérique',
                                couleurTexte: texteCouleur,
                                onTap: _ouvrirCarnetNumerique,
                              ),
                              Divider(height: 1, color: separateurCouleur),
                              _ItemMenu(
                                icone: Icons.calendar_month_outlined,
                                titre: 'Mon planning',
                                couleurTexte: texteCouleur,
                                onTap: _ouvrirPlanning,
                              ),
                              Divider(height: 1, color: separateurCouleur),
                              _ItemMenu(
                                icone: Icons.description_outlined,
                                titre: 'Mes rapports',
                                couleurTexte: texteCouleur,
                                onTap: () => _ouvrirPage(
                                  'Mes rapports',
                                  const SectionDossierProfil(),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),

                          // BOUTON DÉCONNEXION
                          Container(
                            width: double.infinity,
                            height: 52,
                            decoration: BoxDecoration(
                              color: fondCarte,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: const Color(0xFFEF4444),
                                width: 1.3,
                              ),
                            ),
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                borderRadius: BorderRadius.circular(16),
                                onTap: _deconnecter,
                                child: Center(
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(
                                        Icons.logout_rounded,
                                        color: Color(0xFFEF4444),
                                        size: 20,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        'Déconnexion',
                                        style: GoogleFonts.inter(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w600,
                                          color: const Color(0xFFEF4444),
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
                  ],
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

/// ClipPath personnalisé pour découper le fond bleu supérieur avec une courbe douce
class _ClipperFondBleuProfil extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    path.lineTo(0, size.height - 24);
    path.quadraticBezierTo(
      size.width * 0.5,
      size.height + 4,
      size.width,
      size.height - 24,
    );
    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}

/// Carte blanche avec coins arrondis pour regrouper les options
class _CarteMenuProfil extends StatelessWidget {
  const _CarteMenuProfil({
    required this.enfants,
    required this.couleurFond,
  });

  final List<Widget> enfants;
  final Color couleurFond;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: couleurFond,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Color(0x08000000),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: enfants,
      ),
    );
  }
}

/// Élément individuel d'une carte menu avec icône, titre et chevron
class _ItemMenu extends StatelessWidget {
  const _ItemMenu({
    required this.icone,
    required this.titre,
    required this.couleurTexte,
    required this.onTap,
  });

  final IconData icone;
  final String titre;
  final Color couleurTexte;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
          child: Row(
            children: [
              Icon(
                icone,
                size: 20,
                color: couleurTexte,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  titre,
                  style: GoogleFonts.inter(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w500,
                    color: couleurTexte,
                  ),
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                size: 20,
                color: Color(0xFF94A3B8),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Stack personnalisé qui transmet les tests d'impact aux enfants d'arrière-plan
/// même si un défileur au premier plan couvre l'écran, tant que les zones cliquées
/// ne sont pas interceptées par le contenu opaque du premier plan.
class _StackInteractif extends Stack {
  const _StackInteractif({
    super.children,
  });

  @override
  RenderStack createRenderObject(BuildContext context) {
    return _RenderStackInteractif(
      alignment: alignment,
      textDirection: textDirection ?? Directionality.maybeOf(context),
      fit: fit,
      clipBehavior: clipBehavior,
    );
  }
}

class _RenderStackInteractif extends RenderStack {
  _RenderStackInteractif({
    super.alignment,
    super.textDirection,
    super.fit,
    super.clipBehavior,
  });

  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) {
    var isAnyHit = false;
    RenderBox? child = lastChild;
    while (child != null) {
      final childParentData = child.parentData! as StackParentData;
      final isHit = result.addWithPaintOffset(
        offset: childParentData.offset,
        position: position,
        hitTest: (BoxHitTestResult result, Offset transformed) {
          assert(transformed == position - childParentData.offset);
          return child!.hitTest(result, position: transformed);
        },
      );
      if (isHit) {
        isAnyHit = true;
      }
      child = childParentData.previousSibling;
    }
    return isAnyHit;
  }
}

