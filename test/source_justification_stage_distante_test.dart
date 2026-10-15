import 'package:flutter_test/flutter_test.dart';
import 'package:stagia/core/network/client_api.dart';
import 'package:stagia/core/network/endpoints_api.dart';
import 'package:stagia/core/network/source_etudiant_distante.dart';

void main() {
  test('charge les situations calculées par le serveur', () async {
    final client = _ClientJustifications(
      reponseGet: {
        'success': true,
        'data': {
          'items': [
            {'assignment_uuid': 'assignment-1', 'situation': 'INTERRUPTION'},
          ],
          'allowed_values': {
            'reasons': ['MALADIE', 'AUTRE'],
          },
        },
      },
    );
    final resultat = await SourceEtudiantDistante(client).justificationsStage();
    expect(client.chemin, EndpointsApi.justificationsStageEtudiant);
    expect((resultat['items'] as List), hasLength(1));
  });

  test('envoie du JSON quand aucun document n’est joint', () async {
    final client = _ClientJustifications(
      reponsePost: {
        'success': true,
        'data': {
          'justification': {'justification_status': 'EN_ATTENTE'},
        },
      },
    );
    await SourceEtudiantDistante(client).soumettreJustificationStage(
      assignmentUuid: 'assignment-1',
      typeSituation: 'INTERRUPTION',
      motif: 'MALADIE',
    );
    expect(client.chemin, EndpointsApi.justificationsStageEtudiant);
    expect(client.corps, {
      'assignment_uuid': 'assignment-1',
      'type_situation': 'INTERRUPTION',
      'motif': 'MALADIE',
    });
    expect(client.cheminFichier, isNull);
  });

  test('envoie du multipart seulement lorsqu’un document est joint', () async {
    final client = _ClientJustifications(
      reponseUpload: {
        'success': true,
        'data': {
          'justification': {'justification_status': 'EN_ATTENTE'},
        },
      },
    );
    await SourceEtudiantDistante(client).soumettreJustificationStage(
      assignmentUuid: 'assignment-1',
      typeSituation: 'NON_DEMARRAGE',
      motif: 'AUTRE',
      explication: 'Contrainte documentée',
      cheminDocument: 'C:/temp/preuve.pdf',
    );
    expect(client.chemin, EndpointsApi.justificationsStageEtudiant);
    expect(client.cleFichier, 'document');
    expect(client.cheminFichier, 'C:/temp/preuve.pdf');
    expect(client.champs, {
      'assignment_uuid': 'assignment-1',
      'type_situation': 'NON_DEMARRAGE',
      'motif': 'AUTRE',
      'explication': 'Contrainte documentée',
    });
  });

  test('marque explicitement la décision comme lue', () async {
    final client = _ClientJustifications(
      reponsePost: {
        'success': true,
        'data': {'uuid': 'justification-1'},
      },
    );
    await SourceEtudiantDistante(
      client,
    ).marquerDecisionJustificationLue('justification-1');
    expect(
      client.chemin,
      EndpointsApi.lireDecisionJustificationStageEtudiant('justification-1'),
    );
    expect(client.corps, <String, dynamic>{});
  });

  test('télécharge uniquement le justificatif demandé', () async {
    final client = _ClientJustifications(octets: [37, 80, 68, 70]);
    final resultat = await SourceEtudiantDistante(
      client,
    ).fichierJustificationStage('justification-1', download: true);
    expect(resultat, [37, 80, 68, 70]);
    expect(
      client.chemin,
      EndpointsApi.fichierJustificationStageEtudiant('justification-1'),
    );
    expect(client.parametres, {'download': 1});
  });
}

class _ClientJustifications implements ClientApi {
  _ClientJustifications({
    this.reponseGet,
    this.reponsePost,
    this.reponseUpload,
    this.octets = const [],
  });
  final Map<String, dynamic>? reponseGet;
  final Map<String, dynamic>? reponsePost;
  final Map<String, dynamic>? reponseUpload;
  final List<int> octets;
  String? chemin;
  Object? corps;
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
  Future<Map<String, dynamic>> post(
    String chemin, {
    Object? corps,
    Map<String, String>? entetes,
  }) async {
    this.chemin = chemin;
    this.corps = corps;
    return reponsePost!;
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
  Future<Map<String, dynamic>> patch(String chemin, {Object? corps}) =>
      throw UnimplementedError();

  @override
  Future<Map<String, dynamic>> delete(String chemin) =>
      throw UnimplementedError();
}
