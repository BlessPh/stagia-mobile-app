import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_theme.dart';

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
      _afficherActionsRapidesParDefaut(context);
    }
  }

  void _afficherActionsRapidesParDefaut(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (modalContext) => _MenuAjoutRapideModal(
        onOptionChoisie: (index) {
          onDestinationSelectionnee(index);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.paddingOf(context).bottom;
    const barHeight = 64.0;
    const protrusion = 18.0;
    final totalHeight = barHeight + protrusion + bottomPadding;

    return SizedBox(
      height: totalHeight,
      width: double.infinity,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.bottomCenter,
        children: [
          // 1. Fond blanc collé en bas avec coins arrondis en haut et ombre douce
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            height: barHeight + bottomPadding,
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Color(0x14000000),
                    blurRadius: 18,
                    offset: Offset(0, -4),
                  ),
                ],
              ),
              padding: EdgeInsets.only(bottom: bottomPadding),
              child: Row(
                children: [
                  Expanded(child: _buildItem(0, context)),
                  Expanded(child: _buildItem(1, context)),
                  Expanded(
                    child: InkWell(
                      onTap: () => _declencherAjout(context),
                      splashColor: Colors.transparent,
                      highlightColor: Colors.transparent,
                      child: const SizedBox.expand(),
                    ),
                  ),
                  Expanded(child: _buildItem(2, context)),
                  Expanded(child: _buildItem(3, context)),
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
                      decoration: const BoxDecoration(
                        color: AppTheme.noir,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Color(0x38000000),
                            blurRadius: 12,
                            offset: Offset(0, 5),
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

  Widget _buildItem(int index, BuildContext context) {
    final destination = _destinations[index];
    final selectionnee = index == indexActuel;
    const couleurActive = AppTheme.orangePrincipal;
    const couleurInactive = AppTheme.noir;

    return Semantics(
      selected: selectionnee,
      label: destination.libelle,
      button: true,
      child: InkWell(
        onTap: () => onDestinationSelectionnee(index),
        splashColor: couleurActive.withValues(alpha: 0.08),
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
                decoration: const BoxDecoration(
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

class _MenuAjoutRapideModal extends StatelessWidget {
  const _MenuAjoutRapideModal({required this.onOptionChoisie});

  final ValueChanged<int> onOptionChoisie;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(
        20,
        14,
        20,
        MediaQuery.paddingOf(context).bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 42,
            height: 4,
            decoration: BoxDecoration(
              color: const Color(0xFFE2E8F0),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 18),
          Text(
            'Actions rapides',
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppTheme.noir,
            ),
          ),
          const SizedBox(height: 16),
          _TuileAction(
            icone: Icons.edit_note_rounded,
            titre: 'Nouvelle entrée au journal',
            sousTitre: 'Rédiger une activité ou tâche de stage',
            couleurFond: const Color(0xFFFFF4EC),
            couleurIcone: AppTheme.orangePrincipal,
            onTap: () {
              Navigator.pop(context);
              onOptionChoisie(2);
            },
          ),
          const SizedBox(height: 10),
          _TuileAction(
            icone: Icons.work_outline_rounded,
            titre: 'Découvrir les offres de stages',
            sousTitre: 'Parcourir les opportunités et postuler',
            couleurFond: const Color(0xFFF1F5F9),
            couleurIcone: AppTheme.noir,
            onTap: () {
              Navigator.pop(context);
              onOptionChoisie(1);
            },
          ),
        ],
      ),
    );
  }
}

class _TuileAction extends StatelessWidget {
  const _TuileAction({
    required this.icone,
    required this.titre,
    required this.sousTitre,
    required this.couleurFond,
    required this.couleurIcone,
    required this.onTap,
  });

  final IconData icone;
  final String titre;
  final String sousTitre;
  final Color couleurFond;
  final Color couleurIcone;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: couleurFond,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icone, color: couleurIcone, size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      titre,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.noir,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      sousTitre,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: const Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                color: Color(0xFF94A3B8),
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
