import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/network/client_api_http.dart';
import '../../../../core/network/reponse_api.dart';
import '../../../notifications/presentation/pages/notifications_page.dart';
import '../../data/datasources/source_campagne_mock.dart';
import '../../data/datasources/source_stage_distante.dart';
import '../../domain/entities/campagne_stage.dart';

class ReservationPage extends StatefulWidget {
  const ReservationPage({
    this.campagne,
    this.hopital,
    super.key,
  });

  final CampagneStage? campagne;
  final HopitalCampagne? hopital;

  @override
  State<ReservationPage> createState() => _ReservationPageState();
}

class _ReservationPageState extends State<ReservationPage> {
  final _source = SourceStageDistante(ClientApiHttp());
  late final CampagneStage _campagne;
  late final HopitalCampagne _hopital;

  late String _serviceSelectionne;
  String _periodeSelectionnee = 'Matin (7h-13h)';
  final TextEditingController _motivationController = TextEditingController();
  bool _conditionsAcceptees = true;
  bool _enCoursDeSoumission = false;

  final List<String> _periodesDisponibles = const [
    'Matin (7h-13h)',
    'Après-midi (13h-18h)',
    'Garde (Nuit 18h-8h)',
  ];

  @override
  void initState() {
    super.initState();
    _campagne = widget.campagne ?? SourceCampagneMock.obtenirCampagneOuverte();
    _hopital = widget.hopital ??
        (_campagne.hopitaux.isNotEmpty
            ? _campagne.hopitaux.first
            : SourceCampagneMock.campagnePrincipale.hopitaux.first);

    _serviceSelectionne = _hopital.services.isNotEmpty
        ? _hopital.services.first
        : 'Pédiatrie';
  }

  @override
  void dispose() {
    _motivationController.dispose();
    super.dispose();
  }

  void _confirmerReservation() async {
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

    final participationIdNum = int.tryParse(
          _hopital.id.replaceAll(RegExp(r'[^0-9]'), ''),
        ) ??
        101;
    final campaignIdNum = int.tryParse(
          _campagne.id.replaceAll(RegExp(r'[^0-9]'), ''),
        ) ??
        1;

    try {
      final resultat = await _source.reserver(
        campaignId: campaignIdNum,
        academicEnrollmentId: 1,
        participationId: participationIdNum,
        motivation: _motivationController.text.trim().isEmpty
            ? 'Candidature pour le service $_serviceSelectionne'
            : _motivationController.text.trim(),
        cleOption: '${_campagne.id}::${_hopital.id}',
        campagneTitre: _campagne.titre,
        etablissementNom: _hopital.nom,
        localisation:
            _hopital.adresse ?? '${_hopital.commune}, ${_hopital.ville}',
      );

      if (!mounted) return;
      setState(() => _enCoursDeSoumission = false);

      final donnees = resultat['data'] is Map
          ? Map<String, dynamic>.from(resultat['data'] as Map)
          : resultat;
      final ref = donnees['reservation_uuid']?.toString() ??
          donnees['reference']?.toString() ??
          'STG-RES-84920';

      _afficherConfirmationModal(ref);
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

  void _afficherConfirmationModal(String reference) {
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
                'Réservation confirmée !',
                style: GoogleFonts.inter(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Votre place a été pré-réservée auprès de ${_hopital.nom}.',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFF64748B),
                ),
              ),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Text(
                  'Référence : $reference',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF1D61F2),
                  ),
                ),
              ),
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

  void _ouvrirSelectionService() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 38,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE2E8F0),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Text(
                'Choisir un service',
                style: GoogleFonts.inter(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 14),
              ..._hopital.services.map((service) {
                final estChoisi = service == _serviceSelectionne;
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(
                    Icons.medical_services_outlined,
                    color: estChoisi
                        ? const Color(0xFF1D61F2)
                        : const Color(0xFF64748B),
                  ),
                  title: Text(
                    service,
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      fontWeight: estChoisi ? FontWeight.w700 : FontWeight.w500,
                      color: estChoisi
                          ? const Color(0xFF1D61F2)
                          : const Color(0xFF0F172A),
                    ),
                  ),
                  trailing: estChoisi
                      ? const Icon(Icons.check_rounded, color: Color(0xFF1D61F2))
                      : null,
                  onTap: () {
                    setState(() => _serviceSelectionne = service);
                    Navigator.of(ctx).pop();
                  },
                );
              }),
            ],
          ),
        );
      },
    );
  }

  void _ouvrirSelectionPeriode() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 38,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE2E8F0),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Text(
                'Période préférée',
                style: GoogleFonts.inter(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 14),
              ..._periodesDisponibles.map((periode) {
                final estChoisi = periode == _periodeSelectionnee;
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(
                    Icons.access_time_rounded,
                    color: estChoisi
                        ? const Color(0xFF1D61F2)
                        : const Color(0xFF64748B),
                  ),
                  title: Text(
                    periode,
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      fontWeight: estChoisi ? FontWeight.w700 : FontWeight.w500,
                      color: estChoisi
                          ? const Color(0xFF1D61F2)
                          : const Color(0xFF0F172A),
                    ),
                  ),
                  trailing: estChoisi
                      ? const Icon(Icons.check_rounded, color: Color(0xFF1D61F2))
                      : null,
                  onTap: () {
                    setState(() => _periodeSelectionnee = periode);
                    Navigator.of(ctx).pop();
                  },
                );
              }),
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
            _CarteVotreSelection(
              campagne: _campagne,
              hopital: _hopital,
            ),

            const SizedBox(height: 22),

            // 2. CHAMP SERVICE SOUHAITÉ
            Text(
              'Service souhaité',
              style: GoogleFonts.inter(
                fontSize: 14.5,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 8),
            _ChampSelecteur(
              icone: Icons.medical_services_outlined,
              valeur: _serviceSelectionne,
              onTap: _ouvrirSelectionService,
            ),

            const SizedBox(height: 18),

            // 3. CHAMP PÉRIODE PRÉFÉRÉE
            Text(
              'Période préférée',
              style: GoogleFonts.inter(
                fontSize: 14.5,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 8),
            _ChampSelecteur(
              icone: Icons.access_time_rounded,
              valeur: _periodeSelectionnee,
              onTap: _ouvrirSelectionPeriode,
            ),

            const SizedBox(height: 18),

            // 4. CHAMP MOTIVATION (OPTIONNEL)
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
                  hintText: 'Expliquez brièvement votre choix de service...',
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

            // 5. CARTE RÉSUMÉ FINANCIER
            _CarteResumeFinancier(campagne: _campagne),

            const SizedBox(height: 18),

            // 6. CASE À COCHER CONDITIONS
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
                      'J\'accepte les conditions de stage et le règlement intérieur.',
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

            // 7. BOUTON CONFIRMER LA RÉSERVATION
            SizedBox(
              width: double.infinity,
              height: 52,
              child: FilledButton(
                onPressed: _enCoursDeSoumission ? null : _confirmerReservation,
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

            // Mention de validation sous 48h
            Center(
              child: Text(
                'Votre réservation sera soumise à validation sous 48h',
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
              onPressed: () => Navigator.of(context, rootNavigator: true).push(
                MaterialPageRoute<void>(
                  builder: (_) => const NotificationsPage(),
                ),
              ),
              icon: const Icon(
                Icons.notifications_none_rounded,
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
}

// -------------------------------------------------------------
// 1. CARTE VOTRE SÉLECTION
// -------------------------------------------------------------
class _CarteVotreSelection extends StatelessWidget {
  const _CarteVotreSelection({
    required this.campagne,
    required this.hopital,
  });

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
          Container(
            height: 1,
            color: const Color(0xFFF1F5F9),
          ),
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
                    Text(
                      '${hopital.localisationCourte} • ${hopital.distanceKm.toStringAsFixed(1)} km',
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
// COMPOSANT CHAMP SELECTEUR (DROPDOWN MODERNE)
// -------------------------------------------------------------
class _ChampSelecteur extends StatelessWidget {
  const _ChampSelecteur({
    required this.icone,
    required this.valeur,
    required this.onTap,
  });

  final IconData icone;
  final String valeur;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Row(
          children: [
            Icon(icone, color: const Color(0xFF64748B), size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                valeur,
                style: GoogleFonts.inter(
                  fontSize: 14.5,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF0F172A),
                ),
              ),
            ),
            const Icon(
              Icons.keyboard_arrow_down_rounded,
              color: Color(0xFF64748B),
              size: 22,
            ),
          ],
        ),
      ),
    );
  }
}

// -------------------------------------------------------------
// CARTE RÉSUMÉ FINANCIER
// -------------------------------------------------------------
class _CarteResumeFinancier extends StatelessWidget {
  const _CarteResumeFinancier({required this.campagne});

  final CampagneStage campagne;

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
              Text(
                campagne.indemnite,
                style: GoogleFonts.inter(
                  fontSize: 16.5,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF1D61F2),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),
          Container(
            height: 1,
            color: const Color(0xFFF1F5F9),
          ),
          const SizedBox(height: 12),

          // Ligne 1ère tranche
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Text(
                    '1ère tranche ',
                    style: GoogleFonts.inter(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF475569),
                    ),
                  ),
                  Text(
                    '(Acompte requis)',
                    style: GoogleFonts.inter(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w400,
                      color: const Color(0xFF94A3B8),
                    ),
                  ),
                ],
              ),
              Text(
                '75 000 FC',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF0F172A),
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          // Ligne 2ème tranche
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Text(
                    '2ème tranche ',
                    style: GoogleFonts.inter(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF475569),
                    ),
                  ),
                  Text(
                    '(Mi-parcours)',
                    style: GoogleFonts.inter(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w400,
                      color: const Color(0xFF94A3B8),
                    ),
                  ),
                ],
              ),
              Text(
                '75 000 FC',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF0F172A),
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),
          _LignePointillee(),
          const SizedBox(height: 14),

          // Moyens de paiement acceptés
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Moyens de paiement acceptés',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFF64748B),
                ),
              ),
              Row(
                children: [
                  _BadgePaiement(
                    child: const Icon(
                      Icons.credit_card_rounded,
                      size: 16,
                      color: Color(0xFF64748B),
                    ),
                  ),
                  const SizedBox(width: 6),
                  _BadgePaiement(
                    child: const Icon(
                      Icons.account_balance_wallet_outlined,
                      size: 16,
                      color: Color(0xFF64748B),
                    ),
                  ),
                  const SizedBox(width: 6),
                  _BadgePaiement(
                    child: const Icon(
                      Icons.payments_outlined,
                      size: 16,
                      color: Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _BadgePaiement extends StatelessWidget {
  const _BadgePaiement({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: child,
    );
  }
}

class _LignePointillee extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const double tiretLargeur = 4.0;
        const double espaceLargeur = 3.0;
        final int nombre =
            (constraints.maxWidth / (tiretLargeur + espaceLargeur)).floor();

        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(nombre, (_) {
            return Container(
              width: tiretLargeur,
              height: 1,
              color: const Color(0xFFCBD5E1),
            );
          }),
        );
      },
    );
  }
}
