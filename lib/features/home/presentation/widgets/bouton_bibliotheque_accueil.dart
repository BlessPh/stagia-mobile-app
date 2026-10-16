import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/network/configuration_api.dart';

class BoutonBibliothequeAccueil extends StatelessWidget {
  const BoutonBibliothequeAccueil({
    this.texte = 'Accéder à la bibliothèque',
    this.titre = 'BIBLIOTHEQUE NUMERIQUE STAGIA',
    this.description =
        'Explorez une collection de livres, guides, mémoires et ressources pratiques pour apprendre, entreprendre et construire votre avenir.',
    this.cheminImage = 'assets/images/Biblio.jpg',
    super.key,
  });

  final String texte;
  final String titre;
  final String description;
  final String cheminImage;

  Future<void> _ouvrir(BuildContext context) async {
    final uri = Uri.parse(ConfigurationApi.urlBibliotheque);
    final ouverte = await launchUrl(uri, mode: LaunchMode.externalApplication);

    if (!ouverte && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Impossible d'ouvrir la bibliothèque.")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final modeSombre = Theme.of(context).brightness == Brightness.dark;
    final couleurFond = modeSombre ? const Color(0xFF151515) : Colors.white;
    final couleurTexte = modeSombre ? Colors.white : Colors.black;

    return Container(
      width: double.infinity,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: couleurFond,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: couleurTexte, width: 1.1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            height: 145,
            child: Image.asset(
              cheminImage,
              width: double.infinity,
              fit: BoxFit.cover,
              alignment: Alignment.center,
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 8),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                titre,
                maxLines: 1,
                softWrap: false,
                style: GoogleFonts.lato(
                  color: couleurTexte,
                  fontSize: 21,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.2,
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18),
            child: Text(
              description,
              maxLines: 5,
              style: GoogleFonts.poppins(
                color: couleurTexte.withValues(alpha: 0.72),
                fontSize: 13.5,
                fontWeight: FontWeight.w400,
                height: 1.5,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
            child: TextButton(
              onPressed: () => _ouvrir(context),
              style: TextButton.styleFrom(
                foregroundColor: modeSombre ? Colors.black : Colors.white,
                backgroundColor: modeSombre ? Colors.white : Colors.black,
                textStyle: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 15,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: Text(texte),
            ),
          ),
        ],
      ),
    );
  }
}
