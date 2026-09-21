import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../domain/entities/message_chat.dart';
import 'apercu_reponse_widget.dart';

class BarreSaisieChat extends StatelessWidget {
  const BarreSaisieChat({
    required this.controleur,
    required this.onEnvoyerTexte,
    required this.onEnvoyerVocal,
    required this.onOuvrirPiecesJointes,
    this.messageEnReponse,
    this.onAnnulerReponse,
    this.focusNode,
    super.key,
  });

  final TextEditingController controleur;
  final ValueChanged<String> onEnvoyerTexte;
  final VoidCallback onEnvoyerVocal;
  final VoidCallback onOuvrirPiecesJointes;
  final MessageChat? messageEnReponse;
  final VoidCallback? onAnnulerReponse;
  final FocusNode? focusNode;

  @override
  Widget build(BuildContext context) {
    final modeSombre = Theme.of(context).brightness == Brightness.dark;
    final fondBarre = modeSombre ? const Color(0xFF1E1E1E) : Colors.white;
    final bordureBarre = modeSombre ? const Color(0xFF2D3748) : const Color(0xFFE2E8F0);
    final fondChamp = modeSombre ? const Color(0xFF262626) : const Color(0xFFF1F5F9);

    return Container(
      decoration: BoxDecoration(
        color: fondBarre,
        border: Border(
          top: BorderSide(color: bordureBarre, width: 1),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Bandeau de réponse si un message est cité
            if (messageEnReponse != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                child: ApercuReponseWidget(
                  message: messageEnReponse!,
                  onAnnuler: onAnnulerReponse,
                ),
              ),

            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  // Bouton pièces jointes (+)
                  IconButton(
                    icon: const Icon(
                      Icons.add_circle_outline_rounded,
                      color: Color(0xFF1D61F2),
                      size: 26,
                    ),
                    tooltip: 'Ajouter une pièce jointe',
                    onPressed: onOuvrirPiecesJointes,
                    visualDensity: VisualDensity.compact,
                  ),

                  // Champ de saisie
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: fondChamp,
                        borderRadius: BorderRadius.circular(22),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Expanded(
                            child: TextField(
                              controller: controleur,
                              focusNode: focusNode,
                              maxLines: 4,
                              minLines: 1,
                              textCapitalization: TextCapitalization.sentences,
                              style: GoogleFonts.inter(
                                fontSize: 14.5,
                                color: modeSombre
                                    ? Colors.white
                                    : const Color(0xFF0F172A),
                              ),
                              decoration: InputDecoration(
                                isDense: true,
                                border: InputBorder.none,
                                enabledBorder: InputBorder.none,
                                focusedBorder: InputBorder.none,
                                contentPadding: const EdgeInsets.symmetric(
                                  vertical: 10,
                                ),
                                hintText: 'Écrire un message...',
                                hintStyle: GoogleFonts.inter(
                                  fontSize: 14,
                                  color: const Color(0xFF94A3B8),
                                ),
                              ),
                            ),
                          ),
                          // Bouton emoji
                          IconButton(
                            icon: const Icon(
                              Icons.sentiment_satisfied_alt_rounded,
                              color: Color(0xFF94A3B8),
                              size: 22,
                            ),
                            onPressed: () {
                              final texte = controleur.text;
                              controleur.text = '$texte 😊';
                              controleur.selection = TextSelection.fromPosition(
                                TextPosition(offset: controleur.text.length),
                              );
                            },
                            visualDensity: VisualDensity.compact,
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(
                              minWidth: 32,
                              minHeight: 38,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),

                  // Bouton Micro ou Envoyer
                  ValueListenableBuilder<TextEditingValue>(
                    valueListenable: controleur,
                    builder: (context, value, _) {
                      final aDuTexte = value.text.trim().isNotEmpty;
                      return GestureDetector(
                        onTap: () {
                          if (aDuTexte) {
                            final texte = controleur.text.trim();
                            controleur.clear();
                            onEnvoyerTexte(texte);
                          } else {
                            onEnvoyerVocal();
                          }
                        },
                        child: Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            color: const Color(0xFF1D61F2),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF1D61F2).withValues(alpha: 0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: Center(
                            child: Icon(
                              aDuTexte
                                  ? Icons.send_rounded
                                  : Icons.mic_rounded,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                        ),
                      );
                    },
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
