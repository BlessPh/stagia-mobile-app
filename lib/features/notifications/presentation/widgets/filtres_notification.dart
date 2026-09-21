import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

enum FiltreNotification {
  toutes,
  nonLues,
  stages,
  messages,
}

class FiltresNotificationBar extends StatelessWidget {
  const FiltresNotificationBar({
    required this.filtreActuel,
    required this.onChangerFiltre,
    required this.compteNonLues,
    super.key,
  });

  final FiltreNotification filtreActuel;
  final ValueChanged<FiltreNotification> onChangerFiltre;
  final int compteNonLues;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          _PuceFiltre(
            label: 'Toutes',
            selectionne: filtreActuel == FiltreNotification.toutes,
            onTap: () => onChangerFiltre(FiltreNotification.toutes),
          ),
          const SizedBox(width: 8),
          _PuceFiltre(
            label: 'Non lues',
            badge: compteNonLues > 0 ? '$compteNonLues' : null,
            selectionne: filtreActuel == FiltreNotification.nonLues,
            onTap: () => onChangerFiltre(FiltreNotification.nonLues),
          ),
          const SizedBox(width: 8),
          _PuceFiltre(
            label: 'Stages',
            selectionne: filtreActuel == FiltreNotification.stages,
            onTap: () => onChangerFiltre(FiltreNotification.stages),
          ),
          const SizedBox(width: 8),
          _PuceFiltre(
            label: 'Messages',
            selectionne: filtreActuel == FiltreNotification.messages,
            onTap: () => onChangerFiltre(FiltreNotification.messages),
          ),
        ],
      ),
    );
  }
}

class _PuceFiltre extends StatelessWidget {
  const _PuceFiltre({
    required this.label,
    required this.selectionne,
    required this.onTap,
    this.badge,
  });

  final String label;
  final bool selectionne;
  final VoidCallback onTap;
  final String? badge;

  @override
  Widget build(BuildContext context) {
    final modeSombre = Theme.of(context).brightness == Brightness.dark;

    final fond = selectionne
        ? const Color(0xFFFF7417)
        : (modeSombre ? const Color(0xFF202020) : Colors.white);

    final texteCouleur = selectionne
        ? Colors.white
        : (modeSombre ? const Color(0xFFE2E8F0) : const Color(0xFF475569));

    final bordure = selectionne
        ? Colors.transparent
        : (modeSombre ? const Color(0xFF334155) : const Color(0xFFE2E8F0));

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: fond,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: bordure, width: 1),
            boxShadow: selectionne
                ? [
                    BoxShadow(
                      color: const Color(0xFFFF7417).withValues(alpha: 0.25),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: GoogleFonts.inter(
                  color: texteCouleur,
                  fontSize: 13,
                  fontWeight: selectionne ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
              if (badge != null) ...[
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                  decoration: BoxDecoration(
                    color: selectionne ? Colors.white : const Color(0xFFFF7417),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    badge!,
                    style: GoogleFonts.inter(
                      color: selectionne ? const Color(0xFFFF7417) : Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
