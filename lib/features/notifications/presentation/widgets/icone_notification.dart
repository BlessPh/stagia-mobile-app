import 'package:flutter/material.dart';

class IconeNotification extends StatelessWidget {
  const IconeNotification({
    required this.icone,
    required this.couleur,
    this.taille = 46,
    this.tailleIcone = 22,
    super.key,
  });

  final IconData icone;
  final Color couleur;
  final double taille;
  final double tailleIcone;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: taille,
      height: taille,
      decoration: BoxDecoration(
        color: couleur.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: couleur.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Center(
        child: Icon(
          icone,
          color: couleur,
          size: tailleIcone,
        ),
      ),
    );
  }
}
