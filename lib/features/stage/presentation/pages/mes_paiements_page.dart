import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/network/client_api_http.dart';
import '../../../../core/network/source_etudiant_distante.dart';
import '../../../../core/widgets/contenu_adaptatif.dart';
import '../../../../core/widgets/erreur_chargement_api.dart';
import 'apercu_facture_page.dart';

class MesPaiementsPage extends StatefulWidget {
  const MesPaiementsPage({super.key});

  @override
  State<MesPaiementsPage> createState() => _MesPaiementsPageState();
}

class _MesPaiementsPageState extends State<MesPaiementsPage> {
  final _source = SourceEtudiantDistante(ClientApiHttp());
  late Future<Map<String, dynamic>> _chargement;
  String _filtreActuel = 'Tous'; // 'Tous', 'À payer', 'Payés'

  @override
  void initState() {
    super.initState();
    _chargement = _source.paiements();
  }

  Future<void> _actualiser() async {
    final futur = _source.paiements();
    setState(() => _chargement = futur);
    await futur;
  }

  @override
  Widget build(BuildContext context) {
    final modeSombre = Theme.of(context).brightness == Brightness.dark;
    final fondPage = modeSombre
        ? const Color(0xFF0F172A)
        : const Color(0xFFF8FAFC);
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
          'Mes paiements',
          style: GoogleFonts.inter(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: texteCouleur,
          ),
        ),
        centerTitle: false,
      ),
      body: ContenuAdaptatif(
        largeurMaximale: 680,
        enfant: FutureBuilder<Map<String, dynamic>>(
          future: _chargement,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(color: Color(0xFFFF751F)),
              );
            }
            if (snapshot.hasError) {
              return ErreurChargementApi(
                erreur: snapshot.error,
                onReessayer: _actualiser,
              );
            }

            final data = snapshot.data ?? {};
            final obligationsRaw = (data['obligations'] as List? ?? [])
                .whereType<Map>()
                .map(Map<String, dynamic>.from)
                .toList();

            final stats = data['obligation_stats'] is Map
                ? Map<String, dynamic>.from(data['obligation_stats'] as Map)
                : (data['stats'] is Map
                      ? Map<String, dynamic>.from(data['stats'] as Map)
                      : null);

            final totalAPayer =
                stats?['payable'] ??
                obligationsRaw.where((o) => o['payable'] == true).length;
            final totalPayes =
                stats?['paid'] ??
                obligationsRaw.where((o) => o['status'] == 'PAID').length;

            final obligationsFiltrees = obligationsRaw.where((obl) {
              final status = (obl['status'] ?? '').toString().toUpperCase();
              final payable = obl['payable'] == true;
              if (_filtreActuel == 'À payer') {
                return payable || status == 'PENDING';
              }
              if (_filtreActuel == 'Payés') {
                return status == 'PAID';
              }
              return true;
            }).toList();

            return RefreshIndicator(
              color: const Color(0xFFFF751F),
              onRefresh: _actualiser,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(
                  parent: BouncingScrollPhysics(),
                ),
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
                children: [
                  if (obligationsRaw.isNotEmpty) ...[
                    // Carte de synthèse financière
                    _buildCarteSynthese(
                      modeSombre: modeSombre,
                      totalAPayer: totalAPayer,
                      totalPayes: totalPayes,
                      obligations: obligationsRaw,
                    ),
                    const SizedBox(height: 18),
                    // Sélecteur de filtres
                    Row(
                      children: [
                        _buildChipFiltre('Tous', modeSombre),
                        const SizedBox(width: 8),
                        _buildChipFiltre('À payer', modeSombre),
                        const SizedBox(width: 8),
                        _buildChipFiltre('Payés', modeSombre),
                      ],
                    ),
                    const SizedBox(height: 18),
                  ],
                  if (obligationsRaw.isEmpty)
                    _buildEtatVide(modeSombre)
                  else if (obligationsFiltrees.isEmpty)
                    _buildEtatFiltreVide(modeSombre)
                  else ...[
                    // Liste des obligations financières
                    ...obligationsFiltrees.map((obl) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _CarteObligationItem(
                          obligation: obl,
                          modeSombre: modeSombre,
                          onTap: () async {
                            final uuid = obl['uuid'].toString();
                            await Navigator.of(context).push(
                              MaterialPageRoute<void>(
                                builder: (_) =>
                                    ApercuFacturePage(obligationUuid: uuid),
                              ),
                            );
                            if (mounted) {
                              _actualiser();
                            }
                          },
                        ),
                      );
                    }),
                  ],
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildChipFiltre(String titre, bool modeSombre) {
    final actif = _filtreActuel == titre;
    final fondActif = const Color(0xFFFF751F);
    final fondInactif = modeSombre ? const Color(0xFF1E293B) : Colors.white;
    final texteInactif = modeSombre
        ? const Color(0xFF94A3B8)
        : const Color(0xFF64748B);

    return InkWell(
      onTap: () => setState(() => _filtreActuel = titre),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: actif ? fondActif : fondInactif,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: actif
                ? Colors.transparent
                : (modeSombre
                      ? const Color(0xFF334155)
                      : const Color(0xFFE2E8F0)),
          ),
        ),
        child: Text(
          titre,
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: actif ? FontWeight.w700 : FontWeight.w600,
            color: actif ? Colors.white : texteInactif,
          ),
        ),
      ),
    );
  }

  Widget _buildCarteSynthese({
    required bool modeSombre,
    required dynamic totalAPayer,
    required dynamic totalPayes,
    required List<Map<String, dynamic>> obligations,
  }) {
    final montantsParDevise = <String, num>{};
    for (final o in obligations) {
      if (o['payable'] == true || o['status'] == 'PENDING') {
        final montant = o['amount_remaining'] as num? ?? o['amount'] as num?;
        final devise = o['currency']?.toString().trim();
        if (montant != null && devise != null && devise.isNotEmpty) {
          montantsParDevise.update(
            devise,
            (total) => total + montant,
            ifAbsent: () => montant,
          );
        }
      }
    }
    final solde = montantsParDevise.isEmpty
        ? '—'
        : montantsParDevise.entries
              .map((entree) => '${entree.value} ${entree.key}')
              .join(' · ');

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFFF751F), Color(0xFFFF5500)],
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFF751F).withValues(alpha: 0.3),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Solde à régler',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.white.withValues(alpha: 0.88),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '$totalAPayer facture(s) en attente',
                  style: GoogleFonts.inter(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            solde,
            style: GoogleFonts.inter(
              fontSize: 28,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.verified_rounded,
                  color: Colors.white,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    totalPayes > 0
                        ? '$totalPayes paiement(s) déjà validé(s)'
                        : 'Aucun paiement validé pour l’instant',
                    style: GoogleFonts.inter(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEtatVide(bool modeSombre) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 20),
        child: Column(
          children: [
            Container(
              width: 68,
              height: 68,
              decoration: BoxDecoration(
                color: modeSombre
                    ? const Color(0xFF1E293B)
                    : const Color(0xFFF1F5F9),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.payments_outlined,
                size: 32,
                color: modeSombre
                    ? const Color(0xFF64748B)
                    : const Color(0xFF94A3B8),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Aucune obligation de paiement',
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: modeSombre ? Colors.white : const Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Vos factures et obligations financières de stage s’afficheront ici.',
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
      ),
    );
  }

  Widget _buildEtatFiltreVide(bool modeSombre) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 36),
      child: Text(
        'Aucune obligation ne correspond à ce filtre.',
        textAlign: TextAlign.center,
        style: GoogleFonts.inter(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: modeSombre ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
        ),
      ),
    );
  }
}

class _CarteObligationItem extends StatelessWidget {
  const _CarteObligationItem({
    required this.obligation,
    required this.modeSombre,
    required this.onTap,
  });

  final Map<String, dynamic> obligation;
  final bool modeSombre;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final status = (obligation['status'] ?? '').toString().toUpperCase();
    final payable = obligation['payable'] == true;
    final montant = obligation['amount'];
    final montantRestant = obligation['amount_remaining'] ?? montant;
    final devise = obligation['currency']?.toString() ?? '';
    final reference = obligation['reference']?.toString() ?? '—';
    final label = obligation['label']?.toString() ?? 'Obligation financière';

    final contextData = obligation['context'] is Map
        ? obligation['context'] as Map
        : null;
    final hospital = contextData?['hospital'] is Map
        ? contextData!['hospital'] as Map
        : null;
    final nomHopital = hospital?['name']?.toString();

    final estPaye = status == 'PAID';
    final estEnAttente = payable || status == 'PENDING';
    final estErreur = const {'FAILED', 'CANCELLED', 'EXPIRED'}.contains(status);

    final couleurBadge = estPaye
        ? (modeSombre ? const Color(0xFF4ADE80) : const Color(0xFF16A34A))
        : estErreur
        ? (modeSombre ? const Color(0xFFFCA5A5) : const Color(0xFFDC2626))
        : (modeSombre ? const Color(0xFFFDBA74) : const Color(0xFFEA580C));

    final fondBadge = estPaye
        ? (modeSombre
              ? const Color(0xFF064E3B).withValues(alpha: 0.35)
              : const Color(0xFFDCFCE7))
        : estErreur
        ? (modeSombre
              ? const Color(0xFF7F1D1D).withValues(alpha: 0.35)
              : const Color(0xFFFEE2E2))
        : (modeSombre
              ? const Color(0xFF7C2D12).withValues(alpha: 0.35)
              : const Color(0xFFFFEDD5));

    final libelleBadge = estPaye
        ? 'Réglé'
        : switch (status) {
            'FAILED' => 'Échec',
            'CANCELLED' => 'Annulé',
            'EXPIRED' => 'Expiré',
            'PARTIALLY_PAID' => 'Partiel',
            _ => obligation['payment_pending'] == true ? 'En cours' : 'À payer',
          };

    return Container(
      decoration: BoxDecoration(
        color: modeSombre ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(18),
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
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(18),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 9,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: modeSombre
                            ? const Color(0xFF334155)
                            : const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        reference.toString(),
                        style: GoogleFonts.inter(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                          color: modeSombre
                              ? const Color(0xFFCBD5E1)
                              : const Color(0xFF475569),
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: fondBadge,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        libelleBadge,
                        style: GoogleFonts.inter(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                          color: couleurBadge,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  label.toString(),
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: modeSombre ? Colors.white : const Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 3),
                if (nomHopital != null && nomHopital.isNotEmpty)
                  Text(
                    nomHopital,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: modeSombre
                          ? const Color(0xFF94A3B8)
                          : const Color(0xFF64748B),
                    ),
                  ),
                const SizedBox(height: 12),
                Divider(
                  height: 1,
                  color: modeSombre
                      ? const Color(0xFF334155)
                      : const Color(0xFFF1F5F9),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          estPaye ? 'Montant réglé' : 'Reste à payer',
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: const Color(0xFF94A3B8),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${estPaye ? montant ?? '—' : montantRestant ?? '—'}${devise.isEmpty ? '' : ' $devise'}',
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                            color: estPaye
                                ? (modeSombre
                                      ? const Color(0xFF4ADE80)
                                      : const Color(0xFF16A34A))
                                : const Color(0xFFFF751F),
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        Text(
                          estEnAttente ? 'Payer maintenant' : 'Voir la facture',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF2563EB),
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Icon(
                          Icons.arrow_forward_ios_rounded,
                          size: 14,
                          color: Color(0xFF2563EB),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
