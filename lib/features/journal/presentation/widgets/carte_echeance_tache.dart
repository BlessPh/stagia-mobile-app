import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class CarteEcheanceTache extends StatelessWidget {
  const CarteEcheanceTache({
    required this.horaireTexte,
    required this.sousHoraireTexte,
    required this.tagLibelle,
    required this.tagCouleurFond,
    required this.tagCouleurTexte,
    required this.titre,
    this.onTap,
    super.key,
  });

  final String horaireTexte;
  final String sousHoraireTexte;
  final String tagLibelle;
  final Color tagCouleurFond;
  final Color tagCouleurTexte;
  final String titre;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFE2E8F0)),
            boxShadow: const [
              BoxShadow(
                color: Color(0x05000000),
                blurRadius: 10,
                offset: Offset(0, 2),
              ),
            ],
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Bloc Horaire à gauche
              SizedBox(
                width: 72,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      horaireTexte,
                      style: GoogleFonts.inter(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      sousHoraireTexte,
                      style: GoogleFonts.inter(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFF94A3B8),
                      ),
                    ),
                  ],
                ),
              ),

              // Séparateur vertical fin
              Container(
                width: 1,
                height: 36,
                color: const Color(0xFFF1F5F9),
                margin: const EdgeInsets.symmetric(horizontal: 12),
              ),

              // Contenu principal (Tag + Titre)
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3.5,
                      ),
                      decoration: BoxDecoration(
                        color: tagCouleurFond,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        tagLibelle.toUpperCase(),
                        style: GoogleFonts.inter(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w800,
                          color: tagCouleurTexte,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      titre,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF0F172A),
                        height: 1.25,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
