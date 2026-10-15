import 'package:flutter_test/flutter_test.dart';
import 'package:stagia/core/network/client_api.dart';
import 'package:stagia/core/network/endpoints_api.dart';
import 'package:stagia/core/network/source_etudiant_distante.dart';

void main() {
  test('charge les clôtures avec les filtres du contrat', () async {
    final client = _ClientFinStage({
      'success': true,
      'data': {
        'items': [
          {'status': 'PRET', 'score': 18},
        ],
      },
    });
    final resultat = await SourceEtudiantDistante(client).cloturesStage(
      status: ['PRET', 'VALIDE'],
      assignmentUuid: 'assignment-1',
      hospitalId: 4,
      perPage: 50,
    );
    expect(client.chemin, EndpointsApi.cloturesStageEtudiant);
    expect(client.parametres?['status'], 'PRET,VALIDE');
    expect(client.parametres?['assignment_uuid'], 'assignment-1');
    expect(client.parametres?['hospital_id'], 4);
    expect((resultat['items'] as List).single['score'], isNull);
  });

  test('masque un résultat avant validation universitaire', () async {
    final client = _ClientFinStage({
      'success': true,
      'data': {
        'items': [
          {
            'decision': 'VALIDE',
            'score': 18,
            'appreciation': 'Très bien',
            'administrative_process': {
              'university_transmission': {'status': 'EN_ATTENTE'},
            },
            'document': {
              'uuid': 'certificate-1',
              'status': 'GENERE',
              'available': true,
              'file_endpoint': '/file',
            },
          },
        ],
      },
    });
    final resultat = await SourceEtudiantDistante(client).resultatsStage();
    final item = (resultat['items'] as List).single as Map;
    expect(item['decision'], isNull);
    expect(item['score'], isNull);
    expect((item['document'] as Map)['available'], isFalse);
    expect((item['document'] as Map)['file_endpoint'], isNull);
  });

  test('télécharge un certificat par son uuid', () async {
    final client = _ClientFinStage({'success': true, 'data': {}});
    client.octets = [37, 80, 68, 70];
    final octets = await SourceEtudiantDistante(
      client,
    ).fichierCertificat('certificate-1', download: true);
    expect(octets, [37, 80, 68, 70]);
    expect(client.chemin, EndpointsApi.fichierCertificat('certificate-1'));
    expect(client.parametres, {'download': 1});
  });
}

class _ClientFinStage implements ClientApi {
  _ClientFinStage(this.reponse);
  final Map<String, dynamic> reponse;
  List<int> octets = const [];
  String? chemin;
  Map<String, dynamic>? parametres;

  @override
  Future<Map<String, dynamic>> get(
    String chemin, {
    Map<String, dynamic>? parametres,
  }) async {
    this.chemin = chemin;
    this.parametres = parametres;
    return reponse;
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

  @override
  Future<Map<String, dynamic>> envoyerFichier(
    String chemin, {
    required String cheminFichier,
    required Map<String, String> champs,
    String cleFichier = 'document',
  }) => throw UnimplementedError();
}
