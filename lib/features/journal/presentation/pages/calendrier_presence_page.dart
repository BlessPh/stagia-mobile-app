import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/network/client_api_http.dart';
import '../../../../core/network/source_etudiant_distante.dart';
import '../../../notifications/presentation/pages/notifications_page.dart';
import '../widgets/calendrier_mois_entier.dart';
import '../widgets/modal_signaler_absence.dart';

class CalendrierPresencePage extends StatefulWidget {
  const CalendrierPresencePage({super.key});

  @override
  State<CalendrierPresencePage> createState() => _CalendrierPresencePageState();
}

class _CalendrierPresencePageState extends State<CalendrierPresencePage> {
  final _source = SourceEtudiantDistante(ClientApiHttp());
  DateTime _dateSelectionnee = DateTime.now();
  DateTime _moisAffiche = DateTime(DateTime.now().year, DateTime.now().month);

  bool _chargement = true;
  List<Map<String, dynamic>> _pointages = [];
  Map<int, Color> _statutsPointageParJour = {};
  int _unreadNotifications = 0;

  @override
  void initState() {
    super.initState();
    _dateSelectionnee = DateTime.now();
    _moisAffiche = DateTime(_dateSelectionnee.year, _dateSelectionnee.month);
    _chargerPresences();
  }

  Future<void> _chargerPresences() async {
    try {
      final futurPresences = _source.presences();
      final futurCounts = _source.notificationCounts();
      final results = await Future.wait([futurPresences, futurCounts]);

      final presencesData = results[0];
      final countsData = results[1];

      final items = (presencesData['items'] as List? ?? [])
          .whereType<Map>()
          .map(Map<String, dynamic>.from)
          .toList();

      final unread =
          int.tryParse(countsData['notifications']?.toString() ?? '0') ?? 0;

      // Construire les pastilles pour le mois affiché
      final pastilles = _extrairePastillesParJour(items, _moisAffiche);

      if (mounted) {
        setState(() {
          _pointages = items;
          _statutsPointageParJour = pastilles;
          _unreadNotifications = unread;
          _chargement = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _chargement = false);
      }
    }
  }

  Map<int, Color> _extrairePastillesParJour(
    List<Map<String, dynamic>> items,
    DateTime mois,
  ) {
    final map = <int, Color>{};
    for (final item in items) {
      final dateStr = item['date']?.toString();
      if (dateStr == null) continue;
      final dt = DateTime.tryParse(dateStr);
      if (dt != null && dt.year == mois.year && dt.month == mois.month) {
        final statut = (item['status'] ?? item['statut'] ?? '')
            .toString()
            .toUpperCase();
        if (statut.contains('PRESENT') || statut == 'VALIDE') {
          map[dt.day] = const Color(0xFF16A34A); // Vert
        } else if (statut.contains('RETARD')) {
          map[dt.day] = const Color(0xFFF97316); // Orange
        } else if (statut.contains('ABSENT')) {
          map[dt.day] = const Color(0xFFDC2626); // Rouge
        }
      }
    }
    return map;
  }

  void _onChangementMois(DateTime nouveauMois) {
    setState(() {
      _moisAffiche = nouveauMois;
      _statutsPointageParJour = _extrairePastillesParJour(
        _pointages,
        nouveauMois,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF8FAFC),
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(
            CupertinoIcons.chevron_left,
            color: Color(0xFF0F172A),
            size: 24,
          ),
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
                  MaterialPageRoute<void>(
                    builder: (_) => const NotificationsPage(),
                  ),
                ),
                icon: const Icon(
                  CupertinoIcons.bell,
                  color: Color(0xFF0F172A),
                  size: 25,
                ),
              ),
              if (_unreadNotifications > 0)
                Positioned(
                  top: 8,
                  right: 6,
                  child: Container(
                    padding: const EdgeInsets.all(3),
                    decoration: const BoxDecoration(
                      color: Color(0xFFEF4444),
                      shape: BoxShape.circle,
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 16,
                      minHeight: 16,
                    ),
                    child: Text(
                      '$_unreadNotifications',
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
      ),
      body: SafeArea(
        child: _chargement
            ? const Center(
                child: CircularProgressIndicator(color: Color(0xFFFF7417)),
              )
            : RefreshIndicator(
                color: const Color(0xFFFF7417),
                onRefresh: _chargerPresences,
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
                        _onChangementMois(
                          DateTime(_moisAffiche.year, _moisAffiche.month - 1),
                        );
                      },
                      onMoisSuivant: () {
                        _onChangementMois(
                          DateTime(_moisAffiche.year, _moisAffiche.month + 1),
                        );
                      },
                    ),

                    const SizedBox(height: 12),

                    // Légende des couleurs : Présent, Retard, Absent
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildLegendeElement(
                          'Présent',
                          const Color(0xFF16A34A),
                        ),
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
                            final res = await ModalSignalerAbsence.afficher(
                              context,
                            );
                            if (res == true && mounted) {
                              messager.showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Notification d’absence transmise.',
                                  ),
                                ),
                              );
                              _chargerPresences();
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

                    // Cartes de pointages dynamiques depuis l'API
                    if (_pointages.isEmpty)
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 24),
                          child: Text(
                            'Aucun pointage enregistré pour le moment.',
                            style: GoogleFonts.inter(
                              color: const Color(0xFF94A3B8),
                              fontSize: 14,
                            ),
                          ),
                        ),
                      )
                    else
                      ..._pointages.take(5).map((p) {
                        final dateStr = p['date']?.toString() ?? '';
                        final dt = DateTime.tryParse(dateStr);
                        final dateJour = dt != null
                            ? '${dt.day} ${_nomMoisCourt(dt.month)}'
                            : dateStr;
                        final jourSemaine = dt != null
                            ? _nomJourSemaine(dt.weekday)
                            : '';
                        final arrivee =
                            (p['arrival_time'] ?? p['time_in'] ?? '--:--')
                                .toString()
                                .split(':')
                                .take(2)
                                .join(':');
                        final depart =
                            (p['departure_time'] ?? p['time_out'] ?? '--:--')
                                .toString()
                                .split(':')
                                .take(2)
                                .join(':');
                        final horaires = '$arrivee - $depart';
                        final source =
                            p['hospital_name']?.toString() ??
                            p['observation']?.toString() ??
                            'Pointage clinique';
                        final statutBrut =
                            (p['status'] ?? p['statut'] ?? 'PRESENT')
                                .toString()
                                .toUpperCase();

                        Color couleurStatut = const Color(0xFF16A34A);
                        String statutTexte = 'Présent';
                        if (statutBrut.contains('RETARD')) {
                          couleurStatut = const Color(0xFFF97316);
                          statutTexte = 'Retard';
                        } else if (statutBrut.contains('ABSENT')) {
                          couleurStatut = const Color(0xFFDC2626);
                          statutTexte = 'Absent';
                        }

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _buildCartePointage(
                            dateJour: dateJour,
                            jourSemaine: jourSemaine,
                            horaires: horaires,
                            sourceTexte: 'Source : $source',
                            statutTexte: statutTexte,
                            statutCouleur: couleurStatut,
                          ),
                        );
                      }),
                  ],
                ),
              ),
      ),
    );
  }

  String _nomMoisCourt(int mois) {
    const moisList = [
      'Jan',
      'Fév',
      'Mar',
      'Avr',
      'Mai',
      'Juin',
      'Juil',
      'Août',
      'Sep',
      'Oct',
      'Nov',
      'Déc',
    ];
    if (mois >= 1 && mois <= 12) return moisList[mois - 1];
    return '';
  }

  String _nomJourSemaine(int weekday) {
    const jours = [
      'Lundi',
      'Mardi',
      'Mercredi',
      'Jeudi',
      'Vendredi',
      'Samedi',
      'Dimanche',
    ];
    if (weekday >= 1 && weekday <= 7) return jours[weekday - 1];
    return '';
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
              children: [
                Text(
                  dateJour,
                  style: GoogleFonts.inter(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  jourSemaine,
                  style: GoogleFonts.inter(
                    fontSize: 11,
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
            margin: const EdgeInsets.symmetric(horizontal: 10),
            color: const Color(0xFFF1F5F9),
          ),

          // Horaires et Source
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  horaires,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  sourceTexte,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),

          // Badge Statut
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4.5),
            decoration: BoxDecoration(
              color: statutCouleur.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              statutTexte,
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: statutCouleur,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
