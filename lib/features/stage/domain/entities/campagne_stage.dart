class HopitalCampagne {
  const HopitalCampagne({
    required this.id,
    required this.nom,
    required this.distanceKm,
    required this.placesDisponibles,
    this.participationId,
    this.placesRestantes,
    this.fraisRequis = false,
    this.montantFrais = 0,
    this.devise = '',
    this.adresse,
    this.commune = '',
    this.ville = '',
    this.description = '',
    this.telephone = '',
    this.services = const [],
    this.latitude,
    this.longitude,
  });

  final String id;
  final int? participationId;
  final String nom;
  final double distanceKm;
  final int placesDisponibles;
  final int? placesRestantes;
  final bool fraisRequis;
  final int montantFrais;
  final String devise;
  final String? adresse;
  final String commune;
  final String ville;
  final String description;
  final String telephone;
  final List<String> services;
  final double? latitude;
  final double? longitude;

  int get placesRestantesEffectives => placesRestantes ?? placesDisponibles;

  String get localisationCourte => '$commune, $ville';

  String get distanceEtPlaces =>
      '${distanceKm.toStringAsFixed(1)} km • $placesDisponibles places disponibles';

  Map<String, dynamic> versMapOption({
    required String campagneId,
    required String campagneTitre,
  }) => {
    'campagne_id': campagneId,
    'option_id': id,
    'cle_option': '$campagneId::$id',
    'etablissement': nom,
    'campagne': campagneTitre,
    'localisation': adresse ?? '$commune, $ville · RDC',
  };
}

class CampagneStage {
  const CampagneStage({
    required this.id,
    this.academicEnrollmentId,
    this.isD4 = true,
    this.autoriseReservationAutonome = true,
    this.modeReservation = 'SELF_RESERVATION',
    required this.titre,
    required this.sousTitre,
    required this.dateDebut,
    required this.dateFin,
    required this.periodeTexte,
    required this.indemnite,
    required this.modalite,
    required this.statut,
    required this.nombreHopitaux,
    required this.estEligible,
    this.messageEligibilite = '',
    required this.consignes,
    required this.criteresEligibilite,
    required this.hopitaux,
  });

  final String id;
  final int? academicEnrollmentId;
  final bool isD4;
  final bool autoriseReservationAutonome;
  final String modeReservation;
  final String titre;
  final String sousTitre;
  final String dateDebut;
  final String dateFin;
  final String periodeTexte;
  final String indemnite;
  final String modalite;
  final String statut;
  final int nombreHopitaux;
  final bool estEligible;
  final String messageEligibilite;
  final List<String> consignes;
  final List<String> criteresEligibilite;
  final List<HopitalCampagne> hopitaux;
}
