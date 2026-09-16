import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../data/datasources/source_planning_mock.dart';
import '../../domain/entities/tache_planning.dart';

class DetailTachePage extends StatefulWidget {
  const DetailTachePage({
    required this.tache,
    this.onTacheModifiee,
    super.key,
  });

  final TachePlanning tache;
  final ValueChanged<TachePlanning>? onTacheModifiee;

  @override
  State<DetailTachePage> createState() => _DetailTachePageState();
}

class _DetailTachePageState extends State<DetailTachePage> {
  late TachePlanning _tacheActuelle;

  @override
  void initState() {
    super.initState();
    _tacheActuelle = widget.tache;
  }

  String _formaterDate(DateTime date, String debut, String fin) {
    const jours = [
      'Lundi',
      'Mardi',
      'Mercredi',
      'Jeudi',
      'Vendredi',
      'Samedi',
      'Dimanche',
    ];
    const mois = [
      'Janvier',
      'Février',
      'Mars',
      'Avril',
      'Mai',
      'Juin',
      'Juillet',
      'Août',
      'Septembre',
      'Octobre',
      'Novembre',
      'Décembre',
    ];
    final nomJour = jours[date.weekday - 1];
    final nomMois = mois[date.month - 1];
    final hDebut = debut.replaceAll(':', 'h');
    final hFin = fin.replaceAll(':', 'h');
    return '$nomJour ${date.day} $nomMois, $hDebut - $hFin';
  }

  void _marquerCommeTermine() {
    final nouvelleTache = _tacheActuelle.copyWith(statut: 'Terminé');
    setState(() {
      _tacheActuelle = nouvelleTache;
    });
    SourcePlanningMock.mettreAJourTache(nouvelleTache);
    widget.onTacheModifiee?.call(nouvelleTache);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Tâche marquée comme terminée avec succès !'),
        backgroundColor: Color(0xFF10B981),
      ),
    );
  }

  void _ouvrirDialogueModification() {
    final titreController = TextEditingController(text: _tacheActuelle.titre);
    final descController = TextEditingController(text: _tacheActuelle.description);
    final lieuController = TextEditingController(text: _tacheActuelle.lieu ?? '');
    final rappelController = TextEditingController(text: _tacheActuelle.noteRappel ?? '');

    showDialog<void>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Modifier la tâche',
          style: GoogleFonts.inter(fontWeight: FontWeight.w800, fontSize: 18),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titreController,
                decoration: InputDecoration(
                  labelText: 'Titre',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: lieuController,
                decoration: InputDecoration(
                  labelText: 'Localisation / Lieu',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: descController,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: 'Description',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: rappelController,
                maxLines: 2,
                decoration: InputDecoration(
                  labelText: 'Note / Rappel',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () {
              final modifiee = _tacheActuelle.copyWith(
                titre: titreController.text.trim(),
                lieu: lieuController.text.trim(),
                description: descController.text.trim(),
                noteRappel: rappelController.text.trim().isEmpty ? null : rappelController.text.trim(),
              );
              setState(() {
                _tacheActuelle = modifiee;
              });
              SourcePlanningMock.mettreAJourTache(modifiee);
              widget.onTacheModifiee?.call(modifiee);
              Navigator.pop(dialogCtx);

              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Tâche mise à jour avec succès.')),
              );
            },
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF2563EB),
            ),
            child: const Text('Enregistrer'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final estCours = _tacheActuelle.type == 'Cours';
    final libelleResponsable = estCours ? 'Enseignant' : 'Superviseur';
    final localisation = _tacheActuelle.lieu != null && _tacheActuelle.lieu!.isNotEmpty
        ? _tacheActuelle.lieu!
        : '${_tacheActuelle.service} • ${_tacheActuelle.departement}';

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFF2563EB),
        elevation: 0,
        scrolledUnderElevation: 0,
        leadingWidth: 64,
        leading: Padding(
          padding: const EdgeInsets.only(left: 16),
          child: Center(
            child: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.22),
                shape: BoxShape.circle,
              ),
              child: IconButton(
                onPressed: () => Navigator.maybePop(context),
                icon: const Icon(
                  Icons.chevron_left_rounded,
                  color: Colors.white,
                  size: 24,
                ),
                padding: EdgeInsets.zero,
                tooltip: 'Retour',
              ),
            ),
          ),
        ),
        title: Text(
          'Détail de la tâche',
          style: GoogleFonts.inter(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: Colors.white,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 1. Première carte : Aperçu, Badges & Métadonnées
            _buildPremiereCarte(
              localisation: localisation,
              libelleResponsable: libelleResponsable,
            ),

            const SizedBox(height: 16),

            // 2. Deuxième carte : Description
            _buildCarteDescription(),

            const SizedBox(height: 16),

            // 3. Troisième carte : Note / Rappel (fond pastel jaune/orange)
            _buildCarteRappel(),
          ],
        ),
      ),

      // Barre d'actions en bas (Modifier / Terminé)
      bottomNavigationBar: Container(
        padding: EdgeInsets.fromLTRB(
          16,
          12,
          16,
          MediaQuery.paddingOf(context).bottom + 12,
        ),
        decoration: const BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Color(0x0F000000),
              blurRadius: 16,
              offset: Offset(0, -4),
            ),
          ],
        ),
        child: Row(
          children: [
            // Bouton Modifier (contour bleu)
            Expanded(
              child: OutlinedButton(
                onPressed: _ouvrirDialogueModification,
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Color(0xFF2563EB), width: 2),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: Text(
                  'Modifier',
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF2563EB),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 14),

            // Bouton Terminé (plein bleu)
            Expanded(
              child: FilledButton(
                onPressed: _marquerCommeTermine,
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF2563EB),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: Text(
                  'Terminé',
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
      ),
    );
  }

  Widget _buildPremiereCarte({
    required String localisation,
    required String libelleResponsable,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(
            color: Color(0x08000000),
            blurRadius: 18,
            offset: Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Ligne supérieure : Badges type et statut
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _tacheActuelle.type,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF2563EB),
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: _tacheActuelle.statut == 'Terminé'
                      ? const Color(0xFFECFDF5)
                      : const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _tacheActuelle.statut,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: _tacheActuelle.statut == 'Terminé'
                        ? const Color(0xFF10B981)
                        : const Color(0xFF2563EB),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Titre principal
          Text(
            _tacheActuelle.titre,
            style: GoogleFonts.inter(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: const Color(0xFF0F172A),
              height: 1.25,
            ),
          ),
          const SizedBox(height: 6),

          // Ligne de séparation intérieure
          const Divider(height: 28, thickness: 1, color: Color(0xFFF1F5F9)),

          // 1. Date & Horaires
          _buildItemMetadonnee(
            icone: Icons.calendar_today_rounded,
            libelle: 'Date & Horaires',
            valeur: _formaterDate(
              _tacheActuelle.date,
              _tacheActuelle.heureDebut,
              _tacheActuelle.heureFin,
            ),
          ),
          const SizedBox(height: 18),

          // 2. Localisation
          _buildItemMetadonnee(
            icone: Icons.location_on_outlined,
            libelle: 'Localisation',
            valeur: localisation,
          ),
          const SizedBox(height: 18),

          // 3. Enseignant / Superviseur
          _buildItemMetadonnee(
            icone: Icons.person_outline_rounded,
            libelle: libelleResponsable,
            valeur: _tacheActuelle.superviseur,
          ),
        ],
      ),
    );
  }

  Widget _buildItemMetadonnee({
    required IconData icone,
    required String libelle,
    required String valeur,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: const BoxDecoration(
            color: Color(0xFFEFF6FF),
            shape: BoxShape.circle,
          ),
          child: Icon(
            icone,
            color: const Color(0xFF2563EB),
            size: 19,
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                libelle,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: const Color(0xFF94A3B8),
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                valeur,
                style: GoogleFonts.inter(
                  fontSize: 14.5,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF0F172A),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCarteDescription() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: Color(0x08000000),
            blurRadius: 16,
            offset: Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Description',
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            _tacheActuelle.description,
            style: GoogleFonts.inter(
              fontSize: 13.5,
              color: const Color(0xFF64748B),
              height: 1.55,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCarteRappel() {
    final rappel = _tacheActuelle.noteRappel ??
        'Consultez les consignes d\'usage auprès de votre superviseur de stage.';

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBF5),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFFFE8D1), width: 1.2),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.info_outline_rounded,
                color: Color(0xFFF97316),
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Note / Rappel',
                style: GoogleFonts.inter(
                  fontSize: 14.5,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFFF97316),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            rappel,
            style: GoogleFonts.inter(
              fontSize: 13.5,
              color: const Color(0xFF334155),
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
