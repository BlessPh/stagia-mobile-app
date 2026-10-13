import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class BarreRechercheStages extends StatelessWidget {
  const BarreRechercheStages({
    this.controller,
    this.onChanged,
    this.hintText = 'Rechercher...',
    super.key,
  });

  final TextEditingController? controller;
  final ValueChanged<String>? onChanged;
  final String hintText;

  @override
  Widget build(BuildContext context) {
    final modeSombre = Theme.of(context).brightness == Brightness.dark;
    final fondBarre = modeSombre ? const Color(0xFF1E293B) : Colors.white;
    final bordureCouleur = modeSombre ? const Color(0xFF334155) : const Color(0xFFE2E8F0);
    final texteCouleur = modeSombre ? Colors.white : const Color(0xFF0F172A);
    final sousTexteCouleur = const Color(0xFF94A3B8);

    return Container(
      height: 48,
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
            CupertinoIcons.search,
            color: sousTexteCouleur,
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: controller,
              onChanged: onChanged,
              style: GoogleFonts.inter(
                fontSize: 14.5,
                fontWeight: FontWeight.w500,
                color: texteCouleur,
              ),
              decoration: InputDecoration(
                filled: true,
                fillColor: fondBarre,
                hintText: hintText,
                hintStyle: GoogleFonts.inter(
                  fontSize: 14.5,
                  fontWeight: FontWeight.w400,
                  color: sousTexteCouleur,
                ),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
