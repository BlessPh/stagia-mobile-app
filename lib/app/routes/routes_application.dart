import 'package:flutter/material.dart';
import '../../features/authentication/presentation/pages/connexion_page.dart';
import '../../features/authentication/presentation/pages/mot_de_passe_oublie_page.dart';
import '../../features/authentication/presentation/pages/reinitialisation_mot_de_passe_page.dart';
import '../../features/demarrage/presentation/pages/ecran_demarrage.dart';
import '../navigation/main_shell.dart';

abstract final class RoutesApplication {
  static const demarrage = '/';
  static const connexion = '/connexion';
  static const motDePasseOublie = '/mot-de-passe-oublie';
  static const reinitialiserMotDePasse = '/reinitialiser-mot-de-passe';
  static const tableauDeBord = '/tableau-de-bord';

  static Route<dynamic> generer(RouteSettings parametres) {
    final nom = parametres.name ?? '';
    final uri = Uri.tryParse(nom);
    final chemin = uri?.path ?? nom;

    final Widget page;
    if (chemin == connexion) {
      page = const ConnexionPage();
    } else if (chemin == motDePasseOublie) {
      page = const MotDePasseOubliePage();
    } else if (chemin == reinitialiserMotDePasse ||
        chemin.endsWith('/reset-password') ||
        chemin.endsWith('reinitialiser-mot-de-passe')) {
      final token = uri?.queryParameters['token'] ??
          (parametres.arguments is String ? parametres.arguments as String : '');
      page = ReinitialisationMotDePassePage(token: token);
    } else if (chemin == tableauDeBord) {
      page = const MainShell();
    } else {
      page = const EcranDemarrage();
    }

    return MaterialPageRoute<dynamic>(
      builder: (_) => page,
      settings: parametres,
    );
  }
}
