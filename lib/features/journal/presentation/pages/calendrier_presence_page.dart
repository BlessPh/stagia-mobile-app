import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../notifications/presentation/pages/notifications_page.dart';
import '../widgets/calendrier_mois_entier.dart';
import '../widgets/modal_signaler_absence.dart';

class CalendrierPresencePage extends StatefulWidget {
  const CalendrierPresencePage({super.key});

  @override
  State<CalendrierPresencePage> createState() => _CalendrierPresencePageState();
}

class _CalendrierPresencePageState extends State<CalendrierPresencePage> {
  DateTime _dateSelectionnee = DateTime(2026, 1, 15);
  DateTime _moisAffiche = DateTime(2026, 1);

  final Map<int, Color> _statutsPointageParJour = {
    5: const Color(0xFF16A34A),
    6: const Color(0xFF16A34A),
    7: const Color(0xFF16A34A),
    8: const Color(0xFF16A34A),
    9: const Color(0xFF16A34A),
    11: const Color(0xFF16A34A), // Vert Présent
    12: const Color(0xFF16A34A),
    13: const Color(0xFFF97316), // Orange Retard
    14: const Color(0xFF16A34A),
    15: const Color(0xFFF97316),
    16: const Color(0xFF16A34A),
    17: const Color(0xFF16A34A),
    19: const Color(0xFF16A34A),
    20: const Color(0xFF16A34A),
    21: const Color(0xFF16A34A),
    22: const Color(0xFF16A34A),
    23: const Color(0xFF16A34A),
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF8FAFC),
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(CupertinoIcons.chevron_left, color: Color(0xFF0F172A), size: 24),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Calendrier de présence',
          style: GoogleFonts.inter(
            fontSize: 19,
            fontWeight: FontWeight.w800,
            color: const Color(0xFF0F172A),
          ),
        ),
        actions: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              IconButton(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(builder: (_) => const NotificationsPage()),
                ),
                icon: const Icon(CupertinoIcons.bell, color: Color(0xFF0F172A), size: 25),
              ),
              Positioned(
                top: 8,
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
                    style: TextStyle(color: Colors.white, fontSize: 9.5, fontWeight: FontWeight.w800, height: 1),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
          children: [
            // Sélecteur de calendrier mois entier
            CalendrierMoisEntier(
              dateSelectionnee: _dateSelectionnee,
              moisAffiche: _moisAffiche,
              pointsCouleursParDate: _statutsPointageParJour,
              onDateSelectionnee: (date) {
                setState(() => _dateSelectionnee = date);
              },
              onMoisPrecedent: () {
                setState(() {
                  _moisAffiche = DateTime(_moisAffiche.year, _moisAffiche.month - 1);
                });
              },
              onMoisSuivant: () {
                setState(() {
                  _moisAffiche = DateTime(_moisAffiche.year, _moisAffiche.month + 1);
                });
              },
            ),

            const SizedBox(height: 12),

            // Légende des couleurs : Présent, Retard, Absent
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildLegendeElement('Présent', const Color(0xFF16A34A)),
                const SizedBox(width: 16),
                _buildLegendeElement('Retard', const Color(0xFFF97316)),
                const SizedBox(width: 16),
                _buildLegendeElement('Absent', const Color(0xFFDC2626)),
              ],
            ),

            const SizedBox(height: 24),

            // Titre Derniers pointages
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Derniers pointages',
                  style: GoogleFonts.inter(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF0F172A),
                  ),
                ),
                GestureDetector(
                  onTap: () async {
                    final messager = ScaffoldMessenger.of(context);
                    final res = await ModalSignalerAbsence.afficher(context);
                    if (res == true && mounted) {
                      messager.showSnackBar(
                        const SnackBar(content: Text('Notification d’absence transmise.')),
                      );
                    }
                  },
                  child: Text(
                    'Signaler absence',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFFF97316),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 14),

            // Cartes de pointages
            _buildCartePointage(
              dateJour: '14 Jan',
              jourSemaine: 'Mercredi',
              horaires: '07:54 - 16:30',
              sourceTexte: 'Source : GPS Hôpital',
              statutTexte: 'Présent',
              statutCouleur: const Color(0xFF16A34A),
            ),
            const SizedBox(height: 12),
            _buildCartePointage(
              dateJour: '13 Jan',
              jourSemaine: 'Mardi',
              horaires: '08:14 - 16:05',
              sourceTexte: 'Validé par superviseur',
              statutTexte: 'Retard 14 min',
              statutCouleur: const Color(0xFFF97316),
            ),
            const SizedBox(height: 12),
            _buildCartePointage(
              dateJour: '12 Jan',
              jourSemaine: 'Lundi',
              horaires: '07:50 - 16:30',
              sourceTexte: 'Source : QR Code Borne',
              statutTexte: 'Présent',
              statutCouleur: const Color(0xFF16A34A),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLegendeElement(String titre, Color couleur) {
    return Row(
      children: [
        Container(
          width: 7,
          height: 7,
          decoration: BoxDecoration(color: couleur, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          titre,
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: const Color(0xFF64748B),
          ),
        ),
      ],
    );
  }

  Widget _buildCartePointage({
    required String dateJour,
    required String jourSemaine,
    required String horaires,
    required String sourceTexte,
    required String statutTexte,
    required Color statutCouleur,
  }) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x05000000),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Date & Jour
          SizedBox(
            width: 68,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  dateJour,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  jourSemaine,
                  style: GoogleFonts.inter(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF94A3B8),
                  ),
                ),
              ],
            ),
          ),

          // Séparateur vertical
          Container(
            width: 1,
            height: 38,
            color: const Color(0xFFF1F5F9),
            margin: const EdgeInsets.symmetric(horizontal: 12),
          ),

          // Horaires et Source/Statut (protégé contre tout overflow)
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  horaires,
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 3),
                Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: '$sourceTexte • ',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFF64748B),
                        ),
                      ),
                      TextSpan(
                        text: statutTexte,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: statutCouleur,
                        ),
                      ),
                    ],
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
