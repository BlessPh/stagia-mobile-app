import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../domain/entities/discussion.dart';
import 'avatar_discussion.dart';
import 'badge_message.dart';
import 'statut_lecture_icone.dart';

class ElementDiscussion extends StatelessWidget {
  const ElementDiscussion({
    required this.discussion,
    required this.onTap,
    super.key,
  });

  final Discussion discussion;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final modeSombre = Theme.of(context).brightness == Brightness.dark;
    final aDesNonLus = discussion.nbNonLus > 0;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
          child: Row(
            children: [
              // Avatar
              AvatarDiscussion(
                nom: discussion.nom,
                estEnLigne: discussion.estEnLigne,
                estGroupe: discussion.estGroupe,
                estDiffusion: discussion.estDiffusion,
                rayon: 26,
              ),
              const SizedBox(width: 14),

              // Contenu central
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Titre + Épinglé + Heure
                    Row(
                      children: [
                        if (discussion.estEpingle) ...[
                          const Icon(
                            Icons.push_pin_rounded,
                            size: 14,
                            color: Color(0xFFFF7417),
                          ),
                          const SizedBox(width: 4),
                        ],
                        Expanded(
                          child: Text(
                            discussion.nom,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.inter(
                              fontSize: 15,
                              fontWeight: aDesNonLus
                                  ? FontWeight.w800
                                  : FontWeight.w700,
                              color: modeSombre
                                  ? Colors.white
                                  : const Color(0xFF0F172A),
                              letterSpacing: -0.2,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          discussion.tempsAffiche,
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: aDesNonLus
                                ? FontWeight.w700
                                : FontWeight.w500,
                            color: aDesNonLus
                                ? const Color(0xFFFF7417)
                                : const Color(0xFF94A3B8),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 3),

                    // Service / Rôle tag
                    Text(
                      discussion.roleOuService,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: const Color(0xFF64748B),
                        fontWeight: FontWeight.w500,
                      ),
                    ),

                    const SizedBox(height: 4),

                    // Dernier message + Statut ou Badge
                    Row(
                      children: [
                        if (discussion.dernierMessageEstMien) ...[
                          StatutLectureIcone(
                            statut: discussion.statutMessage,
                            taille: 14,
                          ),
                          const SizedBox(width: 5),
                        ],
                        Expanded(
                          child: Text(
                            discussion.dernierMessage,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.inter(
                              fontSize: 13.5,
                              fontWeight: aDesNonLus
                                  ? FontWeight.w600
                                  : FontWeight.w400,
                              color: aDesNonLus
                                  ? (modeSombre
                                      ? Colors.white
                                      : const Color(0xFF1E293B))
                                  : const Color(0xFF64748B),
                            ),
                          ),
                        ),
                        if (aDesNonLus) ...[
                          const SizedBox(width: 8),
                          BadgeMessageCompteur(compte: discussion.nbNonLus),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
