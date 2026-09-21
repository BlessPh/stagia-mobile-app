import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class LecteurVocalWidget extends StatefulWidget {
  const LecteurVocalWidget({
    required this.duree,
    required this.estMien,
    super.key,
  });

  final Duration duree;
  final bool estMien;

  @override
  State<LecteurVocalWidget> createState() => _LecteurVocalWidgetState();
}

class _LecteurVocalWidgetState extends State<LecteurVocalWidget> {
  bool _enLecture = false;

  void _basculerLecture() {
    setState(() => _enLecture = !_enLecture);
  }

  @override
  Widget build(BuildContext context) {
    final couleurPrimaire = widget.estMien ? Colors.white : const Color(0xFF1D61F2);
    final couleurSecondaire = widget.estMien
        ? Colors.white.withValues(alpha: 0.4)
        : const Color(0xFFCBD5E1);

    final dureeSecondes = widget.duree.inSeconds;
    final minutes = (dureeSecondes ~/ 60).toString();
    final secondes = (dureeSecondes % 60).toString().padLeft(2, '0');
    final tempsFormatte = '$minutes:$secondes';

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Bouton Lecture / Pause
        GestureDetector(
          onTap: _basculerLecture,
          child: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: widget.estMien
                  ? Colors.white.withValues(alpha: 0.2)
                  : const Color(0xFF1D61F2).withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Icon(
                _enLecture ? Icons.pause_rounded : Icons.play_arrow_rounded,
                color: couleurPrimaire,
                size: 22,
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),

        // Ondes sonores stylisées
        Expanded(
          child: SizedBox(
            height: 28,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: List.generate(22, (index) {
                // Hauteurs dynamiques stylisées
                final hauteurs = [
                  8.0, 14.0, 20.0, 10.0, 24.0, 16.0, 12.0, 22.0, 18.0, 26.0,
                  14.0, 8.0, 20.0, 16.0, 24.0, 12.0, 18.0, 22.0, 14.0, 10.0,
                  16.0, 8.0,
                ];
                final active = _enLecture && (index < 12);
                return Container(
                  width: 2.8,
                  height: hauteurs[index % hauteurs.length],
                  decoration: BoxDecoration(
                    color: active ? couleurPrimaire : couleurSecondaire,
                    borderRadius: BorderRadius.circular(2),
                  ),
                );
              }),
            ),
          ),
        ),
        const SizedBox(width: 10),

        // Timer
        Text(
          tempsFormatte,
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: widget.estMien
                ? Colors.white.withValues(alpha: 0.9)
                : const Color(0xFF64748B),
          ),
        ),
      ],
    );
  }
}
