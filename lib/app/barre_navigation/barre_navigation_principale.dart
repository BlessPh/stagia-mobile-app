import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_theme.dart';
import '../../features/journal/presentation/pages/saisir_journal_page.dart';

class BarreNavigationPrincipale extends StatelessWidget {
  const BarreNavigationPrincipale({
    required this.indexActuel,
    required this.onDestinationSelectionnee,
    this.onAjouter,
    super.key,
  });

  final int indexActuel;
  final ValueChanged<int> onDestinationSelectionnee;
  final VoidCallback? onAjouter;

  static const _destinations = [
    _DestinationNavigation(
      libelle: 'Accueil',
      icone: Icons.home_outlined,
      iconeSelectionnee: Icons.home_rounded,
    ),
    _DestinationNavigation(
      libelle: 'Stages',
      icone: Icons.work_outline_rounded,
      iconeSelectionnee: Icons.work_rounded,
    ),
    _DestinationNavigation(
      libelle: 'Journal',
      icone: Icons.menu_book_outlined,
      iconeSelectionnee: Icons.menu_book_rounded,
    ),
    _DestinationNavigation(
      libelle: 'Profil',
      icone: Icons.person_outline_rounded,
      iconeSelectionnee: Icons.person_rounded,
    ),
  ];

  void _declencherAjout(BuildContext context) {
    if (onAjouter != null) {
      onAjouter!();
    } else {
      Navigator.of(context, rootNavigator: true).push(
        MaterialPageRoute<void>(
          builder: (_) => const SaisirJournalPage(),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final modeSombre = Theme.of(context).brightness == Brightness.dark;
    final bottomPadding = MediaQuery.paddingOf(context).bottom;
    const barHeight = 64.0;
    const protrusion = 18.0;
    final totalHeight = barHeight + protrusion + bottomPadding;

    // Couleurs distinctes selon le mode clair / sombre
    final fondBarre = modeSombre ? const Color(0xFF1E2129) : Colors.white;
    final couleurBordure = modeSombre ? const Color(0xFF2C3240) : const Color(0xFFF1F5F9);
    final ombreBarre = modeSombre
        ? const Color(0x60000000)
        : const Color(0x14000000);

    return SizedBox(
      height: totalHeight,
      width: double.infinity,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.bottomCenter,
        children: [
          // 1. Fond collé en bas avec coins arrondis et ombre
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            height: barHeight + bottomPadding,
            child: Container(
              decoration: BoxDecoration(
                color: fondBarre,
                border: Border(
                  top: BorderSide(
                    color: couleurBordure,
                    width: 1.0,
                  ),
                ),
                boxShadow: [
                  BoxShadow(
                    color: ombreBarre,
                    blurRadius: 18,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              padding: EdgeInsets.only(bottom: bottomPadding),
              child: Row(
                children: [
                  Expanded(child: _buildItem(0, context, modeSombre)),
                  Expanded(child: _buildItem(1, context, modeSombre)),
                  Expanded(
                    child: InkWell(
                      onTap: () => _declencherAjout(context),
                      splashColor: Colors.transparent,
                      highlightColor: Colors.transparent,
                      child: const SizedBox.expand(),
                    ),
                  ),
                  Expanded(child: _buildItem(2, context, modeSombre)),
                  Expanded(child: _buildItem(3, context, modeSombre)),
                ],
              ),
            ),
          ),

          // 2. Cinquième élément flottant au milieu avec une icône "+"
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Center(
              child: Semantics(
                button: true,
                label: 'Ajouter ou actions rapides',
                child: Material(
                  color: Colors.transparent,
                  shape: const CircleBorder(),
                  child: InkWell(
                    onTap: () => _declencherAjout(context),
                    customBorder: const CircleBorder(),
                    child: Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        gradient: modeSombre
                            ? const LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  Color(0xFFFF7417),
                                  Color(0xFFE85D00),
                                ],
                              )
                            : null,
                        color: modeSombre ? null : AppTheme.noir,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: modeSombre
                              ? const Color(0xFF1E2129)
                              : Colors.white,
                          width: 3.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: modeSombre
                                ? const Color(0x66FF7417)
                                : const Color(0x38000000),
                            blurRadius: modeSombre ? 14 : 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.add_rounded,
                          color: Colors.white,
                          size: 30,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItem(int index, BuildContext context, bool modeSombre) {
    final destination = _destinations[index];
    final selectionnee = index == indexActuel;
    final couleurActive = modeSombre
        ? const Color(0xFFFF944D)
        : AppTheme.orangePrincipal;
    final couleurInactive = modeSombre
        ? const Color(0xFF94A3B8)
        : const Color(0xFF475569);

    return Semantics(
      selected: selectionnee,
      label: destination.libelle,
      button: true,
      child: InkWell(
        onTap: () => onDestinationSelectionnee(index),
        splashColor: couleurActive.withValues(alpha: 0.12),
        highlightColor: Colors.transparent,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              selectionnee ? destination.iconeSelectionnee : destination.icone,
              size: 22,
              color: selectionnee ? couleurActive : couleurInactive,
            ),
            const SizedBox(height: 3),
            Text(
              destination.libelle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.inter(
                color: selectionnee ? couleurActive : couleurInactive,
                fontSize: 11,
                fontWeight: selectionnee ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
            const SizedBox(height: 3),
            // Point indicateur actif sous le texte
            AnimatedOpacity(
              duration: const Duration(milliseconds: 200),
              opacity: selectionnee ? 1.0 : 0.0,
              child: Container(
                width: 4,
                height: 4,
                decoration: BoxDecoration(
                  color: couleurActive,
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DestinationNavigation {
  const _DestinationNavigation({
    required this.libelle,
    required this.icone,
    required this.iconeSelectionnee,
  });

  final String libelle;
  final IconData icone;
  final IconData iconeSelectionnee;
}
