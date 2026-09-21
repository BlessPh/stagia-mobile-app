import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class CarteStageExplorer extends StatelessWidget {
  const CarteStageExplorer({
    required this.initiale,
    required this.couleurFondInitiale,
    required this.couleurTexteInitiale,
    required this.nomEntreprise,
    required this.ville,
    required this.titrePoste,
    required this.domaineTag,
    required this.dureeTag,
    required this.dateLimite,
    this.estFavori = false,
    this.onFavoriTap,
    this.onPostuler,
    super.key,
  });

  final String initiale;
  final Color couleurFondInitiale;
  final Color couleurTexteInitiale;
  final String nomEntreprise;
  final String ville;
  final String titrePoste;
  final String domaineTag;
  final String dureeTag;
  final String dateLimite;
  final bool estFavori;
  final VoidCallback? onFavoriTap;
  final VoidCallback? onPostuler;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x06000000),
            blurRadius: 12,
            offset: Offset(0, 3),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // En-tête : Initiale + Entreprise/Ville + Signet
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Badge Initiale
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: couleurFondInitiale,
                  borderRadius: BorderRadius.circular(12),
                ),
                alignment: Alignment.center,
                child: Text(
                  initiale,
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: couleurTexteInitiale,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Nom entreprise & Ville
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      nomEntreprise,
                      style: GoogleFonts.inter(
                        fontSize: 15.5,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      ville,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFF94A3B8),
                      ),
                    ),
                  ],
                ),
              ),
              // Bouton Signet
              GestureDetector(
                onTap: onFavoriTap,
                child: Icon(
                  estFavori ? CupertinoIcons.bookmark_fill : CupertinoIcons.bookmark,
                  color: const Color(0xFF2563EB),
                  size: 22,
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          // Titre du poste / stage
          Text(
            titrePoste,
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF0F172A),
            ),
          ),

          const SizedBox(height: 12),

          // Tags (Domaine & Durée)
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: const Color(0xFFE0F2FE),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  domaineTag,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF0284C7),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Row(
                children: [
                  const Icon(
                    CupertinoIcons.clock,
                    size: 14,
                    color: Color(0xFF64748B),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    dureeTag,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 14),

          // Ligne de séparation
          const Divider(height: 1, color: Color(0xFFF1F5F9)),

          const SizedBox(height: 12),

          // Footer : Limite + Bouton Postuler
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Limite : $dateLimite',
                style: GoogleFonts.inter(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFF94A3B8),
                ),
              ),
              GestureDetector(
                onTap: onPostuler,
                child: Text(
                  'Postuler',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF1D61F2),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
