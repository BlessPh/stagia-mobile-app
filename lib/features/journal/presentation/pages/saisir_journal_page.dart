import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class SaisirJournalPage extends StatefulWidget {
  const SaisirJournalPage({this.dateInitiale = '16 Janvier 2026', super.key});

  final String dateInitiale;

  @override
  State<SaisirJournalPage> createState() => _SaisirJournalPageState();
}

class _SaisirJournalPageState extends State<SaisirJournalPage> {
  late final TextEditingController _dateController;
  final TextEditingController _apprentissageController = TextEditingController(
    text:
        'Suture et gestion de l\'asepsie stricte en milieu de garde surchargé. Amélioration de la technique de nœud.',
  );
  final TextEditingController _difficultesController = TextEditingController(
    text:
        'Gestion du stress lors du rush des urgences de midi. Manque de fil de suture 4-0 au box de traumatologie.',
  );

  final List<Map<String, String>> _activitesCliniques = [
    {
      'type': 'RÉALISATION',
      'titre': 'Suture plaie palmaire — 4 points Nylon...',
    },
    {
      'type': 'OBSERVATION',
      'titre': 'Observation pose voie veineuse centra...',
    },
  ];

  @override
  void initState() {
    super.initState();
    _dateController = TextEditingController(text: widget.dateInitiale);
  }

  @override
  void dispose() {
    _dateController.dispose();
    _apprentissageController.dispose();
    _difficultesController.dispose();
    super.dispose();
  }

  void _ajouterActiviteDialog() {
    final typeCtrl = TextEditingController(text: 'RÉALISATION');
    final titreCtrl = TextEditingController();

    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          'Ajouter une activité',
          style: GoogleFonts.inter(fontWeight: FontWeight.w800, fontSize: 17),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<String>(
              initialValue: typeCtrl.text,
              items: ['RÉALISATION', 'OBSERVATION', 'ASSISTANCE']
                  .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                  .toList(),
              onChanged: (v) {
                if (v != null) typeCtrl.text = v;
              },
              decoration: const InputDecoration(labelText: 'Type'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: titreCtrl,
              decoration: const InputDecoration(labelText: 'Intitulé de l\'activité'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () {
              if (titreCtrl.text.trim().isNotEmpty) {
                setState(() {
                  _activitesCliniques.add({
                    'type': typeCtrl.text,
                    'titre': titreCtrl.text.trim(),
                  });
                });
              }
              Navigator.pop(ctx);
            },
            child: const Text('Ajouter'),
          ),
        ],
      ),
    );
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
          icon: const Icon(CupertinoIcons.chevron_left, color: Color(0xFF0F172A), size: 24),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Saisir un journal',
          style: GoogleFonts.inter(
            fontSize: 18.5,
            fontWeight: FontWeight.w800,
            color: const Color(0xFF0F172A),
          ),
        ),
      ),
      body: SafeArea(
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
          children: [
            // Date du journal
            Text(
              'Date du journal',
              style: GoogleFonts.inter(
                fontSize: 13.5,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _dateController.text,
                    style: GoogleFonts.inter(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF0F172A),
                    ),
                  ),
                  const Icon(CupertinoIcons.calendar, size: 20, color: Color(0xFF64748B)),
                ],
              ),
            ),

            const SizedBox(height: 18),

            // Principaux apprentissages
            Text(
              'Principaux apprentissages',
              style: GoogleFonts.inter(
                fontSize: 13.5,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              padding: const EdgeInsets.all(14),
              child: TextField(
                controller: _apprentissageController,
                maxLines: 3,
                style: GoogleFonts.inter(fontSize: 13.5, color: const Color(0xFF0F172A)),
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ),

            const SizedBox(height: 18),

            // Difficultés rencontrées
            Text(
              'Difficultés rencontrées',
              style: GoogleFonts.inter(
                fontSize: 13.5,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              padding: const EdgeInsets.all(14),
              child: TextField(
                controller: _difficultesController,
                maxLines: 3,
                style: GoogleFonts.inter(fontSize: 13.5, color: const Color(0xFF0F172A)),
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ),

            const SizedBox(height: 20),

            // En-tête Activités cliniques (2) + Ajouter
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Activités cliniques (${_activitesCliniques.length})',
                  style: GoogleFonts.inter(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF0F172A),
                  ),
                ),
                GestureDetector(
                  onTap: _ajouterActiviteDialog,
                  child: Text(
                    '+ Ajouter',
                    style: GoogleFonts.inter(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF1D61F2),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Liste des pilules d'activités
            for (final act in _activitesCliniques)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE0F2FE),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          act['type']!,
                          style: GoogleFonts.inter(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF0284C7),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          act['titre']!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF0F172A),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            const SizedBox(height: 24),

            // Bouton Soumettre à l'encadreur (Bleu)
            SizedBox(
              width: double.infinity,
              height: 48,
              child: FilledButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Journal soumis à l’encadreur.')),
                  );
                  Navigator.of(context).pop();
                },
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF1D61F2),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  elevation: 0,
                ),
                child: Text(
                  'Soumettre à l\'encadreur',
                  style: GoogleFonts.inter(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 10),

            // Bouton Enregistrer en Brouillon (Blanc bordé)
            SizedBox(
              width: double.infinity,
              height: 48,
              child: OutlinedButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Journal enregistré en brouillon.')),
                  );
                  Navigator.of(context).pop();
                },
                style: OutlinedButton.styleFrom(
                  backgroundColor: Colors.white,
                  side: const BorderSide(color: Color(0xFFE2E8F0)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: Text(
                  'Enregistrer en Brouillon',
                  style: GoogleFonts.inter(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF475569),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
