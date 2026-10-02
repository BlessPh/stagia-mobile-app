import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/network/configuration_api.dart';
import '../../../notifications/presentation/pages/notifications_page.dart';
import '../../data/datasources/source_campagne_mock.dart';
import '../../domain/entities/campagne_stage.dart';
import '../../domain/entities/suivi_candidature_stage.dart';
import 'hopitaux_disponibles_page.dart';
import 'reservation_page.dart';

class DetailCampagnePage extends StatelessWidget {
  const DetailCampagnePage({this.campagne, this.suiviCandidature, super.key});

  final CampagneStage? campagne;
  final SuiviCandidatureStage? suiviCandidature;

  @override
  Widget build(BuildContext context) {
    final infoCampagne =
        campagne ??
        (ConfigurationApi.utiliserDonneesMockees
            ? SourceCampagneMock.obtenirCampagneOuverte()
            : null);
    if (infoCampagne == null) {
      return Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        appBar: _buildAppBar(context),
        body: const SizedBox.shrink(),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: _buildAppBar(context),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                physics: const BouncingScrollPhysics(
                  parent: AlwaysScrollableScrollPhysics(),
                ),
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
                children: [
                  // Carte Hero en dégradé bleu / violet
                  _CarteHeroCampagne(campagne: infoCampagne),

                  if (suiviCandidature != null) ...[
                    const SizedBox(height: 16),
                    _CarteSuiviCandidature(suivi: suiviCandidature!),
                  ],

                  const SizedBox(height: 16),

                  // Grille 2x2 des informations clés (Début, Fin, Montant, Modalité)
                  _GrilleInformations(campagne: infoCampagne),

                  const SizedBox(height: 22),

                  // Section Consignes générales
                  if (infoCampagne.consignes.isNotEmpty) ...[
                    _SectionConsignes(consignes: infoCampagne.consignes),
                    const SizedBox(height: 22),
                  ],

                  // Section Éligibilité académique
                  if (infoCampagne.messageEligibilite.isNotEmpty ||
                      infoCampagne.criteresEligibilite.isNotEmpty) ...[
                    _SectionEligibilite(
                      messageEligibilite: infoCampagne.messageEligibilite,
                      criteres: infoCampagne.criteresEligibilite,
                    ),
                    const SizedBox(height: 22),
                  ],

                  // Section Hôpitaux retenus
                  if (infoCampagne.hopitaux.isNotEmpty)
                    _SectionHopitauxRetenus(
                      campagne: infoCampagne,
                      hopitaux: infoCampagne.hopitaux,
                      onSelectionnerHopital: (hopital) {
                        if (infoCampagne.autoriseReservationAutonome) {
                          _naviguerVersReservation(
                            context,
                            infoCampagne,
                            hopital,
                          );
                        } else {
                          _naviguerVersHopitauxDisponibles(
                            context,
                            infoCampagne,
                            hopital: hopital,
                          );
                        }
                      },
                      onOuvrirCarte: () {
                        _naviguerVersHopitauxDisponibles(context, infoCampagne);
                      },
                    ),

                  const SizedBox(height: 16),
                ],
              ),
            ),

            // Bouton inférieur "Réserver ma place"
            Container(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 10,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: FilledButton(
                  onPressed: suiviCandidature != null
                      ? () => Navigator.of(context).maybePop()
                      : infoCampagne.hopitaux.isEmpty
                      ? null
                      : () => _naviguerVersHopitauxDisponibles(
                          context,
                          infoCampagne,
                        ),
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFFFF751F),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    suiviCandidature != null
                        ? 'Retour aux candidatures'
                        : infoCampagne.autoriseReservationAutonome
                        ? 'Réserver ma place'
                        : 'Voir les hôpitaux éligibles',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: const Color(0xFFF8FAFC),
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      centerTitle: true,
      leading: IconButton(
        tooltip: 'Retour',
        icon: const Icon(
          Icons.arrow_back_ios_new_rounded,
          size: 20,
          color: Color(0xFF0F172A),
        ),
        onPressed: () => Navigator.of(context).maybePop(),
      ),
      title: Text(
        'Détail de la campagne',
        style: GoogleFonts.inter(
          fontSize: 17,
          fontWeight: FontWeight.w800,
          color: const Color(0xFF0F172A),
        ),
      ),
      actions: [
        Stack(
          clipBehavior: Clip.none,
          children: [
            IconButton(
              tooltip: 'Notifications',
              onPressed: () => Navigator.of(context, rootNavigator: true).push(
                MaterialPageRoute<void>(
                  builder: (_) => const NotificationsPage(),
                ),
              ),
              icon: const Icon(
                CupertinoIcons.bell,
                color: Color(0xFF0F172A),
                size: 26,
              ),
              visualDensity: VisualDensity.compact,
            ),
            Positioned(
              top: 5,
              right: 6,
              child: Container(
                padding: const EdgeInsets.all(3),
                decoration: const BoxDecoration(
                  color: Color(0xFFEF4444),
                  shape: BoxShape.circle,
                ),
                constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                child: const Text(
                  '5',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 9.5,
                    fontWeight: FontWeight.w800,
                    height: 1,
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  void _naviguerVersReservation(
    BuildContext context,
    CampagneStage campagne,
    HopitalCampagne hopital,
  ) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ReservationPage(campagne: campagne, hopital: hopital),
      ),
    );
  }

  void _naviguerVersHopitauxDisponibles(
    BuildContext context,
    CampagneStage campagne, {
    HopitalCampagne? hopital,
  }) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => HopitauxDisponiblesPage(
          campagne: campagne,
          hopitalInitial: hopital,
        ),
      ),
    );
  }
}

// -------------------------------------------------------------
// 1. CARTE HERO DE LA CAMPAGNE
// -------------------------------------------------------------
class _CarteHeroCampagne extends StatelessWidget {
  const _CarteHeroCampagne({required this.campagne});

  final CampagneStage campagne;

  @override
  Widget build(BuildContext context) {
    final statut = campagne.statut.toLowerCase();
    final statutCritique =
        statut.contains('refus') ||
        statut.contains('annul') ||
        statut.contains('expir');
    final fondStatut = statutCritique
        ? const Color(0xFFFEE2E2)
        : const Color(0xFFDCFCE7);
    final couleurStatut = statutCritique
        ? const Color(0xFFDC2626)
        : const Color(0xFF15803D);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFFF751F), Color(0xFFFF7510)],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2355F6).withValues(alpha: 0.25),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Badge "Inscriptions ouvertes"
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: fondStatut,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              campagne.statut,
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: couleurStatut,
              ),
            ),
          ),
          const SizedBox(height: 14),

          // Titre principal
          Text(
            campagne.titre,
            style: GoogleFonts.inter(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              height: 1.22,
            ),
          ),
          const SizedBox(height: 10),

          // Sous-titre universitaire
          Text(
            campagne.sousTitre,
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: Colors.white.withValues(alpha: 0.88),
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }
}

class _CarteSuiviCandidature extends StatelessWidget {
  const _CarteSuiviCandidature({required this.suivi});

  final SuiviCandidatureStage suivi;

  @override
  Widget build(BuildContext context) {
    final estErreur = {
      'CANDIDATURE_REFUSEE',
      'ANNULEE',
      'RESERVATION_EXPIREE',
    }.contains(suivi.statut);
    final couleur = estErreur
        ? const Color(0xFFDC2626)
        : suivi.statut == 'EN_ATTENTE_PAIEMENT'
        ? const Color(0xFFEA580C)
        : const Color(0xFF2563EB);
    final fond = estErreur
        ? const Color(0xFFFEF2F2)
        : suivi.statut == 'EN_ATTENTE_PAIEMENT'
        ? const Color(0xFFFFF7ED)
        : const Color(0xFFEFF6FF);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: fond,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: couleur.withValues(alpha: 0.22)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: couleur.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  estErreur
                      ? Icons.info_outline_rounded
                      : Icons.hourglass_top_rounded,
                  color: couleur,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Votre candidature',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF64748B),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      suivi.libelleStatut,
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: couleur,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: List.generate(6, (index) {
              final atteint = index < suivi.progression && !estErreur;
              return Expanded(
                child: Container(
                  height: 5,
                  margin: EdgeInsets.only(right: index == 5 ? 0 : 5),
                  decoration: BoxDecoration(
                    color: atteint ? couleur : const Color(0xFFCBD5E1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 12),
          Text(
            suivi.message,
            style: GoogleFonts.inter(
              fontSize: 13.5,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF334155),
              height: 1.4,
            ),
          ),
          if (suivi.nomHopital.isNotEmpty) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.local_hospital_outlined, color: couleur, size: 18),
                const SizedBox(width: 7),
                Expanded(
                  child: Text(
                    suivi.nomHopital,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF0F172A),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

// -------------------------------------------------------------
// 2. GRILLE 2x2 D'INFORMATIONS
// -------------------------------------------------------------
class _GrilleInformations extends StatelessWidget {
  const _GrilleInformations({required this.campagne});

  final CampagneStage campagne;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _ItemInformation(
                icone: Icons.calendar_today_outlined,
                label: 'Début',
                valeur: campagne.dateDebut,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _ItemInformation(
                icone: Icons.calendar_month_outlined,
                label: 'Fin',
                valeur: campagne.dateFin,
              ),
            ),
          ],
        ),
        if (campagne.indemnite.isNotEmpty || campagne.modalite.isNotEmpty) ...[
          const SizedBox(height: 12),
          Row(
            children: [
              if (campagne.indemnite.isNotEmpty)
                Expanded(
                  child: _ItemInformation(
                    icone: Icons.payments_outlined,
                    label: 'Montant',
                    valeur: campagne.indemnite,
                  ),
                ),
              if (campagne.indemnite.isNotEmpty && campagne.modalite.isNotEmpty)
                const SizedBox(width: 12),
              if (campagne.modalite.isNotEmpty)
                Expanded(
                  child: _ItemInformation(
                    icone: Icons.account_tree_outlined,
                    label: 'Modalité',
                    valeur: campagne.modalite,
                  ),
                ),
            ],
          ),
        ],
      ],
    );
  }
}

class _ItemInformation extends StatelessWidget {
  const _ItemInformation({
    required this.icone,
    required this.label,
    required this.valeur,
  });

  final IconData icone;
  final String label;
  final String valeur;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF1F5F9)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x06000000),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Icône dans son carré bleu clair
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: const Color(0xFFEFF6FF),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icone, color: const Color(0xFF2563EB), size: 20),
          ),
          const SizedBox(width: 12),

          // Label et Valeur
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF94A3B8),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  valeur,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF0F172A),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// -------------------------------------------------------------
// 3. SECTION CONSIGNES GÉNÉRALES
// -------------------------------------------------------------
class _SectionConsignes extends StatelessWidget {
  const _SectionConsignes({required this.consignes});

  final List<String> consignes;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Consignes générales',
          style: GoogleFonts.inter(
            fontSize: 16.5,
            fontWeight: FontWeight.w800,
            color: const Color(0xFF0F172A),
          ),
        ),
        const SizedBox(height: 10),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFF1F5F9)),
            boxShadow: const [
              BoxShadow(
                color: Color(0x06000000),
                blurRadius: 10,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: consignes.map((consigne) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      margin: const EdgeInsets.only(top: 6, right: 10),
                      width: 5,
                      height: 5,
                      decoration: const BoxDecoration(
                        color: Color(0xFF2563EB),
                        shape: BoxShape.circle,
                      ),
                    ),
                    Expanded(
                      child: Text(
                        consigne,
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFF64748B),
                          height: 1.45,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}

// -------------------------------------------------------------
// 4. SECTION ÉLIGIBILITÉ ACADÉMIQUE
// -------------------------------------------------------------
class _SectionEligibilite extends StatelessWidget {
  const _SectionEligibilite({
    required this.messageEligibilite,
    required this.criteres,
  });

  final String messageEligibilite;
  final List<String> criteres;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Éligibilité académique',
          style: GoogleFonts.inter(
            fontSize: 16.5,
            fontWeight: FontWeight.w800,
            color: const Color(0xFF0F172A),
          ),
        ),
        const SizedBox(height: 10),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: const Color(0xFFF0FDF4),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFBBF7D0), width: 1.2),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // En-tête : Coche bouclier + Message
              Row(
                children: [
                  const Icon(
                    Icons.check_circle_rounded,
                    color: Color(0xFF16A34A),
                    size: 21,
                  ),
                  const SizedBox(width: 9),
                  Expanded(
                    child: Text(
                      messageEligibilite,
                      style: GoogleFonts.inter(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF15803D),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Séparateur fin vert
              Container(
                width: double.infinity,
                height: 1,
                color: const Color(0xFFDCFCE7),
              ),

              const SizedBox(height: 14),

              // Critères avec coches
              ...criteres.map((critere) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.check_circle_outline_rounded,
                        color: Color(0xFF16A34A),
                        size: 18,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          critere,
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF1E293B),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ],
          ),
        ),
      ],
    );
  }
}

// -------------------------------------------------------------
// 5. SECTION HÔPITAUX RETENUS
// -------------------------------------------------------------
class _SectionHopitauxRetenus extends StatelessWidget {
  const _SectionHopitauxRetenus({
    required this.campagne,
    required this.hopitaux,
    required this.onSelectionnerHopital,
    required this.onOuvrirCarte,
  });

  final CampagneStage campagne;
  final List<HopitalCampagne> hopitaux;
  final ValueChanged<HopitalCampagne> onSelectionnerHopital;
  final VoidCallback onOuvrirCarte;

  @override
  Widget build(BuildContext context) {
    // Afficher les deux premiers hôpitaux comme sur la maquette
    final hopitauxAffiches = hopitaux.take(2).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // En-tête : Titre + Lien Carte
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Hôpitaux retenus (${campagne.nombreHopitaux})',
              style: GoogleFonts.inter(
                fontSize: 16.5,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF0F172A),
              ),
            ),
            InkWell(
              onTap: onOuvrirCarte,
              borderRadius: BorderRadius.circular(6),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                child: Row(
                  children: [
                    const Icon(
                      Icons.location_on_outlined,
                      size: 16,
                      color: Color(0xFF2563EB),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Carte',
                      style: GoogleFonts.inter(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF2563EB),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 10),

        // Liste des cartes d'hôpitaux
        ...hopitauxAffiches.map((hopital) {
          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFF1F5F9)),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x06000000),
                  blurRadius: 10,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(16),
              child: InkWell(
                onTap: () => onSelectionnerHopital(hopital),
                borderRadius: BorderRadius.circular(16),
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Row(
                    children: [
                      // Icône hôpital dans son conteneur bleu clair
                      Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: const Color(0xFFEFF6FF),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Center(
                          child: FaIcon(
                            FontAwesomeIcons.hospital,
                            color: Color(0xFF2563EB),
                            size: 18,
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),

                      // Nom de l'hôpital et distance / places
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              hopital.nom,
                              style: GoogleFonts.inter(
                                fontSize: 14.5,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF0F172A),
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              hopital.distanceEtPlaces,
                              style: GoogleFonts.inter(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w500,
                                color: const Color(0xFF64748B),
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Chevron de navigation
                      const Icon(
                        Icons.chevron_right_rounded,
                        color: Color(0xFF94A3B8),
                        size: 22,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }),
      ],
    );
  }
}
