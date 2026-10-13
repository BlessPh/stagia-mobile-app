import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/network/configuration_api.dart';
import '../../../stage/data/datasources/source_campagne_mock.dart';
import '../../../stage/domain/entities/campagne_stage.dart';
import '../../../stage/presentation/pages/detail_campagne_page.dart';

class SectionStageDisponibleAccueil extends StatelessWidget {
  const SectionStageDisponibleAccueil({
    this.campagne,
    this.onVoirDetails,
    this.titreSection = 'Stage disponible',
    this.libelleCompteur = '1 campagne ouverte',
    this.statutAffiche,
    this.messageStatut,
    this.libelleInformationSecondaire = 'Indemnité',
    this.valeurInformationSecondaire,
    this.afficherNombreHopitaux = true,
    this.libelleAction = 'Voir les détails',
    this.estSuiviCandidature = false,
    super.key,
  });

  final CampagneStage? campagne;
  final VoidCallback? onVoirDetails;
  final String titreSection;
  final String libelleCompteur;
  final String? statutAffiche;
  final String? messageStatut;
  final String libelleInformationSecondaire;
  final String? valeurInformationSecondaire;
  final bool afficherNombreHopitaux;
  final String libelleAction;
  final bool estSuiviCandidature;

  @override
  Widget build(BuildContext context) {
    final modeSombre = Theme.of(context).brightness == Brightness.dark;
    final fondCarte = modeSombre ? const Color(0xFF1E293B) : Colors.white;
    final bordure = modeSombre
        ? const Color(0xFF334155)
        : const Color(0xFFF1F5F9);
    final textePrincipal = modeSombre ? Colors.white : const Color(0xFF0F172A);
    final texteSecondaire = modeSombre
        ? const Color(0xFF94A3B8)
        : const Color(0xFF64748B);
    final infoCampagne =
        campagne ??
        (ConfigurationApi.utiliserDonneesMockees
            ? SourceCampagneMock.obtenirCampagneOuverte()
            : null);
    if (infoCampagne == null) return const SizedBox.shrink();
    final statutNormalise = (statutAffiche ?? infoCampagne.statut)
        .toLowerCase();
    final statutCritique =
        statutNormalise.contains('refus') ||
        statutNormalise.contains('annul') ||
        statutNormalise.contains('expir');
    final paiementRequis = statutNormalise.contains('paiement');
    final couleurSuivi = statutCritique
        ? (modeSombre ? const Color(0xFFFCA5A5) : const Color(0xFFDC2626))
        : paiementRequis
        ? (modeSombre ? const Color(0xFFFDBA74) : const Color(0xFFEA580C))
        : (modeSombre ? const Color(0xFF93C5FD) : const Color(0xFF2563EB));
    final fondSuivi = statutCritique
        ? (modeSombre ? const Color(0xFF4C1D24) : const Color(0xFFFEE2E2))
        : paiementRequis
        ? (modeSombre ? const Color(0xFF431C0D) : const Color(0xFFFFEDD5))
        : (modeSombre ? const Color(0xFF1E3A5F) : const Color(0xFFDBEAFE));
    final fondBadgeCompteur = modeSombre
        ? const Color(0xFF0C4A6E)
        : const Color(0xFFE0F2FE);
    final texteBadgeCompteur = modeSombre
        ? const Color(0xFF7DD3FC)
        : const Color(0xFF0284C7);
    final fondStatutOuvert = modeSombre
        ? const Color(0xFF14532D)
        : const Color(0xFFDCFCE7);
    final texteStatutOuvert = modeSombre
        ? const Color(0xFF86EFAC)
        : const Color(0xFF15803D);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // En-tête : Titre + Badge 1 campagne ouverte
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              titreSection,
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: textePrincipal,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 10,
                vertical: 4.5,
              ),
              decoration: BoxDecoration(
                color: fondBadgeCompteur,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                libelleCompteur,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: texteBadgeCompteur,
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 12),

        // Carte de la campagne ouverte
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: fondCarte,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: bordure),
            boxShadow: [
              BoxShadow(
                color: modeSombre
                    ? const Color(0x33000000)
                    : const Color(0x0A000000),
                blurRadius: 16,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Titre de la campagne
                    Text(
                      infoCampagne.titre,
                      style: GoogleFonts.inter(
                        fontSize: 17.5,
                        fontWeight: FontWeight.w800,
                        color: textePrincipal,
                      ),
                    ),

                    const SizedBox(height: 14),

                    // Ligne à 2 colonnes : Date et Indemnité
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Colonne Date
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Date',
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: const Color(0xFF94A3B8),
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                infoCampagne.periodeTexte,
                                style: GoogleFonts.inter(
                                  fontSize: 14.5,
                                  fontWeight: FontWeight.w800,
                                  color: textePrincipal,
                                  height: 1.25,
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Colonne Indemnité
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                libelleInformationSecondaire,
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: const Color(0xFF94A3B8),
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                valeurInformationSecondaire ??
                                    infoCampagne.indemnite,
                                style: GoogleFonts.inter(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w800,
                                  color: textePrincipal,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 14),

                    // Badge Inscriptions ouvertes + Hôpitaux disponibles
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4.5,
                          ),
                          decoration: BoxDecoration(
                            color: estSuiviCandidature
                                ? fondSuivi
                                : fondStatutOuvert,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            statutAffiche ?? infoCampagne.statut,
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: estSuiviCandidature
                                  ? couleurSuivi
                                  : texteStatutOuvert,
                            ),
                          ),
                        ),
                        if (afficherNombreHopitaux) ...[
                          const SizedBox(width: 10),
                          Builder(
                            builder: (context) {
                              final nombre =
                                  infoCampagne.nombreHopitauxDisponibles ??
                                  infoCampagne.nombreHopitaux;
                              return Text(
                                '$nombre '
                                '${nombre == 1 ? 'hôpital' : 'hôpitaux'} '
                                'disponible${nombre == 1 ? '' : 's'}',
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                  color: texteSecondaire,
                                ),
                              );
                            },
                          ),
                        ],
                      ],
                    ),

                    const SizedBox(height: 12),

                    // État d'éligibilité renvoyé par l'API
                    Row(
                      children: [
                        Icon(
                          estSuiviCandidature
                              ? Icons.track_changes_rounded
                              : infoCampagne.estEligible
                              ? Icons.check_circle_rounded
                              : Icons.cancel_rounded,
                          color: estSuiviCandidature
                              ? couleurSuivi
                              : infoCampagne.estEligible
                              ? const Color(0xFF16A34A)
                              : const Color(0xFFDC2626),
                          size: 18,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            messageStatut?.isNotEmpty == true
                                ? messageStatut!
                                : infoCampagne.messageEligibilite.isNotEmpty
                                ? infoCampagne.messageEligibilite
                                : infoCampagne.estEligible
                                ? 'Vous êtes éligible'
                                : 'Vous n’êtes pas éligible',
                            style: GoogleFonts.inter(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w600,
                              color: estSuiviCandidature
                                  ? couleurSuivi
                                  : infoCampagne.estEligible
                                  ? const Color(0xFF16A34A)
                                  : const Color(0xFFDC2626),
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // Bouton bleu "Voir les détails"
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: FilledButton(
                        onPressed: () {
                          if (onVoirDetails != null) {
                            onVoirDetails!();
                          } else {
                            Navigator.of(context, rootNavigator: true).push(
                              MaterialPageRoute<void>(
                                builder: (_) =>
                                    DetailCampagnePage(campagne: infoCampagne),
                              ),
                            );
                          }
                        },
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFFFF751F),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                        child: Text(
                          libelleAction,
                          style: GoogleFonts.inter(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
