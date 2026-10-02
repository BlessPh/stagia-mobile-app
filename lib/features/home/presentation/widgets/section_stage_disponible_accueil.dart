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
        ? const Color(0xFFDC2626)
        : paiementRequis
        ? const Color(0xFFEA580C)
        : const Color(0xFF2563EB);
    final fondSuivi = statutCritique
        ? const Color(0xFFFEE2E2)
        : paiementRequis
        ? const Color(0xFFFFEDD5)
        : const Color(0xFFDBEAFE);

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
                color: const Color(0xFF0F172A),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 10,
                vertical: 4.5,
              ),
              decoration: BoxDecoration(
                color: const Color(0xFFE0F2FE),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                libelleCompteur,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF0284C7),
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
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFF1F5F9)),
            boxShadow: const [
              BoxShadow(
                color: Color(0x0A000000),
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
                        color: const Color(0xFF0F172A),
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
                                  color: const Color(0xFF0F172A),
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
                                  color: const Color(0xFF0F172A),
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
                                : const Color(0xFFDCFCE7),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            statutAffiche ?? infoCampagne.statut,
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: estSuiviCandidature
                                  ? couleurSuivi
                                  : const Color(0xFF15803D),
                            ),
                          ),
                        ),
                        if (afficherNombreHopitaux) ...[
                          const SizedBox(width: 10),
                          Text(
                            '${infoCampagne.nombreHopitaux} '
                            '${infoCampagne.nombreHopitaux == 1 ? 'hôpital' : 'hôpitaux'} '
                            'disponible${infoCampagne.nombreHopitaux == 1 ? '' : 's'}',
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: const Color(0xFF64748B),
                            ),
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
