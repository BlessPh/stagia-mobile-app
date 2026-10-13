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
    this.sousStatutTexte,
    this.estAnnulable = false,
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
  final String? sousStatutTexte;
  final bool estAnnulable;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final modeSombre = Theme.of(context).brightness == Brightness.dark;
    final fondCarte = modeSombre ? const Color(0xFF1E293B) : Colors.white;
    final bordureCouleur = modeSombre ? const Color(0xFF334155) : const Color(0xFFE2E8F0);
    final texteCouleur = modeSombre ? Colors.white : const Color(0xFF0F172A);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: fondCarte,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: bordureCouleur),
            boxShadow: [
              BoxShadow(
                color: modeSombre ? const Color(0x30000000) : const Color(0x05000000),
                blurRadius: 10,
                offset: const Offset(0, 2),
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
                  color: modeSombre
                      ? couleurFondInitiale.withValues(alpha: 0.22)
                      : couleurFondInitiale,
                  borderRadius: BorderRadius.circular(12),
                ),
                alignment: Alignment.center,
                child: Text(
                  initiale,
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: modeSombre ? Colors.white : couleurTexteInitiale,
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
                        color: texteCouleur,
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
                        color: modeSombre ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            dateTexte,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: const Color(0xFF94A3B8),
                            ),
                          ),
                        ),
                        if (sousStatutTexte != null && sousStatutTexte!.isNotEmpty) ...[
                          Text(
                            ' • ',
                            style: TextStyle(
                              color: modeSombre ? const Color(0xFF475569) : const Color(0xFFCBD5E1),
                              fontSize: 11,
                            ),
                          ),
                          Flexible(
                            child: Text(
                              sousStatutTexte!,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.inter(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w600,
                                color: modeSombre ? const Color(0xFF38BDF8) : const Color(0xFF2563EB),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),

              // Badge de statut + Chevron
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  _buildBadgeStatut(modeSombre),
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

  Widget _buildBadgeStatut(bool modeSombre) {
    String texte;
    Color fond;
    Color texteCouleur;

    switch (statutType) {
      case StatutCandidatureType.enAttente:
        texte = libelleStatutCustom ?? 'En attente';
        fond = modeSombre ? const Color(0xFF78350F).withValues(alpha: 0.35) : const Color(0xFFFEF3C7);
        texteCouleur = modeSombre ? const Color(0xFFFCD34D) : const Color(0xFFD97706);
      case StatutCandidatureType.entretien:
        texte = libelleStatutCustom ?? 'Entretien';
        fond = modeSombre ? const Color(0xFF0369A1).withValues(alpha: 0.35) : const Color(0xFFE0F2FE);
        texteCouleur = modeSombre ? const Color(0xFF7DD3FC) : const Color(0xFF0284C7);
      case StatutCandidatureType.refusee:
        texte = libelleStatutCustom ?? 'Refusée';
        fond = modeSombre ? const Color(0xFF7F1D1D).withValues(alpha: 0.35) : const Color(0xFFFEE2E2);
        texteCouleur = modeSombre ? const Color(0xFFFCA5A5) : const Color(0xFFDC2626);
      case StatutCandidatureType.acceptee:
        texte = libelleStatutCustom ?? 'Acceptée';
        fond = modeSombre ? const Color(0xFF14532D).withValues(alpha: 0.35) : const Color(0xFFDCFCE7);
        texteCouleur = modeSombre ? const Color(0xFF86EFAC) : const Color(0xFF16A34A);
      case StatutCandidatureType.paiementRequis:
        texte = libelleStatutCustom ?? 'Paiement requis';
        fond = modeSombre ? const Color(0xFF7C2D12).withValues(alpha: 0.35) : const Color(0xFFFFEDD5);
        texteCouleur = modeSombre ? const Color(0xFFFDBA74) : const Color(0xFFEA580C);
      case StatutCandidatureType.confirme:
        texte = libelleStatutCustom ?? 'Confirmée';
        fond = modeSombre ? const Color(0xFF312E81).withValues(alpha: 0.35) : const Color(0xFFE0E7FF);
        texteCouleur = modeSombre ? const Color(0xFFA5B4FC) : const Color(0xFF4338CA);
      case StatutCandidatureType.admis:
        texte = libelleStatutCustom ?? 'Admis';
        fond = modeSombre ? const Color(0xFF064E3B).withValues(alpha: 0.35) : const Color(0xFFD1FAE5);
        texteCouleur = modeSombre ? const Color(0xFF6EE7B7) : const Color(0xFF059669);
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
