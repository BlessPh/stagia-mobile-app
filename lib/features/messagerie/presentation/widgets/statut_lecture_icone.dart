import 'package:flutter/material.dart';
import '../../domain/entities/discussion.dart';

class StatutLectureIcone extends StatelessWidget {
  const StatutLectureIcone({
    required this.statut,
    this.estSurBulleBleue = false,
    this.taille = 14,
    super.key,
  });

  final StatutMessage statut;
  final bool estSurBulleBleue;
  final double taille;

  @override
  Widget build(BuildContext context) {
    final couleurLue = estSurBulleBleue
        ? const Color(0xFF93C5FD)
        : const Color(0xFF1D61F2);

    final couleurAttente = estSurBulleBleue
        ? Colors.white.withValues(alpha: 0.6)
        : const Color(0xFF94A3B8);

    switch (statut) {
      case StatutMessage.envoye:
        return Icon(
          Icons.check_rounded,
          size: taille,
          color: couleurAttente,
        );
      case StatutMessage.distribue:
        return Icon(
          Icons.done_all_rounded,
          size: taille,
          color: couleurAttente,
        );
      case StatutMessage.lu:
        return Icon(
          Icons.done_all_rounded,
          size: taille,
          color: couleurLue,
        );
    }
  }
}
