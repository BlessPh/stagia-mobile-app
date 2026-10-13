import 'package:flutter_test/flutter_test.dart';
import 'package:stagia/core/mocks/scenario_etudiant_ui.dart';
import 'package:stagia/core/network/endpoints_api.dart';

void main() {
  test('le scénario couvre tout le parcours étudiant à afficher', () {
    final options = ScenarioEtudiantUi.pourEndpoint(
      EndpointsApi.optionsStageEtudiant,
    )!;
    final applications = ScenarioEtudiantUi.pourEndpoint(
      EndpointsApi.candidaturesEtudiant,
    )!;
    final stages = ScenarioEtudiantUi.pourEndpoint(
      EndpointsApi.stagesEtudiant,
    )!;

    expect(options['campaigns'], isNotEmpty);
    expect(
      (applications['items'] as List).map(
        (item) => (item as Map)['workflow_status'],
      ),
      containsAll([
        'PLACEMENT_UNIVERSITAIRE_EN_ATTENTE',
        'AFFECTATION_EN_ATTENTE',
      ]),
    );
    expect(
      (stages['items'] as List).map(
        (item) => (item as Map)['assignment_status'],
      ),
      containsAll(['ACTIVE', 'TERMINEE']),
    );
    expect(
      ScenarioEtudiantUi.pourEndpoint(EndpointsApi.tachesEtudiant)!['items'],
      isNotEmpty,
    );
    expect(
      ScenarioEtudiantUi.pourEndpoint(
        EndpointsApi.evaluationsEtudiant,
      )!['items'],
      isNotEmpty,
    );
  });

  test('les actions de pointage restent entièrement locales', () {
    final arrival = ScenarioEtudiantUi.pointerArrivee();
    expect((arrival['punch'] as Map)['next_action'], 'DEPART');

    final departure = ScenarioEtudiantUi.pointerDepart();
    expect((departure['punch'] as Map)['next_action'], 'TERMINE');
    expect(
      ((departure['punch'] as Map)['attendance'] as Map)['departure_time'],
      '16:10:00',
    );
  });
}
