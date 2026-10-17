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

    final modeSombre = Theme.of(context).brightness == Brightness.dark;
    final fondModal = modeSombre ? const Color(0xFF1E293B) : Colors.white;
    final textePrincipal = modeSombre ? Colors.white : const Color(0xFF0F172A);
    final texteSecondaire = modeSombre
        ? const Color(0xFF94A3B8)
        : const Color(0xFF64748B);
    final bordure = modeSombre
        ? const Color(0xFF334155)
        : const Color(0xFFE2E8F0);
    final poignee = modeSombre
        ? const Color(0xFF475569)
        : const Color(0xFFCBD5E1);

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          padding: const EdgeInsets.fromLTRB(22, 16, 22, 32),
          decoration: BoxDecoration(
            color: fondModal,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            border: Border.all(color: bordure),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: poignee,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 24),
              Container(
                width: 68,
                height: 68,
                decoration: BoxDecoration(
                  color: modeSombre
                      ? const Color(0xFF14532D).withValues(alpha: 0.6)
                      : const Color(0xFFDCFCE7),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.check_circle_rounded,
                  color: modeSombre
                      ? const Color(0xFF4ADE80)
                      : const Color(0xFF16A34A),
                  size: 44,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                reservationCreee
                    ? 'Candidature & Réservation soumises !'
                    : 'Réservation déjà active',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: textePrincipal,
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
                  color: texteSecondaire,
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
                    color: modeSombre
                        ? const Color(0xFF0F172A).withValues(alpha: 0.6)
                        : const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: bordure),
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
                    color: texteSecondaire,
                  ),
                ),
              ],
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: FilledButton(
                  onPressed: () {
                    Navigator.of(ctx).pop();
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
    final modeSombre = Theme.of(context).brightness == Brightness.dark;
    final fondPage = modeSombre
        ? const Color(0xFF0F172A)
        : const Color(0xFFF8FAFC);
    final fondCarte = modeSombre ? const Color(0xFF1E293B) : Colors.white;
    final bordure = modeSombre
        ? const Color(0xFF334155)
        : const Color(0xFFE2E8F0);
    final textePrincipal = modeSombre ? Colors.white : const Color(0xFF0F172A);
    final texteSecondaire = modeSombre
        ? const Color(0xFF94A3B8)
        : const Color(0xFF64748B);

    return Scaffold(
      backgroundColor: fondPage,
      appBar: _buildAppBar(context, modeSombre),
      body: SafeArea(
        child: ListView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
          children: [
            // 1. CARTE VOTRE SÉLECTION
            _CarteVotreSelection(
              campagne: _campagne,
              hopital: _hopital,
              modeSombre: modeSombre,
            ),

            const SizedBox(height: 22),

            // 2. CHAMP MOTIVATION (OPTIONNEL)
            Row(
              children: [
                Text(
                  'Motivation ',
                  style: GoogleFonts.inter(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w800,
                    color: textePrincipal,
                  ),
                ),
                Text(
                  '(Optionnel)',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: texteSecondaire,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: fondCarte,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: bordure),
              ),
              child: TextField(
                controller: _motivationController,
                minLines: 3,
                maxLines: 4,
                cursorColor: const Color(0xFF1D61F2),
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: textePrincipal,
                ),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: fondCarte,
                  hintText:
                      'Expliquez brièvement votre choix de cet établissement...',
                  hintStyle: GoogleFonts.inter(
                    fontSize: 13.5,
                    color: texteSecondaire,
                  ),
                  contentPadding: const EdgeInsets.all(14),
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                ),
              ),
            ),

            const SizedBox(height: 20),

            // 3. CARTE RÉSUMÉ FINANCIER
            _CarteResumeFinancier(
              hopital: _hopital,
              modeSombre: modeSombre,
            ),

            const SizedBox(height: 18),

            // 4. CONDITIONS FOURNIES PAR L'API
            if (_hopital.conditions != null)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: modeSombre
                      ? const Color(0xFF1E293B).withValues(alpha: 0.6)
                      : const Color(0xFFF1F5F9).withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: bordure),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 24,
                      height: 24,
                      child: Checkbox(
                        value: _conditionsAcceptees,
                        activeColor: const Color(0xFF1D61F2),
                        checkColor: Colors.white,
                        side: BorderSide(
                          color: modeSombre
                              ? const Color(0xFF64748B)
                              : const Color(0xFF94A3B8),
                          width: 1.5,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(5),
                        ),
                        onChanged: (val) =>
                            setState(() => _conditionsAcceptees = val ?? false),
                      ),
                    ),
                    const SizedBox(width: 12),
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
                            color: textePrincipal,
                            height: 1.35,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
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
                  disabledBackgroundColor: modeSombre
                      ? const Color(0xFF334155)
                      : const Color(0xFFCBD5E1),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
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
                          color: Colors.white,
                        ),
                      ),
              ),
            ),

            const SizedBox(height: 12),

            // Étape suivante du workflow API
            Center(
              child: Text(
                'Votre réservation sera transmise à votre université pour décision.',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: texteSecondaire,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context, bool modeSombre) {
    final unreadNotifs =
        int.tryParse(_counts?['notifications']?.toString() ?? '0') ?? 0;
    final textePrincipal = modeSombre ? Colors.white : const Color(0xFF0F172A);
    final fondAppBar = modeSombre
        ? const Color(0xFF0F172A)
        : const Color(0xFFF8FAFC);

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
          color: textePrincipal,
        ),
        onPressed: () => Navigator.of(context).maybePop(),
      ),
      title: Text(
        'Réservation',
        style: GoogleFonts.inter(
          fontSize: 18,
          fontWeight: FontWeight.w800,
          color: textePrincipal,
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
              icon: Icon(
                Icons.notifications_none_rounded,
                color: textePrincipal,
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
  const _CarteVotreSelection({
    required this.campagne,
    required this.hopital,
    required this.modeSombre,
  });

  final CampagneStage campagne;
  final HopitalCampagne hopital;
  final bool modeSombre;

  @override
  Widget build(BuildContext context) {
    final fondCarte = modeSombre ? const Color(0xFF1E293B) : Colors.white;
    final bordure = modeSombre
        ? const Color(0xFF334155)
        : const Color(0xFFE2E8F0);
    final textePrincipal = modeSombre ? Colors.white : const Color(0xFF0F172A);
    final texteSecondaire = modeSombre
        ? const Color(0xFF94A3B8)
        : const Color(0xFF64748B);
    final separateur = modeSombre
        ? const Color(0xFF334155)
        : const Color(0xFFF1F5F9);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: fondCarte,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: bordure),
        boxShadow: [
          BoxShadow(
            color: modeSombre
                ? const Color(0x30000000)
                : const Color(0x06000000),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Tag VOTRE SÉLECTION
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: modeSombre
                      ? const Color(0xFF1E3A8A).withValues(alpha: 0.5)
                      : const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  'VOTRE SÉLECTION',
                  style: GoogleFonts.inter(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                    color: const Color(0xFF1D61F2),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Titre de la campagne
          Text(
            campagne.titre,
            style: GoogleFonts.inter(
              fontSize: 16.5,
              fontWeight: FontWeight.w800,
              color: textePrincipal,
            ),
          ),

          const SizedBox(height: 12),
          Divider(height: 1, color: separateur),
          const SizedBox(height: 12),

          // Hôpital avec icône
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: modeSombre
                      ? const Color(0xFF1E3A8A).withValues(alpha: 0.4)
                      : const Color(0xFFEFF6FF),
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
                        color: textePrincipal,
                      ),
                    ),
                    const SizedBox(height: 3),
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
                          color: texteSecondaire,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          // Période
          Row(
            children: [
              Icon(
                Icons.calendar_today_outlined,
                size: 16,
                color: texteSecondaire,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Période : ${campagne.periodeTexte}',
                  style: GoogleFonts.inter(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w500,
                    color: texteSecondaire,
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

// -------------------------------------------------------------
// CARTE RÉSUMÉ FINANCIER
// -------------------------------------------------------------
class _CarteResumeFinancier extends StatelessWidget {
  const _CarteResumeFinancier({
    required this.hopital,
    required this.modeSombre,
  });

  final HopitalCampagne hopital;
  final bool modeSombre;

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
    final fondCarte = modeSombre ? const Color(0xFF1E293B) : Colors.white;
    final bordure = modeSombre
        ? const Color(0xFF334155)
        : const Color(0xFFE2E8F0);
    final textePrincipal = modeSombre ? Colors.white : const Color(0xFF0F172A);
    final texteSecondaire = modeSombre
        ? const Color(0xFF94A3B8)
        : const Color(0xFF64748B);
    final separateur = modeSombre
        ? const Color(0xFF334155)
        : const Color(0xFFF1F5F9);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: fondCarte,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: bordure),
        boxShadow: [
          BoxShadow(
            color: modeSombre
                ? const Color(0x30000000)
                : const Color(0x06000000),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
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
                  color: textePrincipal,
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
            Divider(height: 1, color: separateur),
            const SizedBox(height: 12),
            Text(
              hopital.conditions!,
              style: GoogleFonts.inter(
                fontSize: 12.5,
                fontWeight: FontWeight.w500,
                color: texteSecondaire,
                height: 1.4,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
