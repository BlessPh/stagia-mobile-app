abstract final class EndpointsApi {
  // Authentification et profil (contrat PHP OpenAPI)
  static const connexion = '/auth/login.php';
  static const deconnexion = '/auth/logout.php';
  static const rafraichirToken = '/auth/refresh.php';
  static const profilEtudiant = '/me.php';
  static const motDePasseOublie = '/auth/forgot-password.php';
  static const reinitialiserMotDePasse = '/auth/reset-password.php';

  // Étudiant & Stages (contrat PHP OpenAPI)
  static const tableauDeBordEtudiant = '/student/dashboard.php';
  static const profilActifEtudiant = '/student/profile.php';
  static const rattachementsEtudiant = '/student/enrollments.php';
  static const parcoursAcademiqueEtudiant = '/student/academic-path.php';
  static const optionsStageEtudiant = '/student/stage-options.php';
  static const reserverStage = '/student/reserve.php';
  static const candidaturesEtudiant = '/student/applications.php';
  static const reservationsEtudiant = '/student/reservations.php';
  static const admissionEtudiant = '/student/admission.php';
  static const paiementCheckout = '/student/payment-checkout.php';
  static const paiementSync = '/student/payment-sync.php';
  static const paiementsEtudiant = '/student/payments.php';
  static const stagesEtudiant = '/student/stages.php';
  static const presencesEtudiant = '/student/attendance.php';
  static const journalEtudiant = '/student/logbook.php';
  static const journalEnregistrer = '/student/logbook-save.php';
  static const journalSoumettre = '/student/logbook-submit.php';
  static const evaluationsEtudiant = '/student/evaluations.php';
  static const documentsEtudiant = '/student/documents.php';

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
}
