import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../network/configuration_api.dart';
import '../network/endpoints_api.dart';
import 'session_authentification_service.dart';

/// Événement Server-Sent Events (SSE) typé
class SseEvenement {
  const SseEvenement({
    required this.nom,
    required this.donnees,
    this.id,
  });

  final String nom;
  final Map<String, dynamic> donnees;
  final String? id;

  @override
  String toString() => 'SseEvenement(nom: $nom, id: $id, donnees: $donnees)';
}

/// Service gérant la connexion temps réel SSE (`/student/notifications/stream`)
class SseNotificationsService extends ChangeNotifier {
  SseNotificationsService._();
  static final SseNotificationsService instance = SseNotificationsService._();

  http.Client? _clientHttp;
  bool _enCoursExecution = false;
  String? _dernierEventId;

  // Contrôleurs de flux par type d'événement
  final _controleurEvenements = StreamController<SseEvenement>.broadcast();
  final _controleurCompteurs = StreamController<Map<String, dynamic>>.broadcast();
  final _controleurNotifications = StreamController<Map<String, dynamic>>.broadcast();
  final _controleurMessages = StreamController<Map<String, dynamic>>.broadcast();
  final _controleurCommunications = StreamController<Map<String, dynamic>>.broadcast();
  final _controleurCalendrier = StreamController<Map<String, dynamic>>.broadcast();

  // Getters de flux publics
  Stream<SseEvenement> get fluxEvenements => _controleurEvenements.stream;
  Stream<Map<String, dynamic>> get fluxCompteurs => _controleurCompteurs.stream;
  Stream<Map<String, dynamic>> get fluxNotifications => _controleurNotifications.stream;
  Stream<Map<String, dynamic>> get fluxMessages => _controleurMessages.stream;
  Stream<Map<String, dynamic>> get fluxCommunications => _controleurCommunications.stream;
  Stream<Map<String, dynamic>> get fluxCalendrier => _controleurCalendrier.stream;

  Map<String, dynamic> _derniersCompteurs = {
    'notifications': 0,
    'messages': 0,
    'total': 0,
  };
  Map<String, dynamic> get derniersCompteurs => _derniersCompteurs;

  bool _estConnecte = false;
  bool get estConnecte => _estConnecte;

  /// Démarre l'écoute du flux SSE
  Future<void> demarrer() async {
    if (_enCoursExecution) return;
    _enCoursExecution = true;
    _boucleConnexion();
  }

  /// Arrête la connexion SSE (ex: lors de la déconnexion)
  void arreter() {
    _enCoursExecution = false;
    _estConnecte = false;
    _clientHttp?.close();
    _clientHttp = null;
    notifyListeners();
  }

  /// Émission manuelle pour le mode de simulation/mock
  void emettreEvenementSimule(String nom, Map<String, dynamic> donnees) {
    _traiterEvenement(nom, donnees, null);
  }

  Future<void> _boucleConnexion() async {
    while (_enCoursExecution) {
      final token = await SessionAuthentificationService.jeton();

      if (token == null || token.isEmpty) {
        // En attente d'authentification
        await Future<void>.delayed(const Duration(seconds: 2));
        continue;
      }

      if (ConfigurationApi.utiliserDonneesMockees) {
        // En mode mock, simule un état connecté stable
        if (!_estConnecte) {
          _estConnecte = true;
          notifyListeners();
        }
        await Future<void>.delayed(const Duration(seconds: 15));
        continue;
      }

      try {
        await _connecterStream(token);
      } catch (e) {
        debugPrint('[SSE] Déconnexion ou erreur : $e');
      }

      _estConnecte = false;
      notifyListeners();

      if (!_enCoursExecution) break;

      // Délai de reconnexion recommandé par le serveur : 3 secondes
      await Future<void>.delayed(const Duration(seconds: 3));
    }
  }

  Future<void> _connecterStream(String token) async {
    _clientHttp?.close();
    _clientHttp = http.Client();

    final base = Uri.parse(
      ConfigurationApi.urlBase.trim().isNotEmpty
          ? ConfigurationApi.urlBase.trim()
          : 'http://localhost/stagia/api/v1',
    );
    String basePath = base.path;
    while (basePath.endsWith('/')) {
      basePath = basePath.substring(0, basePath.length - 1);
    }
    String endpointPath = EndpointsApi.notificationsStream;
    if (basePath.isNotEmpty && endpointPath.startsWith(basePath)) {
      endpointPath = endpointPath.substring(basePath.length);
    }

    final queryParams = <String, String>{};
    if (_dernierEventId != null && _dernierEventId!.isNotEmpty) {
      queryParams['cursor'] = _dernierEventId!;
    }

    final uri = base.replace(
      path: '$basePath$endpointPath',
      queryParameters: queryParams.isNotEmpty ? queryParams : null,
    );

    final request = http.Request('GET', uri);
    request.headers.addAll({
      'Accept': 'text/event-stream',
      'Authorization': 'Bearer $token',
      'Cache-Control': 'no-cache',
      'ngrok-skip-browser-warning': 'true',
      ...?(_dernierEventId != null ? {'Last-Event-ID': _dernierEventId!} : null),
    });

    final response = await _clientHttp!.send(request);

    if (response.statusCode != 200) {
      throw Exception('Statut HTTP SSE invalide : ${response.statusCode}');
    }

    _estConnecte = true;
    notifyListeners();

    String nomEvenementEnCours = 'message';
    String? idEvenementEnCours;
    final bufferDonnees = StringBuffer();

    // Lecture continue du flux ligne par ligne
    await for (final line in response.stream.toStringStream().transform(const LineSplitter())) {
      if (!_enCoursExecution) break;

      final ligne = line.trim();

      if (ligne.isEmpty) {
        // Ligne vide = fin d'un bloc d'événement SSE
        if (bufferDonnees.isNotEmpty) {
          final rawData = bufferDonnees.toString();
          bufferDonnees.clear();

          try {
            final parsed = jsonDecode(rawData);
            if (parsed is Map) {
              _traiterEvenement(
                nomEvenementEnCours,
                Map<String, dynamic>.from(parsed),
                idEvenementEnCours,
              );
            }
          } catch (_) {
            // Ping ou donnée non JSON
          }
        }
        nomEvenementEnCours = 'message';
        idEvenementEnCours = null;
        continue;
      }

      if (ligne.startsWith(':')) {
        // Commentaire / keep-alive ping du serveur (ex: `: keep-alive`)
        continue;
      }

      if (ligne.startsWith('event:')) {
        nomEvenementEnCours = ligne.substring(6).trim();
      } else if (ligne.startsWith('data:')) {
        bufferDonnees.writeln(ligne.substring(5).trim());
      } else if (ligne.startsWith('id:')) {
        idEvenementEnCours = ligne.substring(3).trim();
        _dernierEventId = idEvenementEnCours;
      }
    }
  }

  void _traiterEvenement(String nom, Map<String, dynamic> donnees, String? id) {
    final event = SseEvenement(nom: nom, donnees: donnees, id: id);
    _controleurEvenements.add(event);

    switch (nom) {
      case 'ready':
      case 'counts':
        final counts = donnees['counts'] is Map
            ? Map<String, dynamic>.from(donnees['counts'] as Map)
            : donnees;
        _derniersCompteurs = counts;
        _controleurCompteurs.add(counts);
        notifyListeners();
        break;

      case 'notification':
        _controleurNotifications.add(donnees);
        if (donnees['counts'] is Map) {
          _derniersCompteurs = Map<String, dynamic>.from(donnees['counts'] as Map);
          _controleurCompteurs.add(_derniersCompteurs);
          notifyListeners();
        }
        break;

      case 'message':
        _controleurMessages.add(donnees);
        if (donnees['counts'] is Map) {
          _derniersCompteurs = Map<String, dynamic>.from(donnees['counts'] as Map);
          _controleurCompteurs.add(_derniersCompteurs);
          notifyListeners();
        }
        break;

      case 'communication':
        _controleurCommunications.add(donnees);
        break;

      case 'calendar':
        _controleurCalendrier.add(donnees);
        break;

      case 'error':
        debugPrint('[SSE Event Error] ${donnees['message']}');
        break;
    }
  }

  @override
  void dispose() {
    arreter();
    _controleurEvenements.close();
    _controleurCompteurs.close();
    _controleurNotifications.close();
    _controleurMessages.close();
    _controleurCommunications.close();
    _controleurCalendrier.close();
    super.dispose();
  }
}
