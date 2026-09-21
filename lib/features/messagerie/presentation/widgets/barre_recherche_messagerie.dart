import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

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
    final fond = modeSombre ? const Color(0xFF1E1E1E) : const Color(0xFFF1F5F9);
    final bordure = modeSombre ? const Color(0xFF2D3748) : const Color(0xFFE2E8F0);

    return Container(
      height: 44,
      decoration: BoxDecoration(
        color: fond,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: bordure, width: 1),
      ),
      child: TextField(
        controller: controleur,
        onChanged: onChanged,
        style: GoogleFonts.inter(
          fontSize: 14,
          color: modeSombre ? Colors.white : const Color(0xFF0F172A),
        ),
        decoration: InputDecoration(
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          hintText: 'Rechercher une discussion, un encadreur...',
          hintStyle: GoogleFonts.inter(
            fontSize: 13.5,
            color: const Color(0xFF94A3B8),
          ),
          prefixIcon: const Icon(
            Icons.search_rounded,
            color: Color(0xFF94A3B8),
            size: 20,
          ),
          suffixIcon: controleur.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(
                    Icons.close_rounded,
                    color: Color(0xFF94A3B8),
                    size: 18,
                  ),
                  onPressed: () {
                    controleur.clear();
                    if (onClear != null) {
                      onClear!();
                    } else {
                      onChanged('');
                    }
                  },
                )
              : null,
        ),
      ),
    );
  }
}
