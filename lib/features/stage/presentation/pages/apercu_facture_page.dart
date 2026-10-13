import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/network/client_api_http.dart';
import '../../../../core/network/source_etudiant_distante.dart';
import '../../../../core/network/reponse_api.dart';
import '../../../../core/widgets/contenu_adaptatif.dart';
import '../../../../core/widgets/erreur_chargement_api.dart';
import 'paiement_mobile_page.dart';

class ApercuFacturePage extends StatefulWidget {
  const ApercuFacturePage({
    required this.obligationUuid,
    this.obligationInitiale,
    super.key,
  });

  final String obligationUuid;
  final Map<String, dynamic>? obligationInitiale;

  @override
  State<ApercuFacturePage> createState() => _ApercuFacturePageState();
}

class _ApercuFacturePageState extends State<ApercuFacturePage> {
  final _source = SourceEtudiantDistante(ClientApiHttp());
  late Future<Map<String, dynamic>> _chargement;
  bool _enCoursDeSync = false;

  @override
  void initState() {
    super.initState();
    _chargement = _charger();
  }

  Future<Map<String, dynamic>> _charger() async {
    return _source.detailPaiement(widget.obligationUuid);
  }

  Future<void> _actualiser() async {
    final futur = _charger();
    setState(() => _chargement = futur);
    await futur;
  }

  Future<void> _synchroniser() async {
    setState(() => _enCoursDeSync = true);
    try {
      final res = await _source.paiementSync(
        obligationUuid: widget.obligationUuid,
      );
      if (!mounted) return;
      setState(() => _enCoursDeSync = false);

      final paymentStatus = (res['payment_status'] ?? '').toString();
      final msg = res['message']?.toString() ?? 'État synchronisé avec succès.';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(msg),
          backgroundColor: paymentStatus == 'PAID'
              ? const Color(0xFF16A34A)
              : const Color(0xFF2563EB),
        ),
      );
      _actualiser();
    } on ErreurApi catch (e) {
      if (!mounted) return;
      setState(() => _enCoursDeSync = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message), backgroundColor: const Color(0xFFEF4444)),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _enCoursDeSync = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur : $e'), backgroundColor: const Color(0xFFEF4444)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final modeSombre = Theme.of(context).brightness == Brightness.dark;
    final fondPage = modeSombre ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC);
    final texteCouleur = modeSombre ? Colors.white : const Color(0xFF0F172A);

    return Scaffold(
      backgroundColor: fondPage,
      appBar: AppBar(
        backgroundColor: fondPage,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            color: texteCouleur,
            size: 20,
          ),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: Text(
          'Aperçu de la facture',
          style: GoogleFonts.inter(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: texteCouleur,
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Synchroniser l’état',
            icon: _enCoursDeSync
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFFFF751F)),
                  )
                : const Icon(Icons.sync_rounded, color: Color(0xFFFF751F)),
            onPressed: _enCoursDeSync ? null : _synchroniser,
          ),
        ],
        centerTitle: false,
      ),
      body: ContenuAdaptatif(
        largeurMaximale: 640,
        enfant: FutureBuilder<Map<String, dynamic>>(
          future: _chargement,
          initialData: widget.obligationInitiale != null
              ? {'obligation': widget.obligationInitiale!}
              : null,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting &&
                !snapshot.hasData) {
              return const Center(
                child: CircularProgressIndicator(color: Color(0xFFFF751F)),
              );
            }
            if (snapshot.hasError && !snapshot.hasData) {
              return ErreurChargementApi(
                erreur: snapshot.error,
                onReessayer: _actualiser,
              );
            }

            final data = snapshot.data ?? {};
            final obligation = data['obligation'] is Map
                ? Map<String, dynamic>.from(data['obligation'] as Map)
                : (widget.obligationInitiale ?? <String, dynamic>{});

            if (obligation.isEmpty) {
              return Center(
                child: Text(
                  'Facture introuvable.',
                  style: GoogleFonts.inter(color: texteCouleur),
                ),
              );
            }

            final contextData = obligation['context'] is Map
                ? Map<String, dynamic>.from(obligation['context'] as Map)
                : null;
            final invoice = contextData?['invoice'] is Map
                ? Map<String, dynamic>.from(contextData!['invoice'] as Map)
                : null;
            final campaign = contextData?['campaign'] is Map
                ? Map<String, dynamic>.from(contextData!['campaign'] as Map)
                : null;
            final hospital = contextData?['hospital'] is Map
                ? Map<String, dynamic>.from(contextData!['hospital'] as Map)
                : null;

            final status = (obligation['status'] ?? '').toString().toUpperCase();
            final estPayee = status == 'PAID' || invoice?['status'] == 'PAYEE';
            final payable = obligation['payable'] == true && !estPayee;

            final montantTotal = obligation['amount'] ?? invoice?['amount'] ?? 0;
            final montantRestant = obligation['amount_remaining'] ?? (estPayee ? 0 : montantTotal);
            final devise = obligation['currency'] ?? invoice?['currency'] ?? 'USD';
            final referenceObligation = obligation['reference'] ?? 'OBL-STAGE';
            final referenceFacture = invoice?['reference'] ?? 'FAC-STAGE';
            final dateFacture = invoice?['issued_at'] ?? '2026-10-08';

            final nomHopital = hospital?['name']?.toString() ?? 'Hôpital Général';
            final titreCampagne = campaign?['title']?.toString() ?? "Stage de fin d'année 2026";

            return Column(
              children: [
                Expanded(
                  child: ListView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                    children: [
                      // Badge de statut en haut
                      _buildBanniereStatut(
                        modeSombre: modeSombre,
                        estPayee: estPayee,
                        enAttente: obligation['payment_pending'] == true,
                      ),

                      const SizedBox(height: 16),

                      // Carte principale de la facture
                      _buildFactureCard(
                        modeSombre: modeSombre,
                        referenceFacture: referenceFacture,
                        referenceObligation: referenceObligation,
                        dateFacture: dateFacture,
                        titreCampagne: titreCampagne,
                        nomHopital: nomHopital,
                        montantTotal: montantTotal,
                        montantRestant: montantRestant,
                        devise: devise,
                        estPayee: estPayee,
                      ),

                      const SizedBox(height: 18),

                      // Historique des transactions
                      if (obligation['payments'] is List &&
                          (obligation['payments'] as List).isNotEmpty)
                        _buildSectionPaiements(
                          modeSombre: modeSombre,
                          paiements: (obligation['payments'] as List)
                              .whereType<Map>()
                              .map(Map<String, dynamic>.from)
                              .toList(),
                          devise: devise,
                        ),
                    ],
                  ),
                ),

                // Bouton d'action inférieur
                Container(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                  decoration: BoxDecoration(
                    color: modeSombre ? const Color(0xFF1E293B) : Colors.white,
                    border: Border(
                      top: BorderSide(
                        color: modeSombre ? const Color(0xFF334155) : const Color(0xFFF1F5F9),
                      ),
                    ),
                  ),
                  child: SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: estPayee
                        ? OutlinedButton.icon(
                            onPressed: () => Navigator.of(context).maybePop(),
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: Color(0xFF16A34A)),
                              foregroundColor: const Color(0xFF16A34A),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            icon: const Icon(Icons.check_circle_rounded, size: 20),
                            label: Text(
                              'Facture réglée avec succès',
                              style: GoogleFonts.inter(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          )
                        : FilledButton.icon(
                            onPressed: !payable
                                ? null
                                : () async {
                                    final res = await Navigator.of(context).push<bool>(
                                      MaterialPageRoute<bool>(
                                        builder: (_) => PaiementMobilePage(
                                          obligationUuid: widget.obligationUuid,
                                          montant: montantRestant,
                                          devise: devise,
                                          reference: referenceObligation,
                                          nomHopital: nomHopital,
                                          titreCampagne: titreCampagne,
                                        ),
                                      ),
                                    );
                                    if (res == true && mounted) {
                                      _actualiser();
                                    }
                                  },
                            style: FilledButton.styleFrom(
                              backgroundColor: const Color(0xFFFF751F),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            icon: const Icon(Icons.payment_rounded, size: 20),
                            label: Text(
                              'Passer au paiement ($montantRestant $devise)',
                              style: GoogleFonts.inter(
                                fontSize: 15.5,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildBanniereStatut({
    required bool modeSombre,
    required bool estPayee,
    required bool enAttente,
  }) {
    final couleur = estPayee
        ? const Color(0xFF16A34A)
        : (enAttente ? const Color(0xFF2563EB) : const Color(0xFFEA580C));
    final fond = estPayee
        ? (modeSombre ? const Color(0xFF064E3B).withValues(alpha: 0.35) : const Color(0xFFDCFCE7))
        : (enAttente
            ? (modeSombre ? const Color(0xFF1E3A8A).withValues(alpha: 0.35) : const Color(0xFFEFF6FF))
            : (modeSombre ? const Color(0xFF7C2D12).withValues(alpha: 0.35) : const Color(0xFFFFEDD5)));

    final titre = estPayee
        ? 'Facture réglée'
        : (enAttente ? 'Paiement en cours de traitement' : 'Paiement requis');

    final message = estPayee
        ? 'Le montant a été validé. Votre place est confirmée et transmise à l’université.'
        : (enAttente
            ? 'Une transaction a été initiée. Vous pouvez synchroniser le statut une fois le code PIN saisi.'
            : 'Votre candidature a été approuvée par l’université. Veuillez régler pour finaliser votre affectation.');

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: fond,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: couleur.withValues(alpha: 0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            estPayee
                ? Icons.verified_rounded
                : (enAttente ? Icons.hourglass_top_rounded : Icons.info_outline_rounded),
            color: couleur,
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  titre,
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: couleur,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  message,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: modeSombre ? const Color(0xFFE2E8F0) : const Color(0xFF334155),
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFactureCard({
    required bool modeSombre,
    required String referenceFacture,
    required String referenceObligation,
    required String dateFacture,
    required String titreCampagne,
    required String nomHopital,
    required dynamic montantTotal,
    required dynamic montantRestant,
    required String devise,
    required bool estPayee,
  }) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: modeSombre ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: modeSombre ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
        ),
        boxShadow: [
          BoxShadow(
            color: modeSombre ? Colors.black.withValues(alpha: 0.15) : const Color(0x06000000),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  'Détails de l’obligation',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: modeSombre ? Colors.white : const Color(0xFF0F172A),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: modeSombre ? const Color(0xFF334155) : const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    referenceFacture,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: modeSombre ? const Color(0xFFCBD5E1) : const Color(0xFF475569),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          _buildLigneDetail('Référence obligation', referenceObligation, modeSombre),
          _buildLigneDetail('Campagne de stage', titreCampagne, modeSombre),
          _buildLigneDetail('Établissement / Hôpital', nomHopital, modeSombre),
          _buildLigneDetail('Date d’émission', dateFacture, modeSombre),

          const SizedBox(height: 16),
          Divider(
            height: 1,
            color: modeSombre ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
          ),
          const SizedBox(height: 16),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total à régler',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: modeSombre ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                ),
              ),
              Text(
                '$montantTotal $devise',
                style: GoogleFonts.inter(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: modeSombre ? Colors.white : const Color(0xFF0F172A),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                estPayee ? 'Montant acquitté' : 'Solde restant dû',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: modeSombre ? Colors.white : const Color(0xFF0F172A),
                ),
              ),
              Text(
                estPayee ? '$montantTotal $devise' : '$montantRestant $devise',
                style: GoogleFonts.inter(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: estPayee
                      ? (modeSombre ? const Color(0xFF4ADE80) : const Color(0xFF16A34A))
                      : const Color(0xFFFF751F),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLigneDetail(String label, String valeur, bool modeSombre) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: modeSombre ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 3,
            child: Text(
              valeur,
              textAlign: TextAlign.right,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: modeSombre ? Colors.white : const Color(0xFF0F172A),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionPaiements({
    required bool modeSombre,
    required List<Map<String, dynamic>> paiements,
    required String devise,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Transactions associées',
          style: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: modeSombre ? Colors.white : const Color(0xFF0F172A),
          ),
        ),
        const SizedBox(height: 10),
        ...paiements.map((pay) {
          final ref = pay['reference'] ?? 'PAY';
          final montant = pay['amount'] ?? 0;
          final status = (pay['status'] ?? '').toString();
          final channel = pay['channel'] ?? 'MOBILE MONEY';
          final date = pay['initiated_at'] ?? '';

          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: modeSombre ? const Color(0xFF1E293B) : Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: modeSombre ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$ref • $channel',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: modeSombre ? Colors.white : const Color(0xFF0F172A),
                      ),
                    ),
                    if (date.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        date,
                        style: GoogleFonts.inter(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFF94A3B8),
                        ),
                      ),
                    ],
                  ],
                ),
                Text(
                  '$montant $devise ($status)',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: status == 'VALIDE' || status == 'PAID'
                        ? const Color(0xFF16A34A)
                        : const Color(0xFFFF751F),
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }
}
