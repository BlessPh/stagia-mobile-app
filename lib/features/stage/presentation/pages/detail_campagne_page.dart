import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/network/configuration_api.dart';
import '../../../notifications/presentation/pages/notifications_page.dart';
import '../../data/datasources/source_campagne_mock.dart';
import '../../domain/entities/campagne_stage.dart';
import '../../domain/entities/suivi_candidature_stage.dart';
import '../../../../core/network/client_api_http.dart';
import '../../../../core/network/reponse_api.dart';
import '../../../../core/network/source_etudiant_distante.dart';
import '../../../../core/services/suivi_stage_service.dart';
import 'hopitaux_disponibles_page.dart';
import 'reservation_page.dart';
import 'apercu_facture_page.dart';

import 'dart:async';
import '../../../../core/services/sse_notifications_service.dart';

class DetailCampagnePage extends StatefulWidget {
  const DetailCampagnePage({this.campagne, this.suiviCandidature, super.key});

  final CampagneStage? campagne;
  final SuiviCandidatureStage? suiviCandidature;

  @override
  State<DetailCampagnePage> createState() => _DetailCampagnePageState();
}

class _DetailCampagnePageState extends State<DetailCampagnePage> {
  final _sourceEtudiant = SourceEtudiantDistante(ClientApiHttp());
  SuiviCandidatureStage? _suivi;
  bool _enCoursAnnulation = false;
  Map<String, dynamic>? _counts;
  StreamSubscription? _sseSubscription;

  @override
  void initState() {
    super.initState();
    _suivi = widget.suiviCandidature;
    _chargerCounts();
    _sseSubscription = SseNotificationsService.instance.fluxCompteurs.listen((
      counts,
    ) {
      if (mounted) setState(() => _counts = counts);
    });
  }

  Future<void> _chargerCounts() async {
    try {
      final res = await _sourceEtudiant.notificationCounts();
      if (mounted) {
        setState(() => _counts = res);
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _sseSubscription?.cancel();
    super.dispose();
  }

  Future<void> _annulerReservation() async {
    final resUuid = _suivi?.reservationUuid;
    if (resUuid == null) return;

    final confirmer = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        final modeSombre = Theme.of(ctx).brightness == Brightness.dark;
        return AlertDialog(
          backgroundColor: modeSombre ? const Color(0xFF1E293B) : Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(
            'Annuler la réservation ?',
            style: GoogleFonts.inter(
              fontWeight: FontWeight.w800,
              color: modeSombre ? Colors.white : const Color(0xFF0F172A),
            ),
          ),
          content: Text(
            'Votre place temporaire sera libérée immédiatement.',
            style: GoogleFonts.inter(
              color: modeSombre
                  ? const Color(0xFF94A3B8)
                  : const Color(0xFF64748B),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: Text(
                'Conserver',
                style: GoogleFonts.inter(fontWeight: FontWeight.w600),
              ),
            ),
            FilledButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFDC2626),
              ),
              child: const Text('Oui, annuler'),
            ),
          ],
        );
      },
    );

    if (confirmer != true || !mounted) return;

    setState(() => _enCoursAnnulation = true);
    try {
      final rep = await _sourceEtudiant.annulerReservation(resUuid);
      SuiviStageService.notifierChangement();
      if (!mounted) return;
      setState(() {
        _enCoursAnnulation = false;
        _suivi = SuiviCandidatureStage(
          campagne: _suivi!.campagne.avecStatut('Candidature annulée'),
          statut: 'ANNULEE',
          libelleStatut: 'Candidature annulée',
          message: 'Votre réservation a bien été annulée.',
          nomHopital: _suivi!.nomHopital,
          estTermine: true,
          reservationUuid: resUuid,
          reservationStatus: 'ANNULEE',
          applicationStatus: 'ANNULEE',
          canCancel: false,
        );
      });
      final msg = rep['message']?.toString() ?? 'Réservation annulée.';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    } on ErreurApi catch (e) {
      if (!mounted) return;
      setState(() => _enCoursAnnulation = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.message),
          backgroundColor: const Color(0xFFEF4444),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      setState(() => _enCoursAnnulation = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Impossible d’annuler la réservation.'),
          backgroundColor: Color(0xFFEF4444),
        ),
      );
    }
  }

  Future<void> _ouvrirPaiement() async {
    final reservationUuid = _suivi?.reservationUuid?.trim();
    if (reservationUuid == null || reservationUuid.isEmpty) {
      _afficherErreurPaiement(
        'Aucune réservation ne permet de retrouver cette obligation financière.',
      );
      return;
    }

    try {
      final donnees = await _sourceEtudiant.paiements();
      final items = (donnees['items'] as List).whereType<Map>().map(
        Map<String, dynamic>.from,
      );
      String? obligationUuid;

      for (final item in items) {
        if (item['reservation_uuid']?.toString() != reservationUuid) continue;
        final obligation = item['obligation'];
        if (obligation is Map) {
          obligationUuid = obligation['uuid']?.toString().trim();
        }
        obligationUuid ??= item['obligation_uuid']?.toString().trim();
        if (obligationUuid != null && obligationUuid.isNotEmpty) break;
      }

      if (obligationUuid == null || obligationUuid.isEmpty) {
        final obligations = (donnees['obligations'] as List)
            .whereType<Map>()
            .map(Map<String, dynamic>.from);
        for (final obligation in obligations) {
          final contexte = obligation['context'];
          final reservation = contexte is Map ? contexte['reservation'] : null;
          if (reservation is Map &&
              reservation['uuid']?.toString() == reservationUuid) {
            obligationUuid = obligation['uuid']?.toString().trim();
            break;
          }
        }
      }

      if (obligationUuid == null || obligationUuid.isEmpty) {
        throw const ErreurApi(
          code: 'OBLIGATION_INTROUVABLE',
          message:
              'Aucune obligation financière payable n’est associée à cette réservation.',
        );
      }

      if (!mounted) return;
      await Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => ApercuFacturePage(obligationUuid: obligationUuid!),
        ),
      );
      if (mounted) SuiviStageService.notifierChangement();
    } on ErreurApi catch (e) {
      _afficherErreurPaiement(e.message);
    } catch (_) {
      _afficherErreurPaiement(
        'Impossible de charger l’obligation financière pour le moment.',
      );
    }
  }

  void _afficherErreurPaiement(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: const Color(0xFFEF4444),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final modeSombre = Theme.of(context).brightness == Brightness.dark;
    final fondPage = modeSombre
        ? const Color(0xFF0F172A)
        : const Color(0xFFF8FAFC);
    final barreActionFond = modeSombre ? const Color(0xFF1E293B) : Colors.white;

    final infoCampagne =
        widget.campagne ??
        (ConfigurationApi.utiliserDonneesMockees
            ? SourceCampagneMock.obtenirCampagneOuverte()
            : null);
    if (infoCampagne == null) {
      return Scaffold(
        backgroundColor: fondPage,
        appBar: _buildAppBar(context, modeSombre),
        body: const SizedBox.shrink(),
      );
    }

    final aUneReservationActive = _suivi != null && !_suivi!.estTermine;

    return Scaffold(
      backgroundColor: fondPage,
      appBar: _buildAppBar(context, modeSombre),
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
                  // Carte Hero en dégradé
                  _CarteHeroCampagne(campagne: infoCampagne),

                  if (_suivi != null) ...[
                    const SizedBox(height: 16),
                    _CarteSuiviCandidature(
                      suivi: _suivi!,
                      modeSombre: modeSombre,
                      enCoursAnnulation: _enCoursAnnulation,
                      onAnnuler: _suivi!.canCancel ? _annulerReservation : null,
                      onPayer: _suivi!.statut == 'EN_ATTENTE_PAIEMENT'
                          ? _ouvrirPaiement
                          : null,
                    ),
                  ],

                  const SizedBox(height: 16),

                  // Grille 2x2 des informations clés (Début, Fin, Montant, Modalité)
                  _GrilleInformations(
                    campagne: infoCampagne,
                    modeSombre: modeSombre,
                  ),

                  const SizedBox(height: 22),

                  // Section Consignes générales
                  if (infoCampagne.consignes.isNotEmpty) ...[
                    _SectionConsignes(
                      consignes: infoCampagne.consignes,
                      modeSombre: modeSombre,
                    ),
                    const SizedBox(height: 22),
                  ],

                  // Section Éligibilité académique
                  if (infoCampagne.messageEligibilite.isNotEmpty ||
                      infoCampagne.criteresEligibilite.isNotEmpty) ...[
                    _SectionEligibilite(
                      messageEligibilite: infoCampagne.messageEligibilite,
                      criteres: infoCampagne.criteresEligibilite,
                      modeSombre: modeSombre,
                    ),
                    const SizedBox(height: 22),
                  ],

                  // Section Hôpitaux retenus
                  if (infoCampagne.hopitaux.isNotEmpty)
                    _SectionHopitauxRetenus(
                      campagne: infoCampagne,
                      hopitaux: infoCampagne.hopitaux,
                      modeSombre: modeSombre,
                      onSelectionnerHopital: (hopital) {
                        if (aUneReservationActive) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Vous avez déjà une réservation en cours sur cette campagne.',
                              ),
                            ),
                          );
                          return;
                        }
                        if (infoCampagne.autoriseReservationAutonome &&
                            hopital.peutReserver) {
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

            // Bouton inférieur contextualisé
            Container(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
              decoration: BoxDecoration(
                color: barreActionFond,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(
                      alpha: modeSombre ? 0.3 : 0.04,
                    ),
                    blurRadius: 10,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: FilledButton(
                  onPressed: aUneReservationActive
                      ? () => Navigator.of(context).maybePop()
                      : !infoCampagne.hopitaux.any(
                          (hopital) => hopital.peutReserver,
                        )
                      ? null
                      : () => _naviguerVersHopitauxDisponibles(
                          context,
                          infoCampagne,
                        ),
                  style: FilledButton.styleFrom(
                    backgroundColor: aUneReservationActive
                        ? (modeSombre
                              ? const Color(0xFF334155)
                              : const Color(0xFF64748B))
                        : const Color(0xFFFF751F),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    aUneReservationActive
                        ? 'Voir ma candidature'
                        : infoCampagne.autoriseReservationAutonome &&
                              infoCampagne.hopitaux.any(
                                (hopital) => hopital.peutReserver,
                              )
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

  PreferredSizeWidget _buildAppBar(BuildContext context, bool modeSombre) {
    final texteCouleur = modeSombre ? Colors.white : const Color(0xFF0F172A);
    final iconeCouleur = modeSombre
        ? const Color(0xFFE2E8F0)
        : const Color(0xFF0F172A);
    final fondAppBar = modeSombre
        ? const Color(0xFF0F172A)
        : const Color(0xFFF8FAFC);

    final unreadNotifs =
        int.tryParse(_counts?['notifications']?.toString() ?? '0') ?? 0;

    return AppBar(
      backgroundColor: fondAppBar,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      centerTitle: true,
      leading: IconButton(
        tooltip: 'Retour',
        icon: Icon(
          Icons.arrow_back_ios_new_rounded,
          size: 20,
          color: iconeCouleur,
        ),
        onPressed: () => Navigator.of(context).maybePop(),
      ),
      title: Text(
        'Détail de la campagne',
        style: GoogleFonts.inter(
          fontSize: 17,
          fontWeight: FontWeight.w800,
          color: texteCouleur,
        ),
      ),
      actions: [
        Stack(
          clipBehavior: Clip.none,
          children: [
            IconButton(
              tooltip: 'Notifications',
              onPressed: () async {
                await Navigator.of(context, rootNavigator: true).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const NotificationsPage(),
                  ),
                );
                _chargerCounts();
              },
              icon: Icon(CupertinoIcons.bell, color: iconeCouleur, size: 26),
              visualDensity: VisualDensity.compact,
            ),
            if (unreadNotifs > 0)
              Positioned(
                top: 5,
                right: 6,
                child: Container(
                  padding: const EdgeInsets.all(3),
                  decoration: const BoxDecoration(
                    color: Color(0xFFEF4444),
                    shape: BoxShape.circle,
                  ),
                  constraints: const BoxConstraints(
                    minWidth: 16,
                    minHeight: 16,
                  ),
                  child: Text(
                    '$unreadNotifs',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
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
          if (campagne.sousTitre.isNotEmpty)
            Text(
              campagne.sousTitre,
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: Colors.white.withValues(alpha: 0.88),
                height: 1.35,
              ),
            ),
          if (campagne.promotionNom.isNotEmpty) ...[
            const SizedBox(height: 5),
            Text(
              campagne.promotionNom,
              style: GoogleFonts.inter(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: Colors.white.withValues(alpha: 0.82),
                height: 1.3,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _CarteSuiviCandidature extends StatelessWidget {
  const _CarteSuiviCandidature({
    required this.suivi,
    required this.modeSombre,
    this.enCoursAnnulation = false,
    this.onAnnuler,
    this.onPayer,
  });

  final SuiviCandidatureStage suivi;
  final bool modeSombre;
  final bool enCoursAnnulation;
  final VoidCallback? onAnnuler;
  final VoidCallback? onPayer;

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

    final fond = modeSombre
        ? (estErreur
              ? const Color(0xFF451A1A)
              : suivi.statut == 'EN_ATTENTE_PAIEMENT'
              ? const Color(0xFF431407)
              : const Color(0xFF1E293B))
        : (estErreur
              ? const Color(0xFFFEF2F2)
              : suivi.statut == 'EN_ATTENTE_PAIEMENT'
              ? const Color(0xFFFFF7ED)
              : const Color(0xFFEFF6FF));

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: fond,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: modeSombre
              ? (estErreur
                    ? const Color(0xFF991B1B)
                    : couleur.withValues(alpha: 0.4))
              : couleur.withValues(alpha: 0.22),
        ),
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
                  color: couleur.withValues(alpha: modeSombre ? 0.25 : 0.12),
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
                      'Votre statut actuel',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: modeSombre
                            ? const Color(0xFF94A3B8)
                            : const Color(0xFF64748B),
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
                    color: atteint
                        ? couleur
                        : (modeSombre
                              ? const Color(0xFF334155)
                              : const Color(0xFFCBD5E1)),
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
              color: modeSombre
                  ? const Color(0xFFCBD5E1)
                  : const Color(0xFF334155),
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
                      color: modeSombre
                          ? Colors.white
                          : const Color(0xFF0F172A),
                    ),
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 14),
          // Étapes de validation du workflow (Placement -> Admission -> Affectation)
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: modeSombre
                  ? const Color(0xFF0F172A).withValues(alpha: 0.5)
                  : Colors.white.withValues(alpha: 0.7),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: modeSombre
                    ? const Color(0xFF334155)
                    : const Color(0xFFE2E8F0),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Détail de la progression',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: modeSombre
                        ? const Color(0xFF94A3B8)
                        : const Color(0xFF64748B),
                  ),
                ),
                const SizedBox(height: 8),
                _buildLigneEtape(
                  titre: 'Placement universitaire',
                  actif: suivi.placementExists,
                  statut:
                      suivi.placementStatus ??
                      (suivi.placementExists ? 'CONFIRME' : 'En attente'),
                  modeSombre: modeSombre,
                ),
                const SizedBox(height: 6),
                _buildLigneEtape(
                  titre: 'Admission hospitalière',
                  actif: suivi.admissionExists,
                  statut:
                      suivi.admissionStatus ??
                      (suivi.admissionExists ? 'ADMIS' : 'En attente'),
                  reference: suivi.admissionUuid != null
                      ? 'Réf: ${suivi.admissionUuid!.substring(0, 8)}...'
                      : null,
                  modeSombre: modeSombre,
                ),
                const SizedBox(height: 6),
                _buildLigneEtape(
                  titre: 'Affectation & rotations',
                  actif: suivi.assignmentExists,
                  statut:
                      suivi.assignmentStatus ??
                      (suivi.assignmentExists ? 'PLANIFIEE' : 'En attente'),
                  reference: suivi.assignmentUuid != null
                      ? 'Réf: ${suivi.assignmentUuid!.substring(0, 8)}...'
                      : null,
                  modeSombre: modeSombre,
                ),
              ],
            ),
          ),
          if (onPayer != null) ...[
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: onPayer,
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFFEA580C),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: const Icon(Icons.payment_rounded, size: 18),
                label: Text(
                  'Régler les frais de réservation',
                  style: GoogleFonts.inter(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
          ],
          if (onAnnuler != null) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: enCoursAnnulation ? null : onAnnuler,
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Color(0xFFEF4444)),
                  foregroundColor: const Color(0xFFEF4444),
                  padding: const EdgeInsets.symmetric(vertical: 11),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: enCoursAnnulation
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Color(0xFFEF4444),
                        ),
                      )
                    : const Icon(Icons.cancel_outlined, size: 18),
                label: Text(
                  enCoursAnnulation
                      ? 'Annulation en cours...'
                      : 'Annuler ma réservation',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildLigneEtape({
    required String titre,
    required bool actif,
    required String statut,
    String? reference,
    required bool modeSombre,
  }) {
    final couleur = actif ? const Color(0xFF16A34A) : const Color(0xFF94A3B8);
    final texteCouleur = modeSombre ? Colors.white : const Color(0xFF0F172A);

    return Row(
      children: [
        Icon(
          actif ? Icons.check_circle_rounded : Icons.radio_button_unchecked,
          color: couleur,
          size: 16,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                titre,
                style: GoogleFonts.inter(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: texteCouleur,
                ),
              ),
              if (reference != null)
                Text(
                  reference,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: const Color(0xFF94A3B8),
                  ),
                ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: actif
                ? (modeSombre
                      ? const Color(0xFF166534).withValues(alpha: 0.35)
                      : const Color(0xFFDCFCE7))
                : (modeSombre
                      ? const Color(0xFF334155).withValues(alpha: 0.5)
                      : const Color(0xFFF1F5F9)),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            statut,
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: actif
                  ? (modeSombre
                        ? const Color(0xFF4ADE80)
                        : const Color(0xFF15803D))
                  : const Color(0xFF64748B),
            ),
          ),
        ),
      ],
    );
  }
}

// -------------------------------------------------------------
// 2. GRILLE 2x2 D'INFORMATIONS
// -------------------------------------------------------------
class _GrilleInformations extends StatelessWidget {
  const _GrilleInformations({required this.campagne, required this.modeSombre});

  final CampagneStage campagne;
  final bool modeSombre;

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
                modeSombre: modeSombre,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _ItemInformation(
                icone: Icons.calendar_month_outlined,
                label: 'Fin',
                valeur: campagne.dateFin,
                modeSombre: modeSombre,
              ),
            ),
          ],
        ),
        if (campagne.typeStageLibelle.isNotEmpty ||
            campagne.promotionNom.isNotEmpty) ...[
          const SizedBox(height: 12),
          Row(
            children: [
              if (campagne.typeStageLibelle.isNotEmpty)
                Expanded(
                  child: _ItemInformation(
                    icone: Icons.medical_services_outlined,
                    label: 'Type de stage',
                    valeur: campagne.typeStageLibelle,
                    modeSombre: modeSombre,
                  ),
                ),
              if (campagne.typeStageLibelle.isNotEmpty &&
                  campagne.promotionNom.isNotEmpty)
                const SizedBox(width: 12),
              if (campagne.promotionNom.isNotEmpty)
                Expanded(
                  child: _ItemInformation(
                    icone: Icons.school_outlined,
                    label: 'Promotion',
                    valeur: campagne.promotionNom,
                    modeSombre: modeSombre,
                  ),
                ),
            ],
          ),
        ],
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
                    modeSombre: modeSombre,
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
                    modeSombre: modeSombre,
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
    required this.modeSombre,
  });

  final IconData icone;
  final String label;
  final String valeur;
  final bool modeSombre;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: modeSombre ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: modeSombre ? const Color(0xFF334155) : const Color(0xFFF1F5F9),
        ),
        boxShadow: [
          BoxShadow(
            color: modeSombre
                ? Colors.black.withValues(alpha: 0.15)
                : const Color(0x06000000),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: modeSombre
                  ? const Color(0xFF2563EB).withValues(alpha: 0.2)
                  : const Color(0xFFEFF6FF),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icone, color: const Color(0xFF2563EB), size: 20),
          ),
          const SizedBox(width: 12),
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
                    color: modeSombre ? Colors.white : const Color(0xFF0F172A),
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
  const _SectionConsignes({required this.consignes, required this.modeSombre});

  final List<String> consignes;
  final bool modeSombre;

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
            color: modeSombre ? Colors.white : const Color(0xFF0F172A),
          ),
        ),
        const SizedBox(height: 10),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: modeSombre ? const Color(0xFF1E293B) : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: modeSombre
                  ? const Color(0xFF334155)
                  : const Color(0xFFF1F5F9),
            ),
            boxShadow: [
              BoxShadow(
                color: modeSombre
                    ? Colors.black.withValues(alpha: 0.15)
                    : const Color(0x06000000),
                blurRadius: 10,
                offset: const Offset(0, 2),
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
                          color: modeSombre
                              ? const Color(0xFF94A3B8)
                              : const Color(0xFF64748B),
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
    required this.modeSombre,
  });

  final String messageEligibilite;
  final List<String> criteres;
  final bool modeSombre;

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
            color: modeSombre ? Colors.white : const Color(0xFF0F172A),
          ),
        ),
        const SizedBox(height: 10),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: modeSombre
                ? const Color(0xFF064E3B).withValues(alpha: 0.25)
                : const Color(0xFFF0FDF4),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: modeSombre
                  ? const Color(0xFF059669).withValues(alpha: 0.4)
                  : const Color(0xFFBBF7D0),
              width: 1.2,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
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
                        color: modeSombre
                            ? const Color(0xFF4ADE80)
                            : const Color(0xFF15803D),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Container(
                width: double.infinity,
                height: 1,
                color: modeSombre
                    ? const Color(0xFF059669).withValues(alpha: 0.25)
                    : const Color(0xFFDCFCE7),
              ),
              const SizedBox(height: 14),
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
                            color: modeSombre
                                ? const Color(0xFFE2E8F0)
                                : const Color(0xFF1E293B),
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
    required this.modeSombre,
  });

  final CampagneStage campagne;
  final List<HopitalCampagne> hopitaux;
  final ValueChanged<HopitalCampagne> onSelectionnerHopital;
  final VoidCallback onOuvrirCarte;
  final bool modeSombre;

  @override
  Widget build(BuildContext context) {
    final hopitauxAffiches = hopitaux.take(2).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Hôpitaux retenus (${campagne.nombreHopitaux})',
              style: GoogleFonts.inter(
                fontSize: 16.5,
                fontWeight: FontWeight.w800,
                color: modeSombre ? Colors.white : const Color(0xFF0F172A),
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
        ...hopitauxAffiches.map((hopital) {
          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            decoration: BoxDecoration(
              color: modeSombre ? const Color(0xFF1E293B) : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: modeSombre
                    ? const Color(0xFF334155)
                    : const Color(0xFFF1F5F9),
              ),
              boxShadow: [
                BoxShadow(
                  color: modeSombre
                      ? Colors.black.withValues(alpha: 0.15)
                      : const Color(0x06000000),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
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
                      Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: modeSombre
                              ? const Color(0xFF2563EB).withValues(alpha: 0.2)
                              : const Color(0xFFEFF6FF),
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
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              hopital.nom,
                              style: GoogleFonts.inter(
                                fontSize: 14.5,
                                fontWeight: FontWeight.w700,
                                color: modeSombre
                                    ? Colors.white
                                    : const Color(0xFF0F172A),
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
