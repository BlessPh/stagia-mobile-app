import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../domain/entities/notification_item.dart';
import 'badge_notification.dart';
import 'icone_notification.dart';

class CarteNotification extends StatelessWidget {
  const CarteNotification({
    required this.notification,
    required this.onAction,
    this.onMarquerLue,
    super.key,
  });

  final NotificationItem notification;
  final VoidCallback onAction;
  final VoidCallback? onMarquerLue;

  @override
  Widget build(BuildContext context) {
    final modeSombre = Theme.of(context).brightness == Brightness.dark;
    final nonLue = !notification.lue;

    final fondCarte = nonLue
        ? (modeSombre ? const Color(0xFF231C18) : const Color(0xFFFFFBF8))
        : (modeSombre ? const Color(0xFF1E1E1E) : Colors.white);

    final bordureCarte = nonLue
        ? const Color(0xFFFF7417).withValues(alpha: 0.3)
        : (modeSombre ? const Color(0xFF2E2E2E) : const Color(0xFFEDF2F7));

    return Container(
      decoration: BoxDecoration(
        color: fondCarte,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: bordureCarte, width: nonLue ? 1.2 : 1),
        boxShadow: [
          BoxShadow(
            color: nonLue
                ? const Color(0xFFFF7417).withValues(alpha: 0.05)
                : Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: () {
            if (nonLue && onMarquerLue != null) {
              onMarquerLue!();
            }
            onAction();
          },
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Icône du sujet
                    IconeNotification(
                      icone: notification.icone,
                      couleur: notification.couleur,
                    ),
                    const SizedBox(width: 12),

                    // Sujet & Temps
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  notification.sujet,
                                  style: GoogleFonts.inter(
                                    fontSize: 14.5,
                                    fontWeight: nonLue
                                        ? FontWeight.w800
                                        : FontWeight.w700,
                                    color: modeSombre
                                        ? Colors.white
                                        : const Color(0xFF0F172A),
                                    letterSpacing: -0.2,
                                  ),
                                ),
                              ),
                              if (nonLue) ...[
                                const SizedBox(width: 8),
                                const PastilleNonLue(taille: 9),
                              ],
                            ],
                          ),
                          const SizedBox(height: 3),
                          Text(
                            notification.tempsRelatif,
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: const Color(0xFF64748B),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 10),

                // Description
                Padding(
                  padding: const EdgeInsets.only(left: 4),
                  child: Text(
                    notification.description,
                    style: GoogleFonts.inter(
                      fontSize: 13.5,
                      height: 1.45,
                      color: modeSombre
                          ? const Color(0xFFCBD5E1)
                          : const Color(0xFF334155),
                    ),
                  ),
                ),

                const SizedBox(height: 14),

                // Bouton d'action
                Align(
                  alignment: Alignment.centerRight,
                  child: OutlinedButton(
                    onPressed: onAction,
                    style: OutlinedButton.styleFrom(
                      backgroundColor: notification.couleur.withValues(alpha: 0.08),
                      foregroundColor: notification.couleur,
                      side: BorderSide(
                        color: notification.couleur.withValues(alpha: 0.35),
                        width: 1,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 9,
                      ),
                      visualDensity: VisualDensity.compact,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          notification.actionLabel,
                          style: GoogleFonts.inter(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.1,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Icon(
                          Icons.arrow_forward_rounded,
                          size: 14,
                          color: notification.couleur,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
