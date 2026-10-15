import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/network/client_api_http.dart';
import '../../../../core/network/source_etudiant_distante.dart';
import '../../../../core/network/reponse_api.dart';
import '../../../../core/widgets/contenu_adaptatif.dart';

class PaiementMobilePage extends StatefulWidget {
  const PaiementMobilePage({
    required this.obligationUuid,
    required this.montant,
    required this.devise,
    required this.reference,
    this.nomHopital,
    this.titreCampagne,
    super.key,
  });

  final String obligationUuid;
  final num montant;
  final String devise;
  final String reference;
  final String? nomHopital;
  final String? titreCampagne;

  @override
  State<PaiementMobilePage> createState() => _PaiementMobilePageState();
}

class _OperateurMobile {
  const _OperateurMobile({
    required this.cle,
    required this.nom,
    required this.logoAsset,
    required this.prefixeIndicatif,
    required this.couleurAccent,
  });

  final String cle;
  final String nom;
  final String logoAsset;
  final String prefixeIndicatif;
  final Color couleurAccent;
}

class _PaiementMobilePageState extends State<PaiementMobilePage> {
  final _source = SourceEtudiantDistante(ClientApiHttp());
  final _phoneController = TextEditingController(text: '+243');
  final _focusNodePhone = FocusNode();

  static const List<_OperateurMobile> _operateurs = [
    _OperateurMobile(
      cle: 'MPESA',
      nom: 'M-Pesa (Vodacom)',
      logoAsset: 'assets/images/operateurs/mpesa.png',
      prefixeIndicatif: '+24381',
      couleurAccent: Color(0xFFE60000),
    ),
    _OperateurMobile(
      cle: 'ORANGE_MONEY',
      nom: 'Orange Money',
      logoAsset: 'assets/images/operateurs/orange_money.png',
      prefixeIndicatif: '+24389',
      couleurAccent: Color(0xFFFF6600),
    ),
    _OperateurMobile(
      cle: 'AIRTEL_MONEY',
      nom: 'Airtel Money',
      logoAsset: 'assets/images/operateurs/airtel_money.png',
      prefixeIndicatif: '+24399',
      couleurAccent: Color(0xFFED1C24),
    ),
    _OperateurMobile(
      cle: 'AFRIMONEY',
      nom: 'Afrimoney (Africell)',
      logoAsset: 'assets/images/operateurs/afrimoney-logo.png',
      prefixeIndicatif: '+24390',
      couleurAccent: Color(0xFF8B2582),
    ),
  ];

  late _OperateurMobile _operateurSelectionne;
  late final String _idempotencyKey;
  bool _enCoursTraitement = false;

  @override
  void initState() {
    super.initState();
    _operateurSelectionne = _operateurs.first;
    _idempotencyKey =
        'mobile-${DateTime.now().microsecondsSinceEpoch}-${widget.obligationUuid.hashCode.abs()}';
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _focusNodePhone.dispose();
    super.dispose();
  }

  Future<void> _procederPaiement() async {
    final phone = _phoneController.text.trim();
    if (phone.isEmpty || phone.length < 9) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez entrer un numéro Mobile Money valide.'),
          backgroundColor: Color(0xFFEF4444),
        ),
      );
      _focusNodePhone.requestFocus();
      return;
    }

    // Masque le clavier
    FocusScope.of(context).unfocus();

    setState(() => _enCoursTraitement = true);

    try {
      final resultat = await _source.initierPaiement(
        obligationUuid: widget.obligationUuid,
        channel: _operateurSelectionne.cle,
        phoneNumber: phone,
        idempotencyKey: _idempotencyKey,
      );

      if (!mounted) return;
      setState(() => _enCoursTraitement = false);

      final paiement = resultat['payment'] is Map
          ? Map<String, dynamic>.from(resultat['payment'] as Map)
          : <String, dynamic>{};
      final statut = (paiement['status'] ?? '').toString().toUpperCase();
      if (const {'PAID', 'SUCCEEDED', 'CONFIRME'}.contains(statut)) {
        _afficherSuccesModal();
      } else if (const {
        'FAILED',
        'CANCELLED',
        'ANNULE',
        'EXPIRED',
      }.contains(statut)) {
        _afficherErreurPaiement(
          'La demande de paiement n’a pas abouti. Vérifiez le numéro et réessayez.',
        );
      } else {
        _afficherBoiteDialogueAttente(resultat);
      }
    } on ErreurApi catch (e) {
      if (!mounted) return;
      setState(() => _enCoursTraitement = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.message),
          backgroundColor: const Color(0xFFEF4444),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      setState(() => _enCoursTraitement = false);
      _afficherErreurPaiement(
        'Impossible d’initier le paiement pour le moment.',
      );
    }
  }

  Future<void> _synchroniserStatut(BuildContext dialogCtx) async {
    Navigator.of(dialogCtx).pop(); // Ferme le modal d'attente

    setState(() => _enCoursTraitement = true);
    try {
      final syncResult = await _source.paiementSync(
        obligationUuid: widget.obligationUuid,
      );

      if (!mounted) return;
      setState(() => _enCoursTraitement = false);

      final paymentStatus = (syncResult['payment_status'] ?? '').toString();
      final statutNormalise = paymentStatus.toUpperCase();
      if (statutNormalise == 'PAID' ||
          syncResult['invoice_status'] == 'PAYEE') {
        _afficherSuccesModal();
      } else if (const {
        'FAILED',
        'CANCELLED',
        'EXPIRED',
        'NOT_CONFIRMED',
      }.contains(statutNormalise)) {
        _afficherErreurPaiement(
          statutNormalise == 'NOT_CONFIRMED'
              ? 'Le paiement n’a pas encore été confirmé par l’opérateur.'
              : 'Le paiement a échoué ou a été annulé. Vous pouvez réessayer.',
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Le paiement est en cours de traitement par l’opérateur. Veuillez réessayer la synchronisation dans un instant.',
            ),
            backgroundColor: Color(0xFFF59E0B),
          ),
        );
      }
    } on ErreurApi catch (e) {
      if (!mounted) return;
      setState(() => _enCoursTraitement = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.message),
          backgroundColor: const Color(0xFFEF4444),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      setState(() => _enCoursTraitement = false);
      _afficherErreurPaiement(
        'Impossible de synchroniser le paiement pour le moment.',
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

  void _afficherBoiteDialogueAttente(Map<String, dynamic> donnees) {
    final modeSombre = Theme.of(context).brightness == Brightness.dark;

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: modeSombre ? const Color(0xFF1E293B) : Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFFF751F).withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.phone_android_rounded,
                  color: Color(0xFFFF751F),
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Validation requise',
                  style: GoogleFonts.inter(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: modeSombre ? Colors.white : const Color(0xFF0F172A),
                  ),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Une notification de paiement a été envoyée sur votre téléphone ${_phoneController.text}.',
                style: GoogleFonts.inter(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w500,
                  color: modeSombre
                      ? const Color(0xFFCBD5E1)
                      : const Color(0xFF334155),
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: modeSombre
                      ? const Color(0xFF0F172A)
                      : const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: modeSombre
                        ? const Color(0xFF334155)
                        : const Color(0xFFE2E8F0),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.pin_outlined,
                      color: Color(0xFFFF751F),
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Composez votre code secret Mobile Money pour approuver la transaction.',
                        style: GoogleFonts.inter(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          color: modeSombre
                              ? Colors.white
                              : const Color(0xFF0F172A),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: Text(
                'Fermer',
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF94A3B8),
                ),
              ),
            ),
            FilledButton.icon(
              onPressed: () => _synchroniserStatut(ctx),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFFF751F),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: const Icon(Icons.sync_rounded, size: 18),
              label: Text(
                'J’ai validé le code PIN',
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _afficherSuccesModal() {
    final modeSombre = Theme.of(context).brightness == Brightness.dark;

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: modeSombre ? const Color(0xFF1E293B) : Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 10),
              Container(
                width: 64,
                height: 64,
                decoration: const BoxDecoration(
                  color: Color(0xFFDCFCE7),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_circle_rounded,
                  color: Color(0xFF16A34A),
                  size: 38,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Paiement confirmé !',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 19,
                  fontWeight: FontWeight.w900,
                  color: modeSombre ? Colors.white : const Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Votre réservation est désormais confirmée. Votre dossier a été transmis pour placement universitaire.',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w500,
                  color: modeSombre
                      ? const Color(0xFF94A3B8)
                      : const Color(0xFF64748B),
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: FilledButton(
                  onPressed: () {
                    Navigator.of(ctx).pop();
                    Navigator.of(
                      context,
                    ).pop(true); // Retourne succès à la page précédente
                  },
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF16A34A),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: Text(
                    'Continuer',
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
    final texteCouleur = modeSombre ? Colors.white : const Color(0xFF0F172A);
    final texteSecondaire = modeSombre
        ? const Color(0xFF94A3B8)
        : const Color(0xFF64748B);

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
          'Paiement',
          style: GoogleFonts.inter(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: texteCouleur,
          ),
        ),
        centerTitle: false,
      ),
      body: ContenuAdaptatif(
        largeurMaximale: 580,
        enfant: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Aperçu de l'opérateur actuellement sélectionné avec son logo au-dessus
                      _buildEnTeteOperateur(modeSombre),

                      const SizedBox(height: 20),

                      // Montant à débiter
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 18,
                          vertical: 16,
                        ),
                        decoration: BoxDecoration(
                          color: modeSombre
                              ? const Color(0xFF1E293B)
                              : Colors.white,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                            color: modeSombre
                                ? const Color(0xFF334155)
                                : const Color(0xFFE2E8F0),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Montant net à débiter',
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: texteSecondaire,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${widget.montant} ${widget.devise}',
                                  style: GoogleFonts.inter(
                                    fontSize: 24,
                                    fontWeight: FontWeight.w900,
                                    color: modeSombre
                                        ? Colors.white
                                        : const Color(0xFF0F172A),
                                    letterSpacing: -0.5,
                                  ),
                                ),
                              ],
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: modeSombre
                                    ? const Color(0xFF334155)
                                    : const Color(0xFFF1F5F9),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.lock_outline_rounded,
                                    color: modeSombre
                                        ? const Color(0xFFCBD5E1)
                                        : const Color(0xFF475569),
                                    size: 15,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Sécurisé',
                                    style: GoogleFonts.inter(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: modeSombre
                                          ? const Color(0xFFCBD5E1)
                                          : const Color(0xFF475569),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Sélection de l'opérateur Mobile Money
                      Text(
                        'Choisissez votre opérateur',
                        style: GoogleFonts.inter(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: texteCouleur,
                        ),
                      ),
                      const SizedBox(height: 12),

                      Row(
                        children: _operateurs.map((op) {
                          final selectionne =
                              op.cle == _operateurSelectionne.cle;
                          return Expanded(
                            child: GestureDetector(
                              onTap: () {
                                setState(() {
                                  _operateurSelectionne = op;
                                  if (!_phoneController.text.startsWith(
                                    op.prefixeIndicatif,
                                  )) {
                                    _phoneController.text = op.prefixeIndicatif;
                                    _phoneController
                                        .selection = TextSelection.fromPosition(
                                      TextPosition(
                                        offset: _phoneController.text.length,
                                      ),
                                    );
                                  }
                                });
                              },
                              child: Container(
                                margin: const EdgeInsets.symmetric(
                                  horizontal: 4,
                                ),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 12,
                                  horizontal: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: selectionne
                                      ? (modeSombre
                                            ? const Color(0xFF1E293B)
                                            : Colors.white)
                                      : (modeSombre
                                            ? const Color(
                                                0xFF1E293B,
                                              ).withValues(alpha: 0.5)
                                            : const Color(0xFFF1F5F9)),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: selectionne
                                        ? const Color(0xFFFF751F)
                                        : (modeSombre
                                              ? const Color(0xFF334155)
                                              : Colors.transparent),
                                    width: selectionne ? 2 : 1,
                                  ),
                                  boxShadow: selectionne
                                      ? [
                                          BoxShadow(
                                            color: const Color(
                                              0xFFFF751F,
                                            ).withValues(alpha: 0.18),
                                            blurRadius: 10,
                                            offset: const Offset(0, 4),
                                          ),
                                        ]
                                      : null,
                                ),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: Image.asset(
                                        op.logoAsset,
                                        width: 40,
                                        height: 40,
                                        fit: BoxFit.contain,
                                        errorBuilder:
                                            (context, error, stackTrace) =>
                                                Container(
                                                  width: 40,
                                                  height: 40,
                                                  color: op.couleurAccent
                                                      .withValues(alpha: 0.2),
                                                  child: Icon(
                                                    Icons.phone_android,
                                                    color: op.couleurAccent,
                                                    size: 20,
                                                  ),
                                                ),
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      op.cle.replaceAll('_', ' '),
                                      textAlign: TextAlign.center,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: GoogleFonts.inter(
                                        fontSize: 10.5,
                                        fontWeight: selectionne
                                            ? FontWeight.w800
                                            : FontWeight.w600,
                                        color: selectionne
                                            ? const Color(0xFFFF751F)
                                            : texteSecondaire,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),

                      const SizedBox(height: 24),

                      // Champ de saisie du numéro de téléphone
                      Text(
                        'Numéro Mobile Money du compte',
                        style: GoogleFonts.inter(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: texteCouleur,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Le montant de ${widget.montant} ${widget.devise} sera débité de ce numéro.',
                        style: GoogleFonts.inter(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w500,
                          color: texteSecondaire,
                        ),
                      ),
                      const SizedBox(height: 12),

                      Container(
                        decoration: BoxDecoration(
                          color: modeSombre
                              ? const Color(0xFF1E293B)
                              : Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: _focusNodePhone.hasFocus
                                ? const Color(0xFFFF751F)
                                : (modeSombre
                                      ? const Color(0xFF334155)
                                      : const Color(0xFFCBD5E1)),
                            width: 1.5,
                          ),
                        ),
                        child: TextField(
                          controller: _phoneController,
                          focusNode: _focusNodePhone,
                          keyboardType: TextInputType.phone,
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(RegExp(r'[\d+]')),
                          ],
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: texteCouleur,
                            letterSpacing: 0.5,
                          ),
                          decoration: InputDecoration(
                            prefixIcon: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(6),
                                    child: Image.asset(
                                      _operateurSelectionne.logoAsset,
                                      width: 24,
                                      height: 24,
                                      fit: BoxFit.contain,
                                      errorBuilder:
                                          (context, error, stackTrace) =>
                                              const Icon(
                                                Icons.phone_android,
                                                size: 20,
                                                color: Color(0xFFFF751F),
                                              ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    width: 1,
                                    height: 22,
                                    color: modeSombre
                                        ? const Color(0xFF334155)
                                        : const Color(0xFFE2E8F0),
                                  ),
                                ],
                              ),
                            ),
                            hintText: '+243...',
                            hintStyle: GoogleFonts.inter(
                              color: const Color(0xFF94A3B8),
                              fontWeight: FontWeight.w500,
                            ),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 16,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),

              // Barre d'action inférieure (évite tout overflow au clavier)
              Container(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                decoration: BoxDecoration(
                  color: modeSombre ? const Color(0xFF1E293B) : Colors.white,
                  border: Border(
                    top: BorderSide(
                      color: modeSombre
                          ? const Color(0xFF334155)
                          : const Color(0xFFF1F5F9),
                    ),
                  ),
                ),
                child: SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: FilledButton(
                    onPressed: _enCoursTraitement ? null : _procederPaiement,
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFFFF751F),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      elevation: 0,
                    ),
                    child: _enCoursTraitement
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: Colors.white,
                            ),
                          )
                        : Text(
                            'Payer ${widget.montant} ${widget.devise}',
                            style: GoogleFonts.inter(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEnTeteOperateur(bool modeSombre) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: modeSombre ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(20),
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
      child: Column(
        children: [
          // Logo de l'opérateur sélectionné apparaissant au-dessus
          Container(
            width: 86,
            height: 86,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: modeSombre
                  ? const Color(0xFF0F172A)
                  : const Color(0xFFF8FAFC),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: modeSombre
                      ? Colors.black.withValues(alpha: 0.3)
                      : Colors.black.withValues(alpha: 0.06),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(40),
              child: Image.asset(
                _operateurSelectionne.logoAsset,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) => const Icon(
                  Icons.phone_android,
                  size: 38,
                  color: Color(0xFFFF751F),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            _operateurSelectionne.nom,
            style: GoogleFonts.inter(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              color: modeSombre ? Colors.white : const Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            widget.titreCampagne ?? widget.reference,
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: modeSombre
                  ? const Color(0xFF94A3B8)
                  : const Color(0xFF64748B),
            ),
          ),
        ],
      ),
    );
  }
}
