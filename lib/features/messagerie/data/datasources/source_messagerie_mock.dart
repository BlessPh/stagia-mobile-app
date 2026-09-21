import '../../domain/entities/discussion.dart';
import '../../domain/entities/message_chat.dart';

abstract final class SourceMessagerieMock {
  static List<Discussion> obtenirDiscussions() {
    final maintenant = DateTime.now();
    return [
      Discussion(
        id: 'disc_mwamba',
        nom: 'Dr. Patrick Mwamba',
        roleOuService: 'Chirurgien Chef · Hôpital Général',
        dernierMessage: 'Bien reçu ! Bon travail pour cette garde.',
        date: maintenant.subtract(const Duration(minutes: 8)),
        categorie: CategorieDiscussion.encadreurs,
        nbNonLus: 2,
        estEnLigne: true,
        estEpingle: true,
        dernierMessageEstMien: false,
        statutMessage: StatutMessage.lu,
      ),
      Discussion(
        id: 'disc_garde_urgences',
        nom: 'Équipe Garde Urgences A',
        roleOuService: '5 stagiaires · 2 superviseurs',
        dernierMessage: 'Relève effectuée pour le box 3, cas stabilisé.',
        date: maintenant.subtract(const Duration(minutes: 34)),
        categorie: CategorieDiscussion.groupes,
        nbNonLus: 4,
        estGroupe: true,
        dernierMessageEstMien: false,
        statutMessage: StatutMessage.lu,
      ),
      Discussion(
        id: 'disc_diffusion',
        nom: 'Diffusion Décanat Santé',
        roleOuService: 'Canal Officiel de Diffusion',
        dernierMessage: 'Note de service : Validation semestrielle des stages cliniques.',
        date: maintenant.subtract(const Duration(hours: 3)),
        categorie: CategorieDiscussion.diffusion,
        nbNonLus: 1,
        estDiffusion: true,
        estEpingle: true,
        dernierMessageEstMien: false,
        statutMessage: StatutMessage.lu,
      ),
      Discussion(
        id: 'disc_sarah',
        nom: 'Dr. Sarah Lukusa',
        roleOuService: 'Pédiatre Superviseur · Cliniques Univ.',
        dernierMessage: 'Merci pour le compte-rendu, validation transmise.',
        date: maintenant.subtract(const Duration(hours: 6)),
        categorie: CategorieDiscussion.encadreurs,
        nbNonLus: 0,
        estEnLigne: false,
        dernierMessageEstMien: true,
        statutMessage: StatutMessage.lu,
      ),
      Discussion(
        id: 'disc_promo',
        nom: 'Promotion Médecine 2026',
        roleOuService: 'Forum d’entraide générale',
        dernierMessage: 'Est-ce que quelqu’un a le modèle du carnet de stage ?',
        date: maintenant.subtract(const Duration(days: 1)),
        categorie: CategorieDiscussion.general,
        nbNonLus: 0,
        estGroupe: true,
        dernierMessageEstMien: false,
        statutMessage: StatutMessage.lu,
      ),
    ];
  }

  static List<MessageChat> obtenirMessages(String discussionId) {
    final maintenant = DateTime.now();

    if (discussionId == 'disc_mwamba') {
      final m1 = MessageChat(
        id: 'm_1',
        texte: 'Bonjour Alfred, as-tu pu vérifier la radio thoracique post-opératoire de la patiente du lit 14 ?',
        date: maintenant.subtract(const Duration(hours: 2, minutes: 20)),
        estMien: false,
        expediteurNom: 'Dr. Patrick Mwamba',
        statut: StatutMessage.lu,
      );

      final m2 = MessageChat(
        id: 'm_2',
        texte: 'Bonjour Docteur ! Oui, je viens de passer dans le service. L’épanchement s’est bien résorbé, aucune complication visible.',
        date: maintenant.subtract(const Duration(hours: 2, minutes: 12)),
        estMien: true,
        expediteurNom: 'Moi',
        reponseA: m1,
        statut: StatutMessage.lu,
      );

      final m3 = MessageChat(
        id: 'm_3',
        texte: 'Message vocal (0:28)',
        date: maintenant.subtract(const Duration(hours: 1, minutes: 45)),
        estMien: false,
        expediteurNom: 'Dr. Patrick Mwamba',
        type: TypeMessage.vocal,
        dureeVocal: const Duration(seconds: 28),
        statut: StatutMessage.lu,
      );

      final m4 = MessageChat(
        id: 'm_4',
        texte: 'Fiche_Suivi_Patient_Lit14.pdf',
        date: maintenant.subtract(const Duration(minutes: 40)),
        estMien: true,
        expediteurNom: 'Moi',
        type: TypeMessage.document,
        nomFichier: 'Fiche_Suivi_Patient_Lit14.pdf',
        tailleFichier: '1.2 Mo',
        statut: StatutMessage.lu,
      );

      final m5 = MessageChat(
        id: 'm_5',
        texte: 'Voici également la fiche de suivi réactualisée avec les constantes du matin (TA: 12/8, Temp: 36.8°C).',
        date: maintenant.subtract(const Duration(minutes: 38)),
        estMien: true,
        expediteurNom: 'Moi',
        statut: StatutMessage.lu,
      );

      final m6 = MessageChat(
        id: 'm_6',
        texte: 'Bien reçu ! Bon travail pour cette garde.',
        date: maintenant.subtract(const Duration(minutes: 8)),
        estMien: false,
        expediteurNom: 'Dr. Patrick Mwamba',
        statut: StatutMessage.lu,
      );

      return [m1, m2, m3, m4, m5, m6];
    } else if (discussionId == 'disc_diffusion') {
      return [
        MessageChat(
          id: 'diff_1',
          texte: 'Chers étudiants stagiaires, le port du badge officiel et de la blouse immaculée est obligatoire dans tous les pavillons hospitaliers partenaires.',
          date: maintenant.subtract(const Duration(days: 2)),
          estMien: false,
          expediteurNom: 'Décanat Médecine',
          statut: StatutMessage.lu,
        ),
        MessageChat(
          id: 'diff_2',
          texte: 'Protocole_Sanitaire_2026.pdf',
          date: maintenant.subtract(const Duration(days: 1)),
          estMien: false,
          expediteurNom: 'Décanat Médecine',
          type: TypeMessage.document,
          nomFichier: 'Protocole_Sanitaire_2026.pdf',
          tailleFichier: '3.4 Mo',
          statut: StatutMessage.lu,
        ),
        MessageChat(
          id: 'diff_3',
          texte: 'Note de service : Validation semestrielle des stages cliniques et dépôt des carnets le 15 du mois prochain.',
          date: maintenant.subtract(const Duration(hours: 3)),
          estMien: false,
          expediteurNom: 'Décanat Médecine',
          statut: StatutMessage.lu,
        ),
      ];
    } else {
      return [
        MessageChat(
          id: 'gen_1',
          texte: 'Bonjour à tous, bienvenue dans ce canal de coordination clinique.',
          date: maintenant.subtract(const Duration(hours: 4)),
          estMien: false,
          expediteurNom: 'Superviseur',
          statut: StatutMessage.lu,
        ),
        MessageChat(
          id: 'gen_2',
          texte: 'Bien noté, présent et prêt pour la relève.',
          date: maintenant.subtract(const Duration(hours: 2)),
          estMien: true,
          expediteurNom: 'Moi',
          statut: StatutMessage.lu,
        ),
      ];
    }
  }

  static List<MessageChat> obtenirLotsAnciens(String discussionId) {
    final maintenant = DateTime.now();
    return [
      MessageChat(
        id: 'old_1',
        texte: 'Historique archivé : Attribution initiale du stage au service de chirurgie viscérale.',
        date: maintenant.subtract(const Duration(days: 5)),
        estMien: false,
        expediteurNom: 'Administration Clinique',
        statut: StatutMessage.lu,
      ),
      MessageChat(
        id: 'old_2',
        texte: 'Merci, j’ai bien confirmé ma présence auprès du secrétariat.',
        date: maintenant.subtract(const Duration(days: 4)),
        estMien: true,
        expediteurNom: 'Moi',
        statut: StatutMessage.lu,
      ),
    ];
  }
}
