import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../domain/entities/message_chat.dart';
import 'apercu_reponse_widget.dart';

class BarreSaisieChat extends StatefulWidget {
  const BarreSaisieChat({
    required this.controleur,
    required this.onEnvoyerTexte,
    required this.onEnvoyerVocal,
    required this.onOuvrirPiecesJointes,
    required this.onBasculerEmojis,
    this.messageEnReponse,
    this.onAnnulerReponse,
    this.focusNode,
    this.afficherEmojis = false,
    super.key,
  });

  final TextEditingController controleur;
  final ValueChanged<String> onEnvoyerTexte;
  final void Function(Duration duree) onEnvoyerVocal;
  final VoidCallback onOuvrirPiecesJointes;
  final VoidCallback onBasculerEmojis;
  final MessageChat? messageEnReponse;
  final VoidCallback? onAnnulerReponse;
  final FocusNode? focusNode;
  final bool afficherEmojis;

  @override
  State<BarreSaisieChat> createState() => _BarreSaisieChatState();
}

class _BarreSaisieChatState extends State<BarreSaisieChat>
    with SingleTickerProviderStateMixin {
  bool _enTrainDEnregistrer = false;
  int _secondesEnregistrement = 0;
  Timer? _minuteur;
  late AnimationController _pulsationController;
  late Animation<double> _pulsationAnimation;

  @override
  void initState() {
    super.initState();
    _pulsationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _pulsationAnimation = Tween<double>(begin: 0.85, end: 1.25).animate(
      CurvedAnimation(parent: _pulsationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _minuteur?.cancel();
    _pulsationController.dispose();
    super.dispose();
  }

  Future<void> _demarrerEnregistrement() async {
    // Vérifier / Demander la permission à l'utilisateur
    final autorise = await _demanderPermissionMicrophone();
    if (!autorise) return;

    if (!mounted) return;
    setState(() {
      _enTrainDEnregistrer = true;
      _secondesEnregistrement = 0;
    });
    _minuteur?.cancel();
    _minuteur = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _secondesEnregistrement++;
        });
      }
    });
  }

  Future<bool> _demanderPermissionMicrophone() async {
    // Dialogue de confirmation de permission microphone
    final modeSombre = Theme.of(context).brightness == Brightness.dark;
    final res = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: modeSombre ? const Color(0xFF1E293B) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFFF751F).withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.mic_rounded,
                color: Color(0xFFFF751F),
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Accès au microphone',
                style: GoogleFonts.inter(
                  fontSize: 16.5,
                  fontWeight: FontWeight.w700,
                  color: modeSombre ? Colors.white : const Color(0xFF0F172A),
                ),
              ),
            ),
          ],
        ),
        content: Text(
          'STAGIA a besoin de votre permission pour accéder au microphone afin d\'enregistrer et d\'envoyer vos messages vocaux à vos encadreurs.',
          style: GoogleFonts.inter(
            fontSize: 14,
            height: 1.45,
            color: modeSombre ? const Color(0xFFCBD5E1) : const Color(0xFF475569),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(
              'Refuser',
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: modeSombre ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
              ),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF751F),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(
              'Autoriser',
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );

    return res == true;
  }

  void _annulerEnregistrement() {
    _minuteur?.cancel();
    setState(() {
      _enTrainDEnregistrer = false;
      _secondesEnregistrement = 0;
    });
  }

  void _validerEtEnvoyerVocal() {
    _minuteur?.cancel();
    final duree = Duration(seconds: _secondesEnregistrement > 0 ? _secondesEnregistrement : 1);
    setState(() {
      _enTrainDEnregistrer = false;
      _secondesEnregistrement = 0;
    });
    widget.onEnvoyerVocal(duree);
  }

  String _formaterTemps(int totalSecs) {
    final minutes = (totalSecs ~/ 60).toString().padLeft(2, '0');
    final secondes = (totalSecs % 60).toString().padLeft(2, '0');
    return '$minutes:$secondes';
  }

  @override
  Widget build(BuildContext context) {
    final modeSombre = Theme.of(context).brightness == Brightness.dark;
    final fondBarre = modeSombre ? const Color(0xFF0F172A) : Colors.white;
    final bordureBarre = modeSombre ? const Color(0xFF334155) : const Color(0xFFE2E8F0);
    final fondChamp = fondBarre;
    final bordureChamp = modeSombre ? const Color(0xFF334155) : const Color(0xFFE2E8F0);
    final iconeCouleur = modeSombre ? const Color(0xFFCBD5E1) : const Color(0xFF64748B);

    return Container(
      decoration: BoxDecoration(
        color: fondBarre,
        border: Border(
          top: BorderSide(color: bordureBarre, width: 1),
        ),
        boxShadow: [
          BoxShadow(
            color: modeSombre ? const Color(0x33000000) : Colors.black.withValues(alpha: 0.03),
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
            if (widget.messageEnReponse != null && !_enTrainDEnregistrer)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                child: ApercuReponseWidget(
                  message: widget.messageEnReponse!,
                  onAnnuler: widget.onAnnulerReponse,
                ),
              ),

            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Mode Enregistrement audio en cours
                  if (_enTrainDEnregistrer) ...[
                    // Bouton corbeille / annuler
                    IconButton(
                      icon: const Icon(
                        Icons.delete_outline_rounded,
                        color: Color(0xFFEF4444),
                        size: 26,
                      ),
                      tooltip: 'Annuler l\'enregistrement',
                      onPressed: _annulerEnregistrement,
                      visualDensity: VisualDensity.compact,
                    ),

                    // Indicateur d'enregistrement actif et durée
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: modeSombre ? const Color(0xFF1E293B) : const Color(0xFFFEE2E2).withValues(alpha: 0.4),
                          borderRadius: BorderRadius.circular(22),
                          border: Border.all(
                            color: const Color(0xFFEF4444).withValues(alpha: 0.35),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            ScaleTransition(
                              scale: _pulsationAnimation,
                              child: Container(
                                width: 11,
                                height: 11,
                                decoration: const BoxDecoration(
                                  color: Color(0xFFEF4444),
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Text(
                              _formaterTemps(_secondesEnregistrement),
                              style: GoogleFonts.inter(
                                fontSize: 14.5,
                                fontWeight: FontWeight.w600,
                                color: modeSombre ? Colors.white : const Color(0xFF0F172A),
                              ),
                            ),
                            const Spacer(),
                            Text(
                              'Enregistrement...',
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                color: const Color(0xFFEF4444),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),

                    // Bouton d'envoi audio (l'icône micro s'est transformée en icône envoi)
                    GestureDetector(
                      onTap: _validerEtEnvoyerVocal,
                      child: Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: const Color(0xFFFF751F),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFFF751F).withValues(alpha: 0.35),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: const Center(
                          child: Icon(
                            Icons.send_rounded,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      ),
                    ),
                  ] else ...[
                    // Bouton pièces jointes (+)
                    IconButton(
                      icon: Icon(
                        Icons.add_circle_outline_rounded,
                        color: iconeCouleur,
                        size: 26,
                      ),
                      tooltip: 'Ajouter une pièce jointe',
                      onPressed: widget.onOuvrirPiecesJointes,
                      visualDensity: VisualDensity.compact,
                    ),

                    // Champ de saisie
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          color: fondChamp,
                          borderRadius: BorderRadius.circular(22),
                          border: Border.all(
                            color: bordureChamp,
                            width: 1,
                          ),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Expanded(
                              child: TextField(
                                controller: widget.controleur,
                                focusNode: widget.focusNode,
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
                                  filled: true,
                                  fillColor: fondChamp,
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
                              icon: Icon(
                                widget.afficherEmojis
                                    ? Icons.keyboard_rounded
                                    : Icons.sentiment_satisfied_alt_rounded,
                                color: widget.afficherEmojis
                                    ? const Color(0xFFFF751F)
                                    : iconeCouleur,
                                size: 22,
                              ),
                              tooltip: widget.afficherEmojis ? 'Clavier' : 'Émojis',
                              onPressed: widget.onBasculerEmojis,
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
                      valueListenable: widget.controleur,
                      builder: (context, value, _) {
                        final aDuTexte = value.text.trim().isNotEmpty;
                        return GestureDetector(
                          onTap: () {
                            if (aDuTexte) {
                              final texte = widget.controleur.text.trim();
                              widget.controleur.clear();
                              widget.onEnvoyerTexte(texte);
                            } else {
                              _demarrerEnregistrement();
                            }
                          },
                          child: Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: const Color(0xFFFF751F),
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFFFF751F).withValues(alpha: 0.35),
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
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
