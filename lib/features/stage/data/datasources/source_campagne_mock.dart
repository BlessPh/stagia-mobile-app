import '../../domain/entities/campagne_stage.dart';

abstract final class SourceCampagneMock {
  static const campagnePrincipale = CampagneStage(
    id: 'CAM-STG-2026-001',
    titre: 'Campagne de Stage Clinique 2026',
    sousTitre: 'Faculté de Médecine • Universités partenaires de Kinshasa',
    dateDebut: '01 Oct 2026',
    dateFin: '31 Jan 2027',
    periodeTexte: '01 Oct 2026 - 31 Jan 2027',
    indemnite: '150 000 FC',
    modalite: 'En 2 tranches',
    statut: 'Inscriptions ouvertes',
    nombreHopitaux: 12,
    estEligible: true,
    messageEligibilite: 'Vous êtes éligible pour cette campagne',
    consignes: [
      'Présentation obligatoire en tenue médicale réglementaire (blouse blanche propre).',
      'Dossier physique complet à déposer au secrétariat académique dans les 5 jours de la réservation.',
      'Respect scrupuleux du planning hebdomadaire de 36 heures réparties selon le service affecté.',
    ],
    criteresEligibilite: [
      "Niveau d'études L3 validé ou supérieur",
      'Frais académiques entièrement payés',
      "Dossier médical d'aptitude complet",
    ],
    hopitaux: [
      HopitalCampagne(
        id: 'HOSP-001',
        nom: 'Clinique Ngaliema',
        distanceKm: 2.3,
        placesDisponibles: 5,
        placesRestantes: 5,
        commune: 'Gombe',
        ville: 'Kinshasa',
        adresse: 'Avenue des Cliniques, Gombe, Kinshasa',
        telephone: '+243 81 234 56 78',
        description: 'Hôpital Clinique de référence provinciale',
        services: [
          'Pédiatrie',
          'Gynécologie-Obstétrique',
          'Médecine Interne',
          'Chirurgie',
        ],
        latitude: -4.3060,
        longitude: 15.2866,
      ),
      HopitalCampagne(
        id: 'HOSP-002',
        nom: 'Hôpital Général de Kinshasa',
        distanceKm: 4.1,
        placesDisponibles: 12,
        placesRestantes: 12,
        commune: 'Kinshasa',
        ville: 'Kinshasa',
        adresse: 'Avenue Wangata, Kinshasa',
        telephone: '+243 81 987 65 43',
        description: 'Hôpital général de référence et d’enseignement',
        services: [
          'Médecine Interne',
          'Chirurgie',
          'Pédiatrie',
          'Urgences',
        ],
        latitude: -4.3168,
        longitude: 15.3082,
      ),
      HopitalCampagne(
        id: 'HOSP-003',
        nom: 'Centre Hospitalier Monkole',
        distanceKm: 6.5,
        placesDisponibles: 5,
        placesRestantes: 5,
        commune: 'Mont-Ngafula',
        ville: 'Kinshasa',
        adresse: 'Avenue Monkole, Mont-Ngafula',
        telephone: '+243 89 555 44 33',
        description: 'Centre médico-chirurgical universitaire',
        services: [
          'Pédiatrie',
          'Gynécologie-Obstétrique',
          'Chirurgie',
        ],
        latitude: -4.4137,
        longitude: 15.2652,
      ),
      HopitalCampagne(
        id: 'HOSP-004',
        nom: 'Cliniques Universitaires de Kinshasa',
        distanceKm: 8.2,
        placesDisponibles: 8,
        placesRestantes: 8,
        commune: 'Lemba',
        ville: 'Kinshasa',
        adresse: 'Campus UNIKIN, Lemba',
        telephone: '+243 82 111 22 33',
        description: 'Hôpital universitaire de référence tertiaire',
        services: [
          'Chirurgie',
          'Médecine Interne',
          'Pédiatrie',
          'Cardiologie',
        ],
        latitude: -4.4172,
        longitude: 15.3090,
      ),
    ],
  );

  static CampagneStage obtenirCampagneOuverte() => campagnePrincipale;

  static CampagneStage depuisJson(Map<String, dynamic> json) {
    final hospitalsList = (json['hospitals'] as List?)
            ?.whereType<Map>()
            .map((h) {
              final hMap = Map<String, dynamic>.from(h);
              final hospitalInfo = hMap['hospital'] is Map
                  ? Map<String, dynamic>.from(hMap['hospital'] as Map)
                  : <String, dynamic>{};
              final partId = hMap['participation_id'] is int
                  ? hMap['participation_id'] as int
                  : int.tryParse(hMap['participation_id']?.toString() ?? '');
              final placesDispo = hMap['available_places'] is int
                  ? hMap['available_places'] as int
                  : (int.tryParse(hMap['available_places']?.toString() ?? '') ?? 10);
              final nom = hospitalInfo['name']?.toString() ??
                  hMap['nom']?.toString() ??
                  'Hôpital partenaire';
              final ville = hospitalInfo['city']?.toString() ?? 'Kinshasa';
              final commune = hospitalInfo['province']?.toString() ?? 'Kinshasa';

              return HopitalCampagne(
                id: partId != null ? 'PART-$partId' : 'HOSP-${nom.hashCode.abs()}',
                participationId: partId,
                nom: nom,
                distanceKm: 3.5,
                placesDisponibles: placesDispo,
                placesRestantes: placesDispo,
                fraisRequis: hMap['fees_required'] == true,
                montantFrais: (hMap['amount'] is num ? (hMap['amount'] as num).toInt() : 0),
                devise: hMap['currency']?.toString() ?? 'CDF',
                ville: ville,
                commune: commune,
                adresse: '$commune, $ville',
              );
            })
            .toList() ??
        campagnePrincipale.hopitaux;

    final campaignId = json['campaign_id']?.toString() ??
        json['id']?.toString() ??
        'CAM-STG-2026-001';
    final enrollmentId = json['academic_enrollment_id'] is int
        ? json['academic_enrollment_id'] as int
        : int.tryParse(json['academic_enrollment_id']?.toString() ?? '');
    final titre = json['title']?.toString() ??
        json['titre']?.toString() ??
        'Stage médical D4 2026';
    final dateDebut = json['start_date']?.toString() ?? '2026-11-10';
    final dateFin = json['end_date']?.toString() ?? '2027-01-14';
    final mode = json['mode'] is Map ? json['mode'] as Map : null;
    final isD4 = mode?['is_d4'] == true || (json['stage_type'] is Map && json['stage_type']['code'] == 'MEDICAL_D4');

    return CampagneStage(
      id: campaignId,
      academicEnrollmentId: enrollmentId,
      isD4: isD4,
      titre: titre,
      sousTitre: json['program']?.toString() ?? 'Médecine générale • Universités partenaires',
      dateDebut: dateDebut,
      dateFin: dateFin,
      periodeTexte: '$dateDebut - $dateFin',
      indemnite: 'Selon conditions hospitalières',
      modalite: 'Temps plein',
      statut: 'Inscriptions ouvertes',
      nombreHopitaux: hospitalsList.length,
      estEligible: true,
      consignes: campagnePrincipale.consignes,
      criteresEligibilite: campagnePrincipale.criteresEligibilite,
      hopitaux: hospitalsList,
    );
  }
}
