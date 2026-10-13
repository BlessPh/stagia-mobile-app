class HopitalCampagne {
  const HopitalCampagne({
    required this.id,
    required this.nom,
    required this.distanceKm,
    required this.placesDisponibles,
    this.participationId,
    this.code = '',
    this.capacite = 0,
    this.placesUtilisees = 0,
    this.placesRestantes,
    this.disponible = true,
    this.fraisRequis = false,
    this.montantFrais = 0,
    this.devise = '',
    this.conditions,
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
  final String code;
  final String nom;
  final double distanceKm;
  final int capacite;
  final int placesUtilisees;
  final int placesDisponibles;
  final int? placesRestantes;
  final bool disponible;
  final bool fraisRequis;
  final double montantFrais;
  final String devise;
  final String? conditions;
  final String? adresse;
  final String commune;
  final String ville;
  final String description;
  final String telephone;
  final List<String> services;
  final double? latitude;
  final double? longitude;

  int get placesRestantesEffectives => placesRestantes ?? placesDisponibles;

  bool get peutReserver => disponible && placesRestantesEffectives > 0;

  String get localisationCourte {
    final valeurs = <String>[];
    for (final element in [ville, commune]) {
      final valeur = element.trim();
      if (valeur.isNotEmpty && !valeurs.contains(valeur)) valeurs.add(valeur);
    }
    return valeurs.join(', ');
  }

  String get distanceEtPlaces {
    final details = <String>[];
    if (distanceKm > 0) details.add('${distanceKm.toStringAsFixed(1)} km');
    details.add('$placesRestantesEffectives places disponibles');
    return details.join(' • ');
  }

  Map<String, dynamic> versMapOption({
    required String campagneId,
    required String campagneTitre,
  }) => {
    'campagne_id': campagneId,
    'option_id': id,
    'cle_option': '$campagneId::$id',
    'etablissement': nom,
    'campagne': campagneTitre,
    'localisation': adresse ?? localisationCourte,
  };
}

class CampagneStage {
  const CampagneStage({
    required this.id,
    this.code = '',
    this.academicEnrollmentId,
    this.isD4 = true,
    this.autoriseReservationAutonome = true,
    this.modeReservation = 'SELF_RESERVATION',
    this.typeStageCode = '',
    this.typeStageLibelle = '',
    this.promotionCode = '',
    this.promotionNom = '',
    this.niveau = '',
    required this.titre,
    required this.sousTitre,
    required this.dateDebut,
    required this.dateFin,
    required this.periodeTexte,
    required this.indemnite,
    required this.modalite,
    required this.statut,
    required this.nombreHopitaux,
    this.nombreHopitauxDisponibles,
    required this.estEligible,
    this.messageEligibilite = '',
    required this.consignes,
    required this.criteresEligibilite,
    required this.hopitaux,
  });

  final String id;
  final String code;
  final int? academicEnrollmentId;
  final bool isD4;
  final bool autoriseReservationAutonome;
  final String modeReservation;
  final String typeStageCode;
  final String typeStageLibelle;
  final String promotionCode;
  final String promotionNom;
  final String niveau;
  final String titre;
  final String sousTitre;
  final String dateDebut;
  final String dateFin;
  final String periodeTexte;
  final String indemnite;
  final String modalite;
  final String statut;
  final int nombreHopitaux;
  final int? nombreHopitauxDisponibles;
  final bool estEligible;
  final String messageEligibilite;
  final List<String> consignes;
  final List<String> criteresEligibilite;
  final List<HopitalCampagne> hopitaux;

  CampagneStage avecStatut(String nouveauStatut) => CampagneStage(
    id: id,
    code: code,
    academicEnrollmentId: academicEnrollmentId,
    isD4: isD4,
    autoriseReservationAutonome: autoriseReservationAutonome,
    modeReservation: modeReservation,
    typeStageCode: typeStageCode,
    typeStageLibelle: typeStageLibelle,
    promotionCode: promotionCode,
    promotionNom: promotionNom,
    niveau: niveau,
    titre: titre,
    sousTitre: sousTitre,
    dateDebut: dateDebut,
    dateFin: dateFin,
    periodeTexte: periodeTexte,
    indemnite: indemnite,
    modalite: modalite,
    statut: nouveauStatut,
    nombreHopitaux: nombreHopitaux,
    nombreHopitauxDisponibles: nombreHopitauxDisponibles,
    estEligible: estEligible,
    messageEligibilite: messageEligibilite,
    consignes: consignes,
    criteresEligibilite: criteresEligibilite,
    hopitaux: hopitaux,
  );
}
