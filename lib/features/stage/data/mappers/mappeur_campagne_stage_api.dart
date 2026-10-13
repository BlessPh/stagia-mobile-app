import '../../domain/entities/campagne_stage.dart';

/// Convertit strictement une campagne renvoyée par l'API.
///
/// Aucune valeur métier mockée n'est injectée lorsqu'un champ est absent.
abstract final class MappeurCampagneStageApi {
  static CampagneStage depuisJson(Map<String, dynamic> json) {
    final hopitaux =
        (json['hospitals'] as List?)?.whereType<Map>().map((brut) {
          final participation = Map<String, dynamic>.from(brut);
          final hopital = participation['hospital'] is Map
              ? Map<String, dynamic>.from(participation['hospital'] as Map)
              : const <String, dynamic>{};
          final participationId = _entier(participation['participation_id']);
          final places = _entier(participation['available_places']) ?? 0;
          final nom = hopital['name']?.toString().trim() ?? '';
          final ville = hopital['city']?.toString().trim() ?? '';
          final commune = hopital['province']?.toString().trim() ?? '';

          return HopitalCampagne(
            id: participationId?.toString() ?? hopital['id']?.toString() ?? '',
            participationId: participationId,
            code: hopital['code']?.toString() ?? '',
            nom: nom,
            distanceKm: _decimal(participation['distance_km']) ?? 0,
            capacite: _entier(participation['capacity']) ?? 0,
            placesUtilisees: _entier(participation['used_places']) ?? 0,
            placesDisponibles: places,
            placesRestantes:
                _entier(participation['remaining_places']) ?? places,
            disponible: participation.containsKey('available')
                ? participation['available'] == true
                : places > 0,
            fraisRequis: participation['fees_required'] == true,
            montantFrais: _decimal(participation['amount']) ?? 0,
            devise: participation['currency']?.toString() ?? '',
            conditions: _texteOptionnel(participation['conditions']),
            adresse: hopital['address']?.toString(),
            commune: commune,
            ville: ville,
            description: hopital['description']?.toString() ?? '',
            telephone: hopital['phone']?.toString() ?? '',
            services: _servicesHopital(
              hopital['services'] ?? participation['services'],
            ),
            latitude: _decimal(hopital['latitude']),
            longitude: _decimal(hopital['longitude']),
          );
        }).toList() ??
        const <HopitalCampagne>[];

    final mode = json['mode'] is Map
        ? Map<String, dynamic>.from(json['mode'] as Map)
        : const <String, dynamic>{};
    final typeStage = json['stage_type'] is Map
        ? Map<String, dynamic>.from(json['stage_type'] as Map)
        : const <String, dynamic>{};
    final promotion = json['promotion'] is Map
        ? Map<String, dynamic>.from(json['promotion'] as Map)
        : const <String, dynamic>{};
    final debut = json['start_date']?.toString() ?? '';
    final fin = json['end_date']?.toString() ?? '';
    final academicEnrollmentId = _entier(json['academic_enrollment_id']);
    final autoriseReservationAutonome =
        mode['self_reservation_allowed'] != false;
    final fraisRequis = hopitaux.any((hopital) => hopital.fraisRequis);
    final montants = hopitaux
        .where((hopital) => hopital.montantFrais > 0)
        .map((hopital) => hopital.montantFrais)
        .toSet();

    return CampagneStage(
      id: json['campaign_id']?.toString() ?? json['id']?.toString() ?? '',
      code: json['code']?.toString() ?? '',
      academicEnrollmentId: academicEnrollmentId,
      isD4: mode['is_d4'] == true || typeStage['code'] == 'MEDICAL_D4',
      autoriseReservationAutonome: autoriseReservationAutonome,
      modeReservation:
          mode['reservation_mode']?.toString() ??
          (autoriseReservationAutonome
              ? 'SELF_RESERVATION'
              : 'UNIVERSITY_MANAGED'),
      typeStageCode: typeStage['code']?.toString() ?? '',
      typeStageLibelle: typeStage['label']?.toString() ?? '',
      promotionCode: promotion['code']?.toString() ?? '',
      promotionNom: promotion['name']?.toString() ?? '',
      niveau: promotion['level']?.toString() ?? '',
      titre: json['title']?.toString() ?? json['titre']?.toString() ?? '',
      sousTitre: json['program']?.toString() ?? '',
      dateDebut: debut,
      dateFin: fin,
      periodeTexte: debut.isNotEmpty && fin.isNotEmpty ? '$debut - $fin' : '',
      indemnite: fraisRequis && montants.length == 1
          ? '${_formaterMontant(montants.first)} ${hopitaux.first.devise}'
                .trim()
          : fraisRequis
          ? 'Frais variables'
          : 'Gratuit',
      modalite: json['modality']?.toString() ?? '',
      statut: json['status']?.toString() ?? 'OUVERTE',
      nombreHopitaux: _entier(json['hospitals_count']) ?? hopitaux.length,
      nombreHopitauxDisponibles:
          _entier(json['available_hospitals']) ??
          hopitaux.where((hopital) => hopital.peutReserver).length,
      estEligible:
          json['eligible'] == true ||
          json['is_eligible'] == true ||
          academicEnrollmentId != null,
      messageEligibilite: json['eligibility_message']?.toString() ?? '',
      consignes:
          (json['instructions'] as List?)
              ?.map((element) => element.toString())
              .toList() ??
          const [],
      criteresEligibilite:
          (json['eligibility_criteria'] as List?)
              ?.map((element) => element.toString())
              .toList() ??
          const [],
      hopitaux: hopitaux,
    );
  }

  static int? _entier(Object? valeur) =>
      valeur is num ? valeur.toInt() : int.tryParse(valeur?.toString() ?? '');

  static double? _decimal(Object? valeur) => valeur is num
      ? valeur.toDouble()
      : double.tryParse(valeur?.toString() ?? '');

  static String? _texteOptionnel(Object? valeur) {
    final texte = valeur?.toString().trim() ?? '';
    return texte.isEmpty ? null : texte;
  }

  static String _formaterMontant(double valeur) =>
      valeur == valeur.roundToDouble()
      ? valeur.toStringAsFixed(0)
      : valeur.toStringAsFixed(2);

  static List<String> _servicesHopital(Object? valeur) {
    if (valeur is! List) return const [];

    final services = <String>[];
    final nomsDejaAjoutes = <String>{};
    for (final service in valeur) {
      final nom = service is Map
          ? service['name']?.toString().trim()
          : service?.toString().trim();
      if (nom != null && nom.isNotEmpty && nomsDejaAjoutes.add(nom)) {
        services.add(nom);
      }
    }
    return services;
  }
}
