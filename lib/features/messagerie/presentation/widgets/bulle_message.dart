import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../domain/entities/message_chat.dart';
import 'apercu_reponse_widget.dart';
import 'lecteur_vocal_widget.dart';
import 'statut_lecture_icone.dart';

class BulleMessage extends StatelessWidget {
  const BulleMessage({
    required this.message,
    required this.onRepondre,
    this.afficherNomExpediteur = false,
    super.key,
  });

  final MessageChat message;
  final VoidCallback onRepondre;
  final bool afficherNomExpediteur;

  @override
  Widget build(BuildContext context) {
    final modeSombre = Theme.of(context).brightness == Brightness.dark;
    final largeurEcran = MediaQuery.sizeOf(context).width;
    final estTablette = largeurEcran >= 600;
    final largeurMax = estTablette ? 460.0 : largeurEcran * 0.78;

    final fond = message.estMien
        ? const Color(0xFF1D61F2)
        : (modeSombre ? const Color(0xFF262626) : const Color(0xFFF1F5F9));

    final bordureRayon = message.estMien
        ? const BorderRadius.only(
            topLeft: Radius.circular(18),
            topRight: Radius.circular(18),
            bottomLeft: Radius.circular(18),
            bottomRight: Radius.circular(4),
          )
        : const BorderRadius.only(
            topLeft: Radius.circular(18),
            topRight: Radius.circular(18),
            bottomLeft: Radius.circular(4),
            bottomRight: Radius.circular(18),
          );

    final couleurTexte = message.estMien
        ? Colors.white
        : (modeSombre ? const Color(0xFFF8FAFC) : const Color(0xFF0F172A));

    final couleurHeure = message.estMien
        ? Colors.white.withValues(alpha: 0.75)
        : const Color(0xFF94A3B8);

    return Align(
      alignment: message.estMien ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(maxWidth: largeurMax),
        margin: const EdgeInsets.symmetric(vertical: 3.5),
        child: GestureDetector(
          onLongPress: onRepondre,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: fond,
              borderRadius: bordureRayon,
              boxShadow: [
                BoxShadow(
                  color: message.estMien
                      ? const Color(0xFF1D61F2).withValues(alpha: 0.18)
                      : Colors.black.withValues(alpha: 0.03),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: message.estMien
                  ? CrossAxisAlignment.end
                  : CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Nom de l'expéditeur si groupe et message entrant
                if (afficherNomExpediteur && !message.estMien) ...[
                  Text(
                    message.expediteurNom,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF1D61F2),
                    ),
                  ),
                  const SizedBox(height: 4),
                ],

                // Réponse citée si présente
                if (message.reponseA != null) ...[
                  ApercuReponseWidget(
                    message: message.reponseA!,
                    estDansBulle: true,
                    estMien: message.estMien,
                  ),
                  const SizedBox(height: 6),
                ],

                // Contenu selon le type
                if (message.type == TypeMessage.vocal)
                  LecteurVocalWidget(
                    duree: message.dureeVocal ?? const Duration(seconds: 15),
                    estMien: message.estMien,
                  )
                else if (message.type == TypeMessage.document)
                  _CarteDocumentMessage(
                    nomFichier: message.nomFichier ?? 'Document.pdf',
                    tailleFichier: message.tailleFichier ?? '1.0 Mo',
                    estMien: message.estMien,
                  )
                else
                  Text(
                    message.texte,
                    style: GoogleFonts.inter(
                      fontSize: 14.5,
                      height: 1.4,
                      color: couleurTexte,
                    ),
                  ),

                const SizedBox(height: 4),

                // Heure et statut
                Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      message.heureAffichee,
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: couleurHeure,
                      ),
                    ),
                    if (message.estMien) ...[
                      const SizedBox(width: 4),
                      StatutLectureIcone(
                        statut: message.statut,
                        estSurBulleBleue: true,
                        taille: 13,
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CarteDocumentMessage extends StatelessWidget {
  const _CarteDocumentMessage({
    required this.nomFichier,
    required this.tailleFichier,
    required this.estMien,
  });

  final String nomFichier;
  final String tailleFichier;
  final bool estMien;

  @override
  Widget build(BuildContext context) {
    final fondDoc = estMien
        ? Colors.white.withValues(alpha: 0.15)
        : const Color(0xFFE2E8F0);

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: fondDoc,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: estMien ? Colors.white : const Color(0xFF1D61F2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.picture_as_pdf_rounded,
              color: estMien ? const Color(0xFF1D61F2) : Colors.white,
              size: 22,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  nomFichier,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: estMien ? Colors.white : const Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  tailleFichier,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: estMien
                        ? Colors.white.withValues(alpha: 0.75)
                        : const Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 6),
          Icon(
            Icons.download_rounded,
            color: estMien ? Colors.white : const Color(0xFF1D61F2),
            size: 20,
          ),
        ],
      ),
    );
  }
}
