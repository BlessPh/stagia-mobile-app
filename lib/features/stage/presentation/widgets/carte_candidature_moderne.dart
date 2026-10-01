import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

enum StatutCandidatureType {
  enAttente,
  entretien,
  refusee,
  acceptee,
  paiementRequis,
  confirme,
  admis,
}

class CarteCandidatureModerne extends StatelessWidget {
  const CarteCandidatureModerne({
    required this.initiale,
    required this.couleurFondInitiale,
    required this.couleurTexteInitiale,
    required this.nomEntreprise,
    required this.titrePoste,
    required this.dateTexte,
    required this.statutType,
    this.libelleStatutCustom,
    this.onTap,
    super.key,
  });

  final String initiale;
  final Color couleurFondInitiale;
  final Color couleurTexteInitiale;
  final String nomEntreprise;
  final String titrePoste;
  final String dateTexte;
  final StatutCandidatureType statutType;
  final String? libelleStatutCustom;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
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
            children: [
              // Logo/Initiale carrée
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
              const SizedBox(width: 14),

              // Informations entreprise et titre
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      nomEntreprise,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      titrePoste,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFF64748B),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      dateTexte,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: statutType == StatutCandidatureType.entretien
                            ? const Color(0xFF2563EB)
                            : const Color(0xFF94A3B8),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),

              // Badge de statut + Chevron
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  _buildBadgeStatut(),
                  const SizedBox(height: 8),
                  const Icon(
                    CupertinoIcons.chevron_right,
                    color: Color(0xFF94A3B8),
                    size: 16,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBadgeStatut() {
    String texte;
    Color fond;
    Color texteCouleur;

    switch (statutType) {
      case StatutCandidatureType.enAttente:
        texte = libelleStatutCustom ?? 'En attente';
        fond = const Color(0xFFFEF3C7);
        texteCouleur = const Color(0xFFD97706);
      case StatutCandidatureType.entretien:
        texte = libelleStatutCustom ?? 'Entretien';
        fond = const Color(0xFFE0F2FE);
        texteCouleur = const Color(0xFF0284C7);
      case StatutCandidatureType.refusee:
        texte = libelleStatutCustom ?? 'Refusée';
        fond = const Color(0xFFFEE2E2);
        texteCouleur = const Color(0xFFDC2626);
      case StatutCandidatureType.acceptee:
        texte = libelleStatutCustom ?? 'Acceptée';
        fond = const Color(0xFFDCFCE7);
        texteCouleur = const Color(0xFF16A34A);
      case StatutCandidatureType.paiementRequis:
        texte = libelleStatutCustom ?? 'Paiement requis';
        fond = const Color(0xFFFFEDD5);
        texteCouleur = const Color(0xFFEA580C);
      case StatutCandidatureType.confirme:
        texte = libelleStatutCustom ?? 'Confirmée';
        fond = const Color(0xFFE0E7FF);
        texteCouleur = const Color(0xFF4338CA);
      case StatutCandidatureType.admis:
        texte = libelleStatutCustom ?? 'Admis';
        fond = const Color(0xFFD1FAE5);
        texteCouleur = const Color(0xFF059669);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: fond,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        texte,
        style: GoogleFonts.inter(
          fontSize: 11.5,
          fontWeight: FontWeight.w700,
          color: texteCouleur,
        ),
      ),
    );
  }
}
