import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';

class BarreRechercheMessagerie extends StatelessWidget {
  const BarreRechercheMessagerie({
    required this.controleur,
    required this.onChanged,
    this.onClear,
    super.key,
  });

  final TextEditingController controleur;
  final ValueChanged<String> onChanged;
  final VoidCallback? onClear;

  @override
  Widget build(BuildContext context) {
    final modeSombre = Theme.of(context).brightness == Brightness.dark;
    final fondBarre = modeSombre ? const Color(0xFF1E293B) : Colors.white;
    final bordureCouleur = modeSombre ? const Color(0xFF334155) : const Color(0xFFE2E8F0);
    final texteCouleur = modeSombre ? Colors.white : const Color(0xFF0F172A);
    final sousTexteCouleur = modeSombre ? const Color(0xFFCBD5E1) : const Color(0xFF94A3B8);

    return Container(
      height: 48,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: fondBarre,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: bordureCouleur),
        boxShadow: [
          BoxShadow(
            color: modeSombre ? const Color(0x30000000) : const Color(0x05000000),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Icon(
            Iconsax.search_normal_1,
            color: sousTexteCouleur,
            size: 19,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: controleur,
              onChanged: onChanged,
              style: GoogleFonts.inter(
                fontSize: 14.5,
                fontWeight: FontWeight.w500,
                color: texteCouleur,
              ),
              decoration: InputDecoration(
                filled: true,
                fillColor: fondBarre,
                hintText: 'Rechercher une discussion, un encadreur...',
                hintStyle: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  color: const Color(0xFF94A3B8),
                ),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),
          if (controleur.text.isNotEmpty)
            GestureDetector(
              onTap: () {
                controleur.clear();
                if (onClear != null) {
                  onClear!();
                } else {
                  onChanged('');
                }
              },
              child: Padding(
                padding: const EdgeInsets.only(left: 6),
                child: Icon(
                  Icons.close_rounded,
                  color: sousTexteCouleur,
                  size: 18,
                ),
              ),
            ),
        ],
      ),
    );
  }
}


