import 'package:flutter_test/flutter_test.dart';
import 'package:stagia/core/network/client_api.dart';
import 'package:stagia/core/network/endpoints_api.dart';
import 'package:stagia/core/network/source_etudiant_distante.dart';

void main() {
  test(
    'charge les rattachements puis le parcours de l inscription choisie',
    () async {
      final client = _ClientAcademiqueEspion();
      final source = SourceEtudiantDistante(client);

      final rattachements = await source.rattachements();
      final parcours = await source.parcoursAcademique(43);

      expect((rattachements['items'] as List).single['enrollment_id'], 43);
      expect(client.chemins, [
        EndpointsApi.rattachementsEtudiant,
        EndpointsApi.parcoursAcademiqueEtudiant,
      ]);
      expect(client.derniersParametres, {'enrollment_id': 43});
      expect((parcours['academic_years'] as List).single['level'], 'L1');
    },
  );
}

class _ClientAcademiqueEspion implements ClientApi {
  final chemins = <String>[];
  Map<String, dynamic>? derniersParametres;

  @override
  Future<Map<String, dynamic>> get(
    String chemin, {
    Map<String, dynamic>? parametres,
  }) async {
    chemins.add(chemin);
    derniersParametres = parametres;
    if (chemin == EndpointsApi.rattachementsEtudiant) {
      return {
        'success': true,
        'message': '',
        'data': {
          'items': [
            {'enrollment_id': 43, 'is_active': true},
          ],
          'total': 1,
        },
      };
    }
    return {
      'success': true,
      'message': '',
      'data': {
        'academic_years': [
          {
            'academic_year': {'label': '2026-2027'},
            'promotion': {'name': 'Médecine · 2026-2027 · L1'},
            'level': 'L1',
            'is_current': true,
          },
        ],
      },
    };
  }

  @override
  Future<Map<String, dynamic>> post(
    String chemin, {
    Object? corps,
    Map<String, String>? entetes,
  }) => throw UnimplementedError();

  @override
  Future<Map<String, dynamic>> patch(String chemin, {Object? corps}) =>
      throw UnimplementedError();

  @override
  Future<Map<String, dynamic>> delete(String chemin) =>
      throw UnimplementedError();

  @override
  Future<Map<String, dynamic>> envoyerFichier(
    String chemin, {
    required String cheminFichier,
    required Map<String, String> champs,
    String cleFichier = 'document',
  }) => throw UnimplementedError();

  @override
  Future<List<int>> getBytes(
    String chemin, {
    Map<String, dynamic>? parametres,
  }) => throw UnimplementedError();
}
