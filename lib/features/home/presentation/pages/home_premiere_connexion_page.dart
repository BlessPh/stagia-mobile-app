import 'package:flutter/material.dart';
import '../../../../core/network/configuration_api.dart';
import '../../../stage/data/mappers/mappeur_campagne_stage_api.dart';
import '../widgets/carousel_accueil.dart';
import '../widgets/section_stage_disponible_accueil.dart';
import '../widgets/section_stage_en_cours_accueil.dart';
import '../widgets/section_taches_jour_accueil.dart';

class HomePremiereConnexionPage extends StatelessWidget {
  const HomePremiereConnexionPage({
    required this.campagnes,
    required this.candidatures,
    required this.onVoirCampagnes,
    this.stats = const {},
    super.key,
  });

  final List<Map<String, dynamic>> campagnes;
  final List<Map<String, dynamic>> candidatures;
  final VoidCallback? onVoirCampagnes;
  final Map<String, dynamic> stats;

  @override
  Widget build(BuildContext context) {
    final marge = MediaQuery.sizeOf(context).width < 360 ? 14.0 : 18.0;
    final premiereCampagneJson = campagnes.isNotEmpty ? campagnes.first : null;
    final premiereCampagneObj = premiereCampagneJson != null
        ? MappeurCampagneStageApi.depuisJson(premiereCampagneJson)
        : null;

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: EdgeInsets.fromLTRB(marge, 12, marge, 28),
      children: [
        const CarouselAccueil(),
        const SizedBox(height: 20),
        const SectionTachesJourAccueil(),
        const SizedBox(height: 20),
        SectionStageDisponibleAccueil(
          campagne: premiereCampagneObj,
          onVoirDetails: onVoirCampagnes,
        ),
        if (ConfigurationApi.utiliserDonneesMockees) ...[
          const SizedBox(height: 20),
          SectionStageEnCoursAccueil(onTap: onVoirCampagnes),
        ],
      ],
    );
  }
}
