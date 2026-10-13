import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/network/client_api_http.dart';
import '../../../../core/network/configuration_api.dart';
import '../../../../core/network/reponse_api.dart';
import '../../../../core/services/suivi_stage_service.dart';
import '../../../notifications/presentation/pages/notifications_page.dart';
import '../../data/datasources/source_campagne_mock.dart';
import '../../data/datasources/source_stage_distante.dart';
import '../../domain/entities/campagne_stage.dart';

import 'dart:async';
import '../../../../core/services/sse_notifications_service.dart';
import '../../../../core/network/source_etudiant_distante.dart';

class ReservationPage extends StatefulWidget {
  const ReservationPage({this.campagne, this.hopital, super.key});

  final CampagneStage? campagne;
  final HopitalCampagne? hopital;

  @override
  State<ReservationPage> createState() => _ReservationPageState();
}

class _ReservationPageState extends State<ReservationPage> {
  final _source = SourceStageDistante(ClientApiHttp());
  final _sourceEtudiant = SourceEtudiantDistante(ClientApiHttp());
  late final CampagneStage _campagne;
  late final HopitalCampagne _hopital;

  final TextEditingController _motivationController = TextEditingController();
  bool _conditionsAcceptees = true;
  bool _enCoursDeSoumission = false;
  Map<String, dynamic>? _counts;
  StreamSubscription? _sseSubscription;

  @override
  void initState() {
    super.initState();
    _chargerCounts();
    _sseSubscription = SseNotificationsService.instance.fluxCompteurs.listen((counts) {
      if (mounted) setState(() => _counts = counts);
    });
    _campagne =
        widget.campagne ??
        (ConfigurationApi.utiliserDonneesMockees
            ? SourceCampagneMock.obtenirCampagneOuverte()
            : throw StateError('Une campagne API est requise.'));
    _hopital =
        widget.hopital ??
        (_campagne.hopitaux.isNotEmpty
            ? _campagne.hopitaux.first
            : ConfigurationApi.utiliserDonneesMockees
            ? SourceCampagneMock.campagnePrincipale.hopitaux.first
            : throw StateError('Aucun hôpital disponible.'));
    _conditionsAcceptees = _hopital.conditions == null;
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
    _motivationController.dispose();
    super.dispose();
  }

  void _confirmerReservation() async {
    if (!_campagne.autoriseReservationAutonome) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Le placement de cette campagne est géré par votre université.',
          ),
          backgroundColor: Color(0xFFEF4444),
        ),
      );
      return;
    }
    if (!_hopital.peutReserver) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Aucune place ne peut être réservée dans cet hôpital.'),
          backgroundColor: Color(0xFFEF4444),
        ),
      );
      return;
    }
    if (!_conditionsAcceptees) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez accepter les conditions de stage.'),
          backgroundColor: Color(0xFFEF4444),
        ),
      );
      return;
    }

    setState(() => _enCoursDeSoumission = true);

    final participationIdNum =
        _hopital.participationId ??
        int.tryParse(_hopital.id) ??
        (ConfigurationApi.utiliserDonneesMockees ? 101 : null);
    final campaignIdNum =
        int.tryParse(_campagne.id) ??
        (ConfigurationApi.utiliserDonneesMockees ? 1 : null);
    final enrollmentIdNum =
        _campagne.academicEnrollmentId ??
        (ConfigurationApi.utiliserDonneesMockees ? 1 : null);

    if (participationIdNum == null ||
        campaignIdNum == null ||
        enrollmentIdNum == null) {
      setState(() => _enCoursDeSoumission = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Cette option de stage ne contient pas les identifiants requis.',
          ),
          backgroundColor: Color(0xFFEF4444),
        ),
      );
      return;
    }

    try {
      final resultat = await _source.reserver(
        campaignId: campaignIdNum,
        academicEnrollmentId: enrollmentIdNum,
        participationId: participationIdNum,
        motivation: _motivationController.text.trim().isEmpty
            ? null
            : _motivationController.text.trim(),
        cleOption: '${_campagne.id}::${_hopital.id}',
        campagneTitre: _campagne.titre,
        etablissementNom: _hopital.nom,
        localisation: _hopital.adresse ?? _hopital.localisationCourte,
      );

      if (!mounted) return;
      setState(() => _enCoursDeSoumission = false);

      SuiviStageService.notifierChangement();

      _afficherConfirmationModal(resultat);
    } on ErreurApi catch (erreur) {
      if (!mounted) return;
      setState(() => _enCoursDeSoumission = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(erreur.message),
          backgroundColor: const Color(0xFFEF4444),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _enCoursDeSoumission = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur : $e'),
          backgroundColor: const Color(0xFFEF4444),
        ),
      );
    }
  }

  void _afficherConfirmationModal(Map<String, dynamic> donnees) {
    final reference =
        donnees['reservation_uuid']?.toString() ??
        donnees['application_uuid']?.toString() ??
        donnees['reference']?.toString() ??
        '';
    final reservationCreee = donnees['created'] != false;
    final expiration = donnees['expires_at']?.toString() ?? '';
    final statut = donnees['reservation_status']?.toString() ?? '';
    final workflowStatut = donnees['workflow_status']?.toString() ?? '';

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          padding: const EdgeInsets.fromLTRB(22, 16, 22, 32),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFE2E8F0),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 24),
              Container(
                width: 68,
                height: 68,
                decoration: const BoxDecoration(
                  color: Color(0xFFDCFCE7),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_circle_rounded,
                  color: Color(0xFF16A34A),
                  size: 44,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                reservationCreee
                    ? 'Candidature & Réservation soumises !'
                    : 'Réservation déjà active',
                style: GoogleFonts.inter(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                reservationCreee
                    ? 'Votre place est réservée temporairement auprès de ${_hopital.nom}. Elle sera confirmée après la décision universitaire et le règlement des frais le cas échéant.'
                    : 'Votre réservation auprès de ${_hopital.nom} était déjà active. Aucune réservation supplémentaire n’a été créée.',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFF64748B),
                ),
              ),
              if (reference.isNotEmpty ||
                  statut.isNotEmpty ||
                  workflowStatut.isNotEmpty) ...[
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Text(
                    [
                      if (reference.isNotEmpty) 'Référence : $reference',
                      if (statut.isNotEmpty) statut,
                      if (workflowStatut.isNotEmpty) workflowStatut,
                    ].join(' · '),
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF1D61F2),
                    ),
                  ),
                ),
              ],
              if (expiration.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  'Expiration : $expiration',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF64748B),
                  ),
                ),
              ],
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: FilledButton(
                  onPressed: () {
                    Navigator.of(ctx).pop(); // Ferme le modal
                    Navigator.of(context).popUntil((route) => route.isFirst);
                  },
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF1D61F2),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: Text(
                    'Retour à l\'accueil',
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: _buildAppBar(context),
      body: SafeArea(
        child: ListView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
          children: [
            // 1. CARTE VOTRE SÉLECTION
            _CarteVotreSelection(campagne: _campagne, hopital: _hopital),

            const SizedBox(height: 22),

            // 2. CHAMP MOTIVATION (OPTIONNEL)
            Row(
              children: [
                Text(
                  'Motivation ',
                  style: GoogleFonts.inter(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF0F172A),
                  ),
                ),
                Text(
                  '(Optionnel)',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF64748B),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: TextField(
                controller: _motivationController,
                minLines: 3,
                maxLines: 4,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: const Color(0xFF0F172A),
                ),
                decoration: InputDecoration(
                  hintText:
                      'Expliquez brièvement votre choix de cet établissement...',
                  hintStyle: GoogleFonts.inter(
                    fontSize: 13.5,
                    color: const Color(0xFF94A3B8),
                  ),
                  contentPadding: const EdgeInsets.all(14),
                  border: InputBorder.none,
                ),
              ),
            ),

            const SizedBox(height: 20),

            // 3. CARTE RÉSUMÉ FINANCIER
            _CarteResumeFinancier(hopital: _hopital),

            const SizedBox(height: 18),

            // 4. CONDITIONS FOURNIES PAR L'API
            if (_hopital.conditions != null)
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 24,
                    height: 24,
                    child: Checkbox(
                      value: _conditionsAcceptees,
                      activeColor: const Color(0xFF1D61F2),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(5),
                      ),
                      onChanged: (val) =>
                          setState(() => _conditionsAcceptees = val ?? false),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(
                        () => _conditionsAcceptees = !_conditionsAcceptees,
                      ),
                      child: Text(
                        'J\'accepte les conditions suivantes : ${_hopital.conditions}',
                        style: GoogleFonts.inter(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFF475569),
                          height: 1.35,
                        ),
                      ),
                    ),
                  ),
                ],
              ),

            const SizedBox(height: 22),

            // 5. BOUTON CONFIRMER LA RÉSERVATION
            SizedBox(
              width: double.infinity,
              height: 52,
              child: FilledButton(
                onPressed:
                    _enCoursDeSoumission ||
                        !_campagne.autoriseReservationAutonome ||
                        !_hopital.peutReserver
                    ? null
                    : _confirmerReservation,
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF1D61F2),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 0,
                ),
                child: _enCoursDeSoumission
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2.5,
                        ),
                      )
                    : Text(
                        'Confirmer la réservation',
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
              ),
            ),

            const SizedBox(height: 10),

            // Étape suivante du workflow API
            Center(
              child: Text(
                'Votre réservation sera transmise à votre université pour décision.',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFF64748B),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    final unreadNotifs =
        int.tryParse(_counts?['notifications']?.toString() ?? '0') ?? 0;

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
        'Réservation',
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
              onPressed: () async {
                await Navigator.of(context, rootNavigator: true).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const NotificationsPage(),
                  ),
                );
                _chargerCounts();
              },
              icon: const Icon(
                Icons.notifications_none_rounded,
                color: Color(0xFF0F172A),
                size: 26,
              ),
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
                  constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
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
}

// -------------------------------------------------------------
// 1. CARTE VOTRE SÉLECTION
// -------------------------------------------------------------
class _CarteVotreSelection extends StatelessWidget {
  const _CarteVotreSelection({required this.campagne, required this.hopital});

  final CampagneStage campagne;
  final HopitalCampagne hopital;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x06000000),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Tag VOTRE SÉLECTION
          Text(
            'VOTRE SÉLECTION',
            style: GoogleFonts.inter(
              fontSize: 11.5,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.5,
              color: const Color(0xFF1D61F2),
            ),
          ),
          const SizedBox(height: 6),

          // Titre de la campagne
          Text(
            campagne.titre,
            style: GoogleFonts.inter(
              fontSize: 16.5,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF0F172A),
            ),
          ),

          const SizedBox(height: 12),
          Container(height: 1, color: const Color(0xFFF1F5F9)),
          const SizedBox(height: 12),

          // Hôpital avec icône
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Center(
                  child: FaIcon(
                    FontAwesomeIcons.hospital,
                    color: Color(0xFF1D61F2),
                    size: 18,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      hopital.nom,
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 2),
                    if (hopital.localisationCourte.isNotEmpty ||
                        hopital.distanceKm > 0)
                      Text(
                        [
                          if (hopital.localisationCourte.isNotEmpty)
                            hopital.localisationCourte,
                          if (hopital.distanceKm > 0)
                            '${hopital.distanceKm.toStringAsFixed(1)} km',
                        ].join(' • '),
                        style: GoogleFonts.inter(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFF64748B),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Période
          Row(
            children: [
              const Icon(
                Icons.calendar_today_outlined,
                size: 16,
                color: Color(0xFF64748B),
              ),
              const SizedBox(width: 8),
              Text(
                'Période: ${campagne.periodeTexte}',
                style: GoogleFonts.inter(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFF64748B),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// -------------------------------------------------------------
// CARTE RÉSUMÉ FINANCIER
// -------------------------------------------------------------
class _CarteResumeFinancier extends StatelessWidget {
  const _CarteResumeFinancier({required this.hopital});

  final HopitalCampagne hopital;

  String get _montant {
    if (!hopital.fraisRequis) return 'Aucun frais requis';
    if (hopital.montantFrais <= 0) return 'Montant non communiqué';
    final valeur = hopital.montantFrais == hopital.montantFrais.roundToDouble()
        ? hopital.montantFrais.toStringAsFixed(0)
        : hopital.montantFrais.toStringAsFixed(2);
    return '$valeur ${hopital.devise}'.trim();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // En-tête Résumé financier + Montant total
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Résumé financier',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF0F172A),
                ),
              ),
              Flexible(
                child: Text(
                  _montant,
                  textAlign: TextAlign.end,
                  style: GoogleFonts.inter(
                    fontSize: 16.5,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF1D61F2),
                  ),
                ),
              ),
            ],
          ),
          if (hopital.conditions != null) ...[
            const SizedBox(height: 12),
            Container(height: 1, color: const Color(0xFFF1F5F9)),
            const SizedBox(height: 12),
            Text(
              hopital.conditions!,
              style: GoogleFonts.inter(
                fontSize: 12.5,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF64748B),
                height: 1.4,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
