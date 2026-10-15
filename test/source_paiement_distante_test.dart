import 'package:flutter_test/flutter_test.dart';
import 'package:stagia/core/network/client_api.dart';
import 'package:stagia/core/network/endpoints_api.dart';
import 'package:stagia/core/network/reponse_api.dart';
import 'package:stagia/core/network/source_etudiant_distante.dart';

void main() {
  test('une collection API vide reste vide sans fallback mock', () async {
    final client = _ClientPaiementEspion(
      reponseGet: {'success': true, 'message': '', 'data': _collectionVide()},
    );

    final resultat = await SourceEtudiantDistante(client).paiements(
      status: ['PENDING', 'PARTIALLY_PAID'],
      type: 'STAGE_RESERVATION',
    );

    expect(client.cheminGet, EndpointsApi.paiementsEtudiant);
    expect(client.parametresGet, {
      'status': 'PENDING,PARTIALLY_PAID',
      'type': 'STAGE_RESERVATION',
    });
    expect(resultat['items'], isEmpty);
    expect(resultat['obligations'], isEmpty);
  });

  test('une erreur réseau de paiements est propagée sans mock', () async {
    final client = _ClientPaiementEspion(
      erreurGet: const ErreurApi(
        code: 'SERVEUR_INJOIGNABLE',
        message: 'Serveur inaccessible.',
      ),
    );

    expect(
      () => SourceEtudiantDistante(client).paiements(),
      throwsA(
        isA<ErreurApi>().having(
          (erreur) => erreur.code,
          'code',
          'SERVEUR_INJOIGNABLE',
        ),
      ),
    );
  });

  test('une réponse de collection incomplète est refusée', () async {
    final client = _ClientPaiementEspion(
      reponseGet: {
        'success': true,
        'message': '',
        'data': {'items': <Map<String, dynamic>>[]},
      },
    );

    expect(
      () => SourceEtudiantDistante(client).paiements(),
      throwsA(
        isA<ErreurApi>().having(
          (erreur) => erreur.code,
          'code',
          'DONNEES_PAIEMENTS_INVALIDES',
        ),
      ),
    );
  });

  test('charge le détail canonique d’une obligation', () async {
    final client = _ClientPaiementEspion(
      reponseGet: {
        'success': true,
        'message': 'Obligation chargée.',
        'data': {
          'obligation': {
            'uuid': 'obligation-1',
            'status': 'PENDING',
            'actions': {
              'initiate': {'allowed': true},
              'sync': {'allowed': false},
            },
          },
        },
      },
    );

    final resultat = await SourceEtudiantDistante(
      client,
    ).detailPaiement('obligation-1');

    expect(
      client.cheminGet,
      EndpointsApi.detailPaiementEtudiant('obligation-1'),
    );
    expect((resultat['obligation'] as Map)['uuid'], 'obligation-1');
  });

  test(
    'initie sans montant, devise ou callback et garde la clé fournie',
    () async {
      final client = _ClientPaiementEspion(
        reponsePost: {
          'success': true,
          'message': 'Paiement initié.',
          'data': {
            'payment': {'uuid': 'payment-1', 'status': 'INITIE'},
            'obligation': {'uuid': 'obligation-1', 'status': 'PENDING'},
            'reservation_uuid': 'reservation-1',
          },
        },
      );

      final resultat = await SourceEtudiantDistante(client).initierPaiement(
        obligationUuid: 'obligation-1',
        channel: 'mpesa',
        phoneNumber: '+243810000000',
        idempotencyKey: 'mobile-payment-1',
      );

      expect(client.cheminPost, EndpointsApi.initierPaiementEtudiant);
      expect(client.entetesPost, {'Idempotency-Key': 'mobile-payment-1'});
      expect(client.corpsPost, {
        'obligation_uuid': 'obligation-1',
        'channel': 'MPESA',
        'phone_number': '+243810000000',
        'idempotency_key': 'mobile-payment-1',
      });
      expect((resultat['payment'] as Map)['status'], 'INITIE');
    },
  );

  test('synchronise uniquement la cible financière canonique', () async {
    final client = _ClientPaiementEspion(
      reponsePost: {
        'success': true,
        'message': 'État synchronisé.',
        'data': {
          'reservation_uuid': 'reservation-1',
          'reservation_status': 'CONFIRMEE',
          'payment_status': 'PAID',
          'invoice_status': 'PAYEE',
          'amount_remaining': 0,
        },
      },
    );

    final resultat = await SourceEtudiantDistante(
      client,
    ).paiementSync(obligationUuid: 'obligation-1');

    expect(client.cheminPost, EndpointsApi.paiementSync);
    expect(client.corpsPost, {'obligation_uuid': 'obligation-1'});
    expect(resultat['payment_status'], 'PAID');
  });
}

Map<String, dynamic> _collectionVide() => {
  'items': <Map<String, dynamic>>[],
  'obligations': <Map<String, dynamic>>[],
  'obligation_stats': {
    'total': 0,
    'payable': 0,
    'pending': 0,
    'paid': 0,
    'failed': 0,
    'cancelled': 0,
    'expired': 0,
  },
  'stats': {
    'total': 0,
    'payable': 0,
    'paid': 0,
    'pending': 0,
    'failed': 0,
    'free': 0,
  },
  'channels': {
    'MPESA': 'M-Pesa',
    'ORANGE_MONEY': 'Orange Money',
    'AIRTEL_MONEY': 'Airtel Money',
    'AFRIMONEY': 'Afrimoney',
  },
};

class _ClientPaiementEspion implements ClientApi {
  _ClientPaiementEspion({this.reponseGet, this.reponsePost, this.erreurGet});

  final Map<String, dynamic>? reponseGet;
  final Map<String, dynamic>? reponsePost;
  final Object? erreurGet;
  String? cheminGet;
  Map<String, dynamic>? parametresGet;
  String? cheminPost;
  Object? corpsPost;
  Map<String, String>? entetesPost;

  @override
  Future<Map<String, dynamic>> get(
    String chemin, {
    Map<String, dynamic>? parametres,
  }) async {
    cheminGet = chemin;
    parametresGet = parametres;
    if (erreurGet case final erreur?) throw erreur;
    return reponseGet!;
  }

  @override
  Future<Map<String, dynamic>> post(
    String chemin, {
    Object? corps,
    Map<String, String>? entetes,
  }) async {
    cheminPost = chemin;
    corpsPost = corps;
    entetesPost = entetes;
    return reponsePost!;
  }

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
