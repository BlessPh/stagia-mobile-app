import 'package:flutter/material.dart';
import '../pages/candidatures_stage_page.dart';
import '../pages/detail_campagne_page.dart';
import '../pages/hopitaux_disponibles_page.dart';
import '../pages/mes_stages_page.dart';
import '../pages/mon_stage_page.dart';
import '../pages/parcours_candidature_page.dart';
import '../pages/reservation_page.dart';

abstract final class RoutesStage {
  static const accueil = '/';
  static const postuler = '/postuler';
  static const candidatures = '/candidatures';
  static const monStage = '/mon-stage';
  static const parcoursCandidature = '/parcours-candidature';
  static const detailCampagne = '/detail-campagne';
  static const hopitauxDisponibles = '/hopitaux-disponibles';
  static const reservation = '/reservation';

  static Route<dynamic> generer(RouteSettings parametres) {
    final Widget page = switch (parametres.name) {
      postuler => const MesStagesPage(),
      candidatures => const CandidaturesStagePage(),
      monStage => const MonStagePage(),
      detailCampagne => const DetailCampagnePage(),
      hopitauxDisponibles => const HopitauxDisponiblesPage(),
      reservation => const ReservationPage(),
      parcoursCandidature => ParcoursCandidaturePage(
          option: Map<String, dynamic>.from(parametres.arguments! as Map),
        ),
      _ => const MesStagesPage(),
    };

    return MaterialPageRoute<dynamic>(builder: (_) => page);
  }
}
