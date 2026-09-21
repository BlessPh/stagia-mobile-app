import 'package:flutter/material.dart';
import '../widgets/carousel_accueil.dart';
import '../widgets/section_stage_disponible_accueil.dart';
import '../widgets/section_taches_jour_accueil.dart';
import '../widgets/section_stage_en_cours_accueil.dart';
import 'home_shared_widgets.dart';

class HomeStageActifPage extends StatelessWidget {
  const HomeStageActifPage({required this.donnees, super.key});

  final Map<String, dynamic> donnees;

  @override
  Widget build(BuildContext context) {
    final marge = MediaQuery.sizeOf(context).width < 360 ? 14.0 : 18.0;
    final stage = mapApi(donnees['current_stage']);
    final stats = mapApi(donnees['stats']);

    final totalRotations = stage['total_rotations'] is int ? stage['total_rotations'] as int : 6;
    final journauxValides = stage['journaux_valides'] is int ? stage['journaux_valides'] as int : 3;

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: EdgeInsets.fromLTRB(marge, 12, marge, 28),
      children: [
        const CarouselAccueil(),
        const SizedBox(height: 20),
        const SectionTachesJourAccueil(),
        const SizedBox(height: 20),
        const SectionStageDisponibleAccueil(),
        const SizedBox(height: 20),
        SectionStageEnCoursAccueil(
          titreCampagne: stage['campaign_title']?.toString() ?? 'Campagne de Stage Clinique 2026',
          nomEtablissement: stage['hospital_name']?.toString() ?? 'Hôpital Général de Kinshasa',
          serviceActuel: stage['unit_name']?.toString() ?? 'Chirurgie Générale',
          servicesEffectues: journauxValides,
          totalServices: totalRotations,
          joursRestantsService: _joursRestants(stage['date_fin']) ?? 12,
        ),
        const SizedBox(height: 18),
        Row(
          children: [
            Expanded(
              child: _Indicateur(
                'assets/icons/candidature.png',
                '${stats['applications'] ?? 0}',
                'Candidatures',
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _Indicateur(
                'assets/icons/stage_en_cours.png',
                '${stats['active_reservations'] ?? 0}',
                'Réservations',
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _Indicateur(
                'assets/icons/documents.png',
                '${stats['documents'] ?? 0}',
                'Documents',
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        _Statut(
          'Présence quotidienne',
          '${stage['taux_presence'] ?? 0}%',
          'assets/icons/presence.png',
        ),
        const SizedBox(height: 12),
        _Statut(
          'Note',
          stage['note_finale'] == null
              ? 'Pas disponible'
              : '${stage['note_finale']}',
          'assets/icons/note.png',
        ),
        const SizedBox(height: 12),
        _Statut(
          'Documents envoyés',
          '${stats['documents'] ?? 0}',
          'assets/icons/documents.png',
        ),
      ],
    );
  }
}


class _Indicateur extends StatelessWidget {
  const _Indicateur(this.cheminIcone, this.valeur, this.libelle);

  final String cheminIcone;
  final String valeur;
  final String libelle;

  @override
  Widget build(BuildContext context) => Container(
    constraints: const BoxConstraints(minHeight: 134),
    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 14),
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.surface,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: const Color(0xFFFF7417)),
    ),
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Image.asset(
          cheminIcone,
          width: 34,
          height: 34,
          fit: BoxFit.contain,
          errorBuilder: (_, _, _) => const SizedBox(
            width: 34,
            height: 34,
            child: Icon(Icons.image_not_supported_outlined),
          ),
        ),
        const SizedBox(height: 7),
        Text(
          valeur,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: valeur.length > 4 ? 15 : 20,
            fontWeight: FontWeight.w900,
          ),
        ),
        Text(
          libelle,
          maxLines: 2,
          textAlign: TextAlign.center,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(color: Color(0xFF718096), fontSize: 11),
        ),
      ],
    ),
  );
}

class _Statut extends StatelessWidget {
  const _Statut(this.titre, this.valeur, this.cheminIcone);

  final String titre;
  final String valeur;
  final String cheminIcone;

  @override
  Widget build(BuildContext context) => Container(
    constraints: const BoxConstraints(minHeight: 92),
    padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 18),
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.surface,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: const Color(0xFFFF7417)),
    ),
    child: Row(
      children: [
        Image.asset(
          cheminIcone,
          width: 36,
          height: 36,
          fit: BoxFit.contain,
          errorBuilder: (_, _, _) => const SizedBox(
            width: 36,
            height: 36,
            child: Icon(Icons.image_not_supported_outlined),
          ),
        ),
        const SizedBox(width: 20),
        Expanded(
          child: Text.rich(
            TextSpan(
              children: [
                TextSpan(text: '$titre : '),
                TextSpan(
                  text: valeur,
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
              ],
            ),
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          ),
        ),
      ],
    ),
  );
}



int? _joursRestants(Object? valeur) {
  final fin = DateTime.tryParse(valeur?.toString() ?? '');
  if (fin == null) return null;
  final aujourdHui = DateTime.now();
  final debutJour = DateTime(aujourdHui.year, aujourdHui.month, aujourdHui.day);
  final finJour = DateTime(fin.year, fin.month, fin.day);
  final jours = finJour.difference(debutJour).inDays;
  return jours < 0 ? 0 : jours;
}


