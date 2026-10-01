import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/network/client_api_http.dart';
import '../../../../core/network/source_etudiant_distante.dart';
import '../../../../core/widgets/contenu_adaptatif.dart';
import '../../../../core/widgets/erreur_chargement_api.dart';

class NotesAcademiquesPage extends StatefulWidget {
  const NotesAcademiquesPage({this.academicEnrollmentId, super.key});

  final int? academicEnrollmentId;

  @override
  State<NotesAcademiquesPage> createState() => _NotesAcademiquesPageState();
}

class _NotesAcademiquesPageState extends State<NotesAcademiquesPage> {
  final _source = SourceEtudiantDistante(ClientApiHttp());
  late Future<Map<String, dynamic>> _chargement;

  @override
  void initState() {
    super.initState();
    _chargement = _charger();
  }

  Future<Map<String, dynamic>> _charger() => _source.notes(widget.academicEnrollmentId);

  Future<void> _actualiser() async {
    final futur = _charger();
    setState(() => _chargement = futur);
    await futur;
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xFFF8FAFC),
    appBar: AppBar(
      backgroundColor: const Color(0xFFF8FAFC),
      elevation: 0,
      surfaceTintColor: Colors.transparent,
      title: Text(
        'Notes académiques',
        style: GoogleFonts.inter(
          fontSize: 20,
          fontWeight: FontWeight.w800,
          color: const Color(0xFF0F172A),
        ),
      ),
    ),
    body: ContenuAdaptatif(
      largeurMaximale: 680,
      enfant: FutureBuilder<Map<String, dynamic>>(
        future: _chargement,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFF1D61F2)),
            );
          }
          if (snapshot.hasError) {
            return ErreurChargementApi(
              erreur: snapshot.error,
              onReessayer: _actualiser,
            );
          }

          final data = snapshot.data ?? {};
          final notesListe = (data['notes'] as List? ?? data['items'] as List? ?? [])
              .whereType<Map>()
              .map(Map<String, dynamic>.from)
              .toList();

          final stats = data['stats'] is Map ? Map<String, dynamic>.from(data['stats'] as Map) : null;
          final moyenne = stats?['average'] ?? stats?['moyenne'];

          if (notesListe.isEmpty) {
            return Center(
              child: Container(
                margin: const EdgeInsets.all(20),
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.assignment_outlined, size: 48, color: Color(0xFF94A3B8)),
                    const SizedBox(height: 12),
                    Text(
                      'Aucune note académique publiée.',
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF0F172A),
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Vos résultats d\'évaluations apparaîtront ici dès leur validation universitaire.',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: const Color(0xFF64748B),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            );
          }

          return RefreshIndicator(
            color: const Color(0xFF1D61F2),
            onRefresh: _actualiser,
            child: ListView(
              padding: const EdgeInsets.all(18),
              children: [
                if (moyenne != null) ...[
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1D61F2),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x1A1D61F2),
                          blurRadius: 12,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Moyenne Générale',
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: Colors.white70,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${notesListe.length} matières évaluées',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                color: Colors.white.withValues(alpha: 0.85),
                              ),
                            ),
                          ],
                        ),
                        Text(
                          '$moyenne / 20',
                          style: GoogleFonts.inter(
                            fontSize: 24,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                for (final note in notesListe) ...[
                  _CarteNote(note),
                  const SizedBox(height: 12),
                ],
              ],
            ),
          );
        },
      ),
    ),
  );
}

class _CarteNote extends StatelessWidget {
  const _CarteNote(this.note);
  final Map<String, dynamic> note;

  @override
  Widget build(BuildContext context) {
    final noteSur20 = note['note_sur_20'] ?? note['note'] ?? '-';
    final result = note['result']?.toString() ?? note['resultat']?.toString() ?? 'VALIDE';
    final estValide = result.toUpperCase() == 'VALIDE' || result.toUpperCase() == 'VALIDÉ';

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x05000000),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  note['subject_name']?.toString() ?? note['matiere']?.toString() ?? 'Matière',
                  style: GoogleFonts.inter(
                    fontSize: 16.5,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF0F172A),
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4.5),
                decoration: BoxDecoration(
                  color: estValide ? const Color(0xFFDCFCE7) : const Color(0xFFFEE2E2),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  result,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: estValide ? const Color(0xFF16A34A) : const Color(0xFFDC2626),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Text(
                'Note : ',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFF64748B),
                ),
              ),
              Text(
                '$noteSur20 / 20',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: estValide ? const Color(0xFF16A34A) : const Color(0xFFDC2626),
                ),
              ),
              if (note['credits'] != null) ...[
                const Spacer(),
                Text(
                  '${note['credits']} crédits',
                  style: GoogleFonts.inter(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF94A3B8),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
