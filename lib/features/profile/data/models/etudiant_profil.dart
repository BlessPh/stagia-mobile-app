class EtudiantProfil {
  const EtudiantProfil({
    required this.nomComplet,
    required this.sexe,
    required this.dateNaissance,
    required this.lieuNaissance,
    required this.adresse,
    required this.telephone,
    required this.email,
    required this.etablissement,
    required this.faculte,
    required this.filiere,
    required this.option,
    required this.niveau,
    required this.anneeAcademique,
    required this.matricule,
  });

  factory EtudiantProfil.vide() => const EtudiantProfil(
    nomComplet: '',
    sexe: '',
    dateNaissance: '',
    lieuNaissance: '',
    adresse: '',
    telephone: '',
    email: '',
    etablissement: '',
    faculte: '',
    filiere: '',
    option: '',
    niveau: '',
    anneeAcademique: '',
    matricule: '',
  );

  factory EtudiantProfil.fromApi(Map<String, dynamic> data) {
    final user = _map(data['user']);
    final student = _map(data['student']);
    final noms = [
      student['nom'],
      student['postnom'],
      student['prenom'],
    ].where((e) => e != null && e.toString().trim().isNotEmpty).join(' ');
    return EtudiantProfil(
      nomComplet: noms,
      sexe: student['sexe']?.toString() ?? '',
      dateNaissance: student['date_naissance']?.toString() ?? '',
      lieuNaissance:
          student['lieu_naissance']?.toString() ??
          student['ville_naissance']?.toString() ??
          '',
      adresse: student['adresse']?.toString() ?? '',
      telephone: student['telephone']?.toString() ?? '',
      email: user['email']?.toString() ?? student['email']?.toString() ?? '',
      etablissement: student['university_name']?.toString() ?? '',
      faculte: student['faculty_name']?.toString() ?? '',
      filiere: student['department_name']?.toString() ?? '',
      option: student['option_name']?.toString() ?? '',
      niveau: student['promotion_name']?.toString() ?? '',
      anneeAcademique: student['academic_year']?.toString() ?? '',
      matricule:
          student['matricule']?.toString() ??
          student['stagia_code']?.toString() ??
          user['matricule']?.toString() ??
          user['identifiant']?.toString() ??
          '',
    );
  }

  final String nomComplet;
  final String sexe;
  final String dateNaissance;
  final String lieuNaissance;
  final String adresse;
  final String telephone;
  final String email;
  final String etablissement;
  final String faculte;
  final String filiere;
  final String option;
  final String niveau;
  final String anneeAcademique;
  final String matricule;

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
    String? nomComplet,
    String? sexe,
    String? dateNaissance,
    String? lieuNaissance,
    String? adresse,
    String? telephone,
    String? email,
    String? etablissement,
    String? faculte,
    String? filiere,
    String? option,
    String? niveau,
    String? anneeAcademique,
    String? matricule,
  }) => EtudiantProfil(
    nomComplet: nomComplet ?? this.nomComplet,
    sexe: sexe ?? this.sexe,
    dateNaissance: dateNaissance ?? this.dateNaissance,
    lieuNaissance: lieuNaissance ?? this.lieuNaissance,
    adresse: adresse ?? this.adresse,
    telephone: telephone ?? this.telephone,
    email: email ?? this.email,
    etablissement: etablissement ?? this.etablissement,
    faculte: faculte ?? this.faculte,
    filiere: filiere ?? this.filiere,
    option: option ?? this.option,
    niveau: niveau ?? this.niveau,
    anneeAcademique: anneeAcademique ?? this.anneeAcademique,
    matricule: matricule ?? this.matricule,
  );
}

Map<String, dynamic> _map(Object? valeur) =>
    valeur is Map ? Map<String, dynamic>.from(valeur) : <String, dynamic>{};
