class EtudiantProfil {
  const EtudiantProfil({
    required this.studentId,
    required this.stagiaCode,
    required this.nom,
    required this.postnom,
    required this.prenom,
    required this.nomComplet,
    required this.sexe,
    required this.dateNaissance,
    required this.adresse,
    required this.ville,
    required this.province,
    required this.telephone,
    required this.email,
    required this.etablissement,
    required this.faculte,
    required this.filiere,
    required this.option,
    required this.niveau,
    required this.anneeAcademique,
    required this.matricule,
    required this.avatarUrl,
  });

  factory EtudiantProfil.vide() => const EtudiantProfil(
    studentId: '',
    stagiaCode: '',
    nom: '',
    postnom: '',
    prenom: '',
    nomComplet: '',
    sexe: '',
    dateNaissance: '',
    adresse: '',
    ville: '',
    province: '',
    telephone: '',
    email: '',
    etablissement: '',
    faculte: '',
    filiere: '',
    option: '',
    niveau: '',
    anneeAcademique: '',
    matricule: '',
    avatarUrl: '',
  );

  factory EtudiantProfil.fromApi(Map<String, dynamic> data) {
    final user = _map(data['user']);
    final student = _map(data['student']);
    final academic = _map(data['current_academic']);
    String valeur(String cle) =>
        student[cle]?.toString().trim().isNotEmpty == true
        ? student[cle].toString().trim()
        : user[cle]?.toString().trim() ?? '';
    final nom = valeur('nom');
    final postnom = valeur('postnom');
    final prenom = valeur('prenom');
    final noms = [nom, postnom, prenom].where((e) => e.isNotEmpty).join(' ');
    return EtudiantProfil(
      studentId: student['id']?.toString() ?? '',
      stagiaCode:
          student['stagia_code']?.toString() ??
          user['identifiant']?.toString() ??
          '',
      nom: nom,
      postnom: postnom,
      prenom: prenom,
      nomComplet: noms,
      sexe: valeur('sexe'),
      dateNaissance: valeur('date_naissance'),
      adresse: valeur('adresse'),
      ville: valeur('ville'),
      province: valeur('province'),
      telephone: valeur('telephone'),
      email: user['email']?.toString() ?? student['email']?.toString() ?? '',
      etablissement:
          academic['university_name']?.toString() ??
          student['university_name']?.toString() ??
          '',
      faculte:
          academic['faculty']?.toString() ??
          student['faculty_name']?.toString() ??
          '',
      filiere:
          academic['department']?.toString() ??
          student['department_name']?.toString() ??
          '',
      option:
          academic['program']?.toString() ??
          student['option_name']?.toString() ??
          '',
      niveau:
          academic['promotion']?.toString() ??
          student['promotion_name']?.toString() ??
          '',
      anneeAcademique:
          academic['academic_year']?.toString() ??
          student['academic_year']?.toString() ??
          '',
      matricule:
          student['matricule']?.toString() ??
          user['matricule']?.toString() ??
          student['stagia_code']?.toString() ??
          user['identifiant']?.toString() ??
          '',
      avatarUrl: valeur('avatar_url'),
    );
  }

  final String studentId;
  final String stagiaCode;
  final String nom;
  final String postnom;
  final String prenom;
  final String nomComplet;
  final String sexe;
  final String dateNaissance;
  final String adresse;
  final String ville;
  final String province;
  final String telephone;
  final String email;
  final String etablissement;
  final String faculte;
  final String filiere;
  final String option;
  final String niveau;
  final String anneeAcademique;
  final String matricule;
  final String avatarUrl;

  String get initiales {
    final parties = nomComplet
        .trim()
        .split(RegExp(r'\s+'))
        .where((e) => e.isNotEmpty)
        .toList();
    if (parties.isEmpty) return 'ET';
    return parties.take(2).map((e) => e[0]).join().toUpperCase();
  }

  EtudiantProfil copyWith({
    String? studentId,
    String? stagiaCode,
    String? nom,
    String? postnom,
    String? prenom,
    String? nomComplet,
    String? sexe,
    String? dateNaissance,
    String? adresse,
    String? ville,
    String? province,
    String? telephone,
    String? email,
    String? etablissement,
    String? faculte,
    String? filiere,
    String? option,
    String? niveau,
    String? anneeAcademique,
    String? matricule,
    String? avatarUrl,
  }) => EtudiantProfil(
    studentId: studentId ?? this.studentId,
    stagiaCode: stagiaCode ?? this.stagiaCode,
    nom: nom ?? this.nom,
    postnom: postnom ?? this.postnom,
    prenom: prenom ?? this.prenom,
    nomComplet: nomComplet ?? this.nomComplet,
    sexe: sexe ?? this.sexe,
    dateNaissance: dateNaissance ?? this.dateNaissance,
    adresse: adresse ?? this.adresse,
    ville: ville ?? this.ville,
    province: province ?? this.province,
    telephone: telephone ?? this.telephone,
    email: email ?? this.email,
    etablissement: etablissement ?? this.etablissement,
    faculte: faculte ?? this.faculte,
    filiere: filiere ?? this.filiere,
    option: option ?? this.option,
    niveau: niveau ?? this.niveau,
    anneeAcademique: anneeAcademique ?? this.anneeAcademique,
    matricule: matricule ?? this.matricule,
    avatarUrl: avatarUrl ?? this.avatarUrl,
  );
}

Map<String, dynamic> _map(Object? valeur) =>
    valeur is Map ? Map<String, dynamic>.from(valeur) : <String, dynamic>{};
