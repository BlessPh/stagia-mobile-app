import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../domain/entities/message_chat.dart';

class ApercuReponseWidget extends StatelessWidget {
  const ApercuReponseWidget({
    required this.message,
    this.onAnnuler,
    this.estDansBulle = false,
    this.estMien = false,
    super.key,
  });

  final MessageChat message;
  final VoidCallback? onAnnuler;
  final bool estDansBulle;
  final bool estMien;

  @override
  Widget build(BuildContext context) {
    final couleurBarre = estMien && estDansBulle
        ? Colors.white
        : const Color(0xFF1D61F2);

    final fond = estDansBulle
        ? (estMien
            ? Colors.white.withValues(alpha: 0.18)
            : const Color(0xFFE2E8F0).withValues(alpha: 0.6))
        : const Color(0xFFF1F5F9);

    final couleurAuteur = estDansBulle
        ? (estMien ? Colors.white : const Color(0xFF1D61F2))
        : const Color(0xFF1D61F2);

    final couleurTexte = estDansBulle
        ? (estMien ? Colors.white.withValues(alpha: 0.85) : const Color(0xFF475569))
        : const Color(0xFF475569);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: fond,
        borderRadius: BorderRadius.circular(8),
        border: Border(
          left: BorderSide(
            color: couleurBarre,
            width: 3.5,
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  message.expediteurNom,
                  style: GoogleFonts.inter(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    color: couleurAuteur,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  message.type == TypeMessage.vocal
                      ? '🎙️ Message vocal'
                      : message.type == TypeMessage.document
                      ? '📄 ${message.nomFichier ?? "Document"}'
                      : message.texte,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: couleurTexte,
                  ),
                ),
              ],
            ),
          ),
          if (onAnnuler != null)
            IconButton(
              icon: const Icon(Icons.close_rounded, size: 18),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
              onPressed: onAnnuler,
              color: const Color(0xFF94A3B8),
            ),
        ],
      ),
    );
  }
}
