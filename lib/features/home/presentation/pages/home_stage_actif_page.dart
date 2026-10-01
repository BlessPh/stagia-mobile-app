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
    final totalRotations = stage['total_rotations'] is int
        ? stage['total_rotations'] as int
        : 0;
    final journauxValides = stage['journaux_valides'] is int
        ? stage['journaux_valides'] as int
        : 0;

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
        if (stage.isNotEmpty)
          SectionStageEnCoursAccueil(
            titreCampagne: stage['campaign_title']?.toString() ?? '',
            nomEtablissement: stage['hospital_name']?.toString() ?? '',
            serviceActuel: stage['unit_name']?.toString() ?? '',
            servicesEffectues: journauxValides,
            totalServices: totalRotations,
            joursRestantsService: _joursRestants(stage['date_fin']) ?? 0,
            nomEncadreur: stage['supervisor_name']?.toString() ?? '',
          ),
      ],
    );
  }
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
