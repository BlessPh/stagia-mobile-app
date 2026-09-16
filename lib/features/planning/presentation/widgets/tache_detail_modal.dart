import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../domain/entities/tache_planning.dart';

class TacheDetailModal extends StatelessWidget {
  const TacheDetailModal({
    required this.tache,
    this.onSupprimer,
    super.key,
  });

  final TachePlanning tache;
  final VoidCallback? onSupprimer;

  static void afficher(
    BuildContext context,
    TachePlanning tache, {
    VoidCallback? onSupprimer,
  }) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => TacheDetailModal(tache: tache, onSupprimer: onSupprimer),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.fromLTRB(
        24,
        16,
        24,
        MediaQuery.paddingOf(context).bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Poignée centrale
          Center(
            child: Container(
              width: 44,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFE2E8F0),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // En-tête : Badge type et Horaires
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: tache.couleur.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  tache.type,
                  style: GoogleFonts.inter(
                    color: tache.couleur,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.schedule_rounded,
                      size: 15,
                      color: Color(0xFF475569),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      '${tache.heureDebut} - ${tache.heureFin}',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF334155),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Titre principal
          Text(
            tache.titre,
            style: GoogleFonts.inter(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF0F172A),
              height: 1.25,
            ),
          ),
          const SizedBox(height: 20),

          // Informations détaillées du stage
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Column(
              children: [
                _LigneDetail(
                  icone: Icons.local_hospital_outlined,
                  libelle: 'Service',
                  valeur: tache.service,
                ),
                const Divider(height: 18, color: Color(0xFFE2E8F0)),
                _LigneDetail(
                  icone: Icons.domain_rounded,
                  libelle: 'Département',
                  valeur: tache.departement,
                ),
                const Divider(height: 18, color: Color(0xFFE2E8F0)),
                _LigneDetail(
                  icone: Icons.badge_outlined,
                  libelle: 'Superviseur',
                  valeur: tache.superviseur,
                ),
                if (tache.lieu != null && tache.lieu!.isNotEmpty) ...[
                  const Divider(height: 18, color: Color(0xFFE2E8F0)),
                  _LigneDetail(
                    icone: Icons.location_on_outlined,
                    libelle: 'Lieu / Salle',
                    valeur: tache.lieu!,
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 18),

          // Description / Consignes
          Text(
            'Consignes et description',
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            tache.description,
            style: GoogleFonts.inter(
              fontSize: 13.5,
              color: const Color(0xFF475569),
              height: 1.45,
            ),
          ),
          const SizedBox(height: 24),

          // Boutons d'actions
          Row(
            children: [
              if (onSupprimer != null)
                IconButton.filledTonal(
                  onPressed: () {
                    Navigator.pop(context);
                    onSupprimer!();
                  },
                  icon: const Icon(
                    Icons.delete_outline_rounded,
                    color: Color(0xFFEF4444),
                  ),
                  style: IconButton.styleFrom(
                    backgroundColor: const Color(0xFFFEE2E2),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              if (onSupprimer != null) const SizedBox(width: 12),
              Expanded(
                child: FilledButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Présence confirmée pour cette tâche.'),
                      ),
                    );
                  },
                  icon: const Icon(Icons.check_circle_outline_rounded, size: 18),
                  label: const Text('Confirmer ma présence'),
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF2563EB),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
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

class _LigneDetail extends StatelessWidget {
  const _LigneDetail({
    required this.icone,
    required this.libelle,
    required this.valeur,
  });

  final IconData icone;
  final String libelle;
  final String valeur;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icone, size: 18, color: const Color(0xFF64748B)),
        const SizedBox(width: 10),
        Text(
          libelle,
          style: GoogleFonts.inter(
            fontSize: 13,
            color: const Color(0xFF64748B),
            fontWeight: FontWeight.w500,
          ),
        ),
        const Spacer(),
        Text(
          valeur,
          style: GoogleFonts.inter(
            fontSize: 13.5,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF0F172A),
          ),
        ),
      ],
    );
  }
}
