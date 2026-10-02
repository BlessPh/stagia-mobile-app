import 'package:flutter_test/flutter_test.dart';
import 'package:stagia/features/stage/domain/entities/campagne_stage.dart';
import 'package:stagia/features/stage/domain/entities/suivi_candidature_stage.dart';

void main() {
  test('mappe le workflow admissions et reconnaît la campagne engagée', () {
    final suivi = SuiviCandidatureStage.depuisAdmission({
      'reservation': {'uuid': 'reservation-1', 'status': 'CONFIRMEE'},
      'campaign': {
        'code': 'CAM-000039',
        'title': 'Stage de fin d’année 2026',
        'start_date': '2026-10-01',
        'end_date': '2026-10-31',
      },
      'hospital': {'name': 'Hôpital général'},
      'workflow_status': 'AFFECTATION_EN_ATTENTE',
      'workflow_message': 'Admission enregistrée, affectation en attente.',
    });

    const campagneDisponible = CampagneStage(
      id: '39',
      code: 'CAM-000039',
      titre: 'Stage de fin d’année 2026',
      sousTitre: 'Médecine',
      dateDebut: '2026-10-01',
      dateFin: '2026-10-31',
      periodeTexte: '2026-10-01 - 2026-10-31',
      indemnite: 'Gratuit',
      modalite: '',
      statut: 'OUVERTE',
      nombreHopitaux: 1,
      estEligible: true,
      consignes: [],
      criteresEligibilite: [],
      hopitaux: [],
    );

    expect(suivi.libelleStatut, 'En attente d’affectation');
    expect(suivi.progression, 5);
    expect(suivi.concerne(campagneDisponible), isTrue);

    final enrichi = suivi.avecCampagne(campagneDisponible);
    expect(enrichi.campagne.statut, 'En attente d’affectation');
    expect(enrichi.campagne.indemnite, 'Gratuit');
  });
}
