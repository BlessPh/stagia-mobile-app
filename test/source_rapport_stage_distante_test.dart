import 'package:flutter_test/flutter_test.dart';
import 'package:stagia/core/network/client_api.dart';
import 'package:stagia/core/network/endpoints_api.dart';
import 'package:stagia/core/network/source_etudiant_distante.dart';

void main() {
  test('transmet les filtres de la liste des rapports', () async {
    final client = _ClientRapports(
      reponseGet: {
        'success': true,
        'data': {'items': <Map<String, dynamic>>[]},
      },
    );
    await SourceEtudiantDistante(client).rapportsStage(
      status: ['SOUMIS', 'A_CORRIGER'],
      assignmentUuid: 'assignment-1',
      campaignUuid: 'campaign-1',
      dateFrom: '2026-01-01',
      dateTo: '2026-12-31',
      perPage: 100,
    );
    expect(client.chemin, EndpointsApi.rapportsStageEtudiant);
    expect(client.parametres, {
      'status': 'SOUMIS,A_CORRIGER',
      'assignment_uuid': 'assignment-1',
      'campaign_uuid': 'campaign-1',
      'date_from': '2026-01-01',
      'date_to': '2026-12-31',
      'page': 1,
      'per_page': 100,
    });
  });

  test('charge un rapport précis appartenant à l’étudiant', () async {
    final client = _ClientRapports(
      reponseGet: {
        'success': true,
        'data': {
          'report': {'uuid': 'report-1', 'version': 2},
        },
      },
    );
    final resultat = await SourceEtudiantDistante(
      client,
    ).detailRapportStage('report-1');
    expect(client.chemin, EndpointsApi.detailRapportStageEtudiant('report-1'));
    expect((resultat['report'] as Map)['version'], 2);
  });

  test('soumet le multipart sans inventer de champs', () async {
    final client = _ClientRapports(
      reponseUpload: {
        'success': true,
        'data': {
          'report': {'uuid': 'report-2', 'version': 1},
        },
      },
    );
    await SourceEtudiantDistante(client).soumettreRapportStage(
      assignmentUuid: 'assignment-1',
      cheminFichier: 'C:/temp/rapport.pdf',
      title: 'Rapport pédiatrie',
      description: 'Version initiale',
    );
    expect(client.chemin, EndpointsApi.rapportsStageEtudiant);
    expect(client.cheminFichier, 'C:/temp/rapport.pdf');
    expect(client.cleFichier, 'report');
    expect(client.champs, {
      'assignment_uuid': 'assignment-1',
      'title': 'Rapport pédiatrie',
      'description': 'Version initiale',
    });
  });

  test('ouvre le fichier avec le paramètre download documenté', () async {
    final client = _ClientRapports(octets: [1, 2, 3]);
    final resultat = await SourceEtudiantDistante(
      client,
    ).fichierRapportStage('report-1', download: true);
    expect(resultat, [1, 2, 3]);
    expect(client.chemin, EndpointsApi.fichierRapportStageEtudiant('report-1'));
    expect(client.parametres, {'download': 1});
  });
}

class _ClientRapports implements ClientApi {
  _ClientRapports({
    this.reponseGet,
    this.reponseUpload,
    this.octets = const [],
  });

  final Map<String, dynamic>? reponseGet;
  final Map<String, dynamic>? reponseUpload;
  final List<int> octets;
  String? chemin;
  Map<String, dynamic>? parametres;
  String? cheminFichier;
  String? cleFichier;
  Map<String, String>? champs;

  @override
  Future<Map<String, dynamic>> get(
    String chemin, {
    Map<String, dynamic>? parametres,
  }) async {
    this.chemin = chemin;
    this.parametres = parametres;
    return reponseGet!;
  }

  @override
  Future<Map<String, dynamic>> envoyerFichier(
    String chemin, {
    required String cheminFichier,
    required Map<String, String> champs,
    String cleFichier = 'document',
  }) async {
    this.chemin = chemin;
    this.cheminFichier = cheminFichier;
    this.champs = champs;
    this.cleFichier = cleFichier;
    return reponseUpload!;
  }

  @override
  Future<List<int>> getBytes(
    String chemin, {
    Map<String, dynamic>? parametres,
  }) async {
    this.chemin = chemin;
    this.parametres = parametres;
    return octets;
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
}
