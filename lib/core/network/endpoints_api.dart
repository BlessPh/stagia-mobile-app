abstract final class EndpointsApi {
  // Authentification et profil (API Mobile v1)
  static const connexion = '/login';
  static const deconnexion = '/logout';
  static const rafraichirToken = '/refresh-token';
  static const profilEtudiant = '/me';
  static const motDePasseOublie = '/forgot-password';
  static const reinitialiserMotDePasse = '/reset-password';

  // Étudiant & Stages (API Mobile v1)
  static const tableauDeBordEtudiant = '/student/dashboard';
  static const profilActifEtudiant = '/student/profile';
  static const rattachementsEtudiant = '/student/enrollments';
  static const parcoursAcademiqueEtudiant = '/student/academic-path';
  static const notesEtudiant = '/student/notes';
  static const optionsStageEtudiant = '/student/stage-options';
  static const reserverStage = '/student/reservations';
  static const candidaturesEtudiant = '/student/applications';
  static const reservationsEtudiant = '/student/reservations';
  static String confirmerReservationEtudiant(String uuid) =>
      '/student/reservations/$uuid/confirm';
  static String annulerReservationEtudiant(String uuid) =>
      '/student/reservations/$uuid/cancel';
  static const admissionEtudiant = '/student/admissions';
  static const paiementsEtudiant = '/student/payments';
  static const initierPaiementEtudiant = '/student/payments/initiate';
  static const paiementSync = '/student/payments/sync';

  // Suivi de Stage & Présences
  static const stagesEtudiant = '/student/stages';
  static const contextePointage = '/student/attendance/context';
  static const pointageArrivee = '/student/attendance/arrival';
  static const pointageDepart = '/student/attendance/departure';
  static const presencesEtudiant = '/student/attendance';

  // Journal de Stage
  static const journalEtudiant = '/student/logbook';
  static String soumettreJournal(String uuid) =>
      '/student/logbook/$uuid/submit';

  // Tâches de Stage
  static const tachesEtudiant = '/student/tasks';
  static String demarrerTache(String uuid) =>
      '/student/tasks/$uuid/start';
  static String commenterTache(String uuid) =>
      '/student/tasks/$uuid/comment';
  static String terminerTache(String uuid) =>
      '/student/tasks/$uuid/complete';

  // Feedbacks & Évaluations
  static const feedbacksEtudiant = '/student/feedbacks';
  static const evaluationsEtudiant = '/student/evaluations';

  // Documents
  static const documentsEtudiant = '/student/documents';
  static String fichierCertificat(String uuid, {bool download = false}) =>
      '/student/certificates/$uuid/file${download ? '?download=1' : ''}';
  static const conventionsEtudiant = '/student/conventions';
  static String fichierConvention(String uuid, {bool download = false}) =>
      '/student/conventions/$uuid/file${download ? '?download=1' : ''}';
  static const documentsAcademiques = '/student/academic-documents';
  static String fichierDocumentAcademique(int id, {bool download = false}) =>
      '/student/academic-documents/$id/file${download ? '?download=1' : ''}';
  static const documentsPersonnels = '/student/personal-documents';
  static String documentPersonnel(String uuid) =>
      '/student/personal-documents/$uuid';
  static String fichierDocumentPersonnel(String uuid, {bool download = false}) =>
      '/student/personal-documents/$uuid/file${download ? '?download=1' : ''}';

  static const regenererIdentifiantStagia = '/me.php';
  static const rechercherInscription = '/students/claim/lookup';
  static const verifierInscription = '/students/claim/verify';
  static const creerCompteEtudiant = '/auth/student/register';
  static const ajouterEmail = '/me/login-identifiers/email';
  static const ajouterTelephone = '/me/login-identifiers/phone';
  static String verifierIdentifiant(String id) =>
      '/me/login-identifiers/$id/verify';

  // Référentiel public utilisé pendant l'inscription
  static const universites = '/public/universities';
  static String anneesAcademiques(String universiteId) =>
      '/public/universities/$universiteId/academic-years';
  static String facultes(String universiteId) =>
      '/public/universities/$universiteId/faculties';
  static String promotions(String universiteId) =>
      '/public/universities/$universiteId/promotions';

  // Stages, candidatures et réservations
  static const campagnes = '/campaigns';
  static String opportunites(String campagneId) =>
      '/campaigns/$campagneId/opportunities';
  static const candidatures = '/applications';
  static String reserverPlace(String candidatureId) =>
      '/applications/$candidatureId/reservations';
  static String confirmerReservation(String reservationId) =>
      '/reservations/$reservationId/confirm';
  static String annulerReservation(String reservationId) =>
      '/reservations/$reservationId/cancel';
  static String exigencesFinancieres(String campagneId) =>
      '/campaigns/$campagneId/financial-requirements';
  static const paiements = '/payments';
  static String verifierPaiement(String paiementId) =>
      '/payments/$paiementId/verify';

  // Stage actif, présences et activités
  static String feuillePresence(String affectationId) =>
      '/assignments/$affectationId/attendance-sheet';
  static String justifierAbsence(String presenceId) =>
      '/attendance/$presenceId/justification';
  static String ajouterActivite(String stageId) =>
      '/internships/$stageId/activities';
  static const referentielEvaluation = '/evaluation-frameworks/current';

  // Médias et documents
  static const medias = '/media';
  static String media(String mediaId) => '/media/$mediaId';
  static String versionsMedia(String mediaId) => '/media/$mediaId/versions';
  static String lierMedia(String mediaId) => '/media/$mediaId/links';
  static String archiverMedia(String mediaId) => '/media/$mediaId/archive';
  static String urlTelechargement(String mediaId) =>
      '/media/$mediaId/download-url';

  // Accueil
  static const tableauDeBord = '/analytics/overview';

  // Notifications (Tâche 8)
  static const notificationsEtudiant = '/student/notifications';
  static const notificationsCounts = '/student/notifications/counts';
  static String marquerNotificationLue(String uuid) =>
      '/student/notifications/$uuid/read';
  static String archiverNotification(String uuid) =>
      '/student/notifications/$uuid/archive';
  static const notificationsStream = '/student/notifications/stream';
  static const notificationsPreferences = '/student/notifications/preferences';
  static const notificationsDevices = '/student/notifications/devices';
  static String supprimerNotificationDevice(String uuid) =>
      '/student/notifications/devices/$uuid';

  // Messagerie et contacts (Tâche 8)
  static const communicationContacts = '/student/communication/contacts';
  static const conversations = '/student/conversations';
  static String conversationMessages(String uuid) =>
      '/student/conversations/$uuid/messages';
  static String marquerMessagesConversationLus(String uuid) =>
      '/student/conversations/$uuid/messages/read';
  static String conversationBrouillon(String uuid) =>
      '/student/conversations/$uuid/draft';
  static String pieceJointeMessage(
    String conversationUuid,
    String messageUuid,
    String fileUuid, {
    bool download = false,
  }) =>
      '/student/conversations/$conversationUuid/messages/$messageUuid/attachments/$fileUuid${download ? '?download=1' : ''}';

  // Communications officielles (Tâche 8)
  static const communicationsOfficielles = '/student/communications';
  static String marquerCommunicationLue(String uuid) =>
      '/student/communications/$uuid/read';

  // Calendrier (Tâche 8)
  static const calendrierEtudiant = '/student/calendar';
  static String repondreInvitationCalendrier(String uuid) =>
      '/student/calendar/$uuid/response';
}

