import 'package:flutter/material.dart';
import '../../../../core/mocks/depot_mock_etudiant.dart';
import '../../../../core/network/client_api_http.dart';
import '../../../../core/network/configuration_api.dart';
import '../../../../core/network/source_etudiant_distante.dart';
import '../../../../core/services/session_authentification_service.dart';
import '../../../../core/widgets/contenu_adaptatif.dart';
import 'home_premiere_connexion_page.dart';
import 'home_shared_widgets.dart';
import 'home_stage_actif_page.dart';

const Map<String, String> _superviseurSimule = {
  'id': 'superviseur-local-001',
  'nom': 'Dr Jean Mbala',
};

class HomePage extends StatefulWidget {
  const HomePage({this.onOuvrirStages, super.key});

  final VoidCallback? onOuvrirStages;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final _source = SourceEtudiantDistante(ClientApiHttp());
  late Future<List<Map<String, dynamic>>> _chargement;
  Map<String, dynamic> _identiteSession = const {};

  @override
  void initState() {
    super.initState();
    DepotMockEtudiant.changements.addListener(_donneesLocalesModifiees);
    _chargement = _charger();
    _chargerIdentiteSession();
  }

  Future<void> _chargerIdentiteSession() async {
    final identite = await SessionAuthentificationService.identite();
    if (mounted) setState(() => _identiteSession = identite);
  }

  @override
  void dispose() {
    DepotMockEtudiant.changements.removeListener(_donneesLocalesModifiees);
    super.dispose();
  }

  void _donneesLocalesModifiees() {
    if (mounted) setState(() => _chargement = _charger());
  }

  Future<List<Map<String, dynamic>>> _charger() async {
    final debut = DateTime.now();
    final donnees = await Future.wait([
      _source.tableauDeBord(),
      _source.candidatures(),
      _chargerProfil(),
    ]);
    final tempsEcoule = DateTime.now().difference(debut);
    final dureeMinimale = ConfigurationApi.utiliserDonneesMockees
        ? const Duration(seconds: 3) // la durée de skeleton en mock
        : const Duration(seconds: 3);
    if (tempsEcoule < dureeMinimale) {
      await Future<void>.delayed(dureeMinimale - tempsEcoule);
    }
    return donnees;
  }

  Future<Map<String, dynamic>> _chargerProfil() async {
    try {
      return await _source.profil();
    } catch (_) {
      return const <String, dynamic>{};
    }
  }

  Future<void> _actualiser() async {
    final futur = _charger();
    setState(() => _chargement = futur);
    await futur;
  }

  @override
  Widget build(
    BuildContext context,
  ) => FutureBuilder<List<Map<String, dynamic>>>(
    future: _chargement,
    builder: (context, snapshot) {
      final donnees = snapshot.data?.first ?? const <String, dynamic>{};
      final candidatures = snapshot.data != null && snapshot.data!.length > 1
          ? snapshot.data![1]
          : const <String, dynamic>{};
      final profil = snapshot.data != null && snapshot.data!.length > 2
          ? snapshot.data![2]
          : const <String, dynamic>{};
      final enChargement = snapshot.connectionState == ConnectionState.waiting;

      final etudiant = <String, dynamic>{};
      void ajouterIdentite(Map<String, dynamic> source) {
        for (final entree in source.entries) {
          if (entree.value.toString().trim().isNotEmpty) {
            etudiant[entree.key] = entree.value;
          }
        }
      }

      ajouterIdentite(mapApi(profil['user']));
      ajouterIdentite(mapApi(profil['student']));
      ajouterIdentite(mapApi(donnees['user']));
      ajouterIdentite(mapApi(donnees['student']));
      for (final entree in _identiteSession.entries) {
        if (entree.value.toString().trim().isNotEmpty) {
          etudiant[entree.key] = entree.value;
        }
      }
      return Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        appBar: EnTeteAccueil(
          etudiant: etudiant,
          superviseur: _superviseurActuel(donnees),
          chargement: enChargement,
        ),
        body: ContenuAdaptatif(
          enfant: snapshot.hasError
              ? ErreurAccueil(onReessayer: _actualiser)
              : RefreshIndicator(
                  color: const Color(0xFFFF7417),
                  onRefresh: _actualiser,
                  child: _interfaceAccueil(
                    donnees: donnees,
                    candidatures: listeApi(candidatures['items']),
                    chargement: enChargement,
                  ),
                ),
        ),
      );
    },
  );

  Map<String, String>? _superviseurActuel(Map<String, dynamic> donnees) {
    final stage = mapApi(donnees['current_stage']);
    if (stage.isEmpty) return _superviseurSimule;

    final rotations = listeApi(
      stage['rotations'] ??
          stage['rotation_items'] ??
          mapApi(stage['parcours'])['rotations'],
    );
    final rotation = rotations.isEmpty
        ? const <String, dynamic>{}
        : rotations.first;
    final objets = [
      mapApi(stage['supervisor']),
      mapApi(stage['superviseur']),
      mapApi(rotation['supervisor']),
      mapApi(rotation['superviseur']),
    ];

    String premier(List<Object?> valeurs) {
      for (final valeur in valeurs) {
        if (valeur is Map || valeur is Iterable) continue;
        final texte = valeur?.toString().trim() ?? '';
        if (texte.isNotEmpty && texte != 'null') return texte;
      }
      return '';
    }

    final id = premier([
      stage['supervisor_id'],
      stage['superviseur_id'],
      rotation['supervisor_id'],
      rotation['superviseur_id'],
      for (final objet in objets) objet['uuid'],
      for (final objet in objets) objet['id'],
    ]);
    final nom = premier([
      stage['supervisor_name'],
      stage['superviseur_name'],
      stage['supervisor'],
      stage['superviseur'],
      rotation['supervisor_name'],
      rotation['superviseur_name'],
      rotation['supervisor'],
      rotation['superviseur'],
      for (final objet in objets) objet['name'],
      for (final objet in objets) objet['nom_complet'],
    ]);
    if (nom.isEmpty) return _superviseurSimule;
    return {
      'id': id.isEmpty ? 'nom-${Uri.encodeComponent(nom.toLowerCase())}' : id,
      'nom': nom,
    };
  }

  Widget _interfaceAccueil({
    required Map<String, dynamic> donnees,
    required List<Map<String, dynamic>> candidatures,
    required bool chargement,
  }) {
    final stats = mapApi(donnees['stats']);
    if (entierApi(stats['stages']) == 0) {
      return HomePremiereConnexionPage(
        candidatures: candidatures,
        chargement: chargement,
      );
    }

    return HomeStageActifPage(donnees: donnees, chargement: chargement);
  }
}
