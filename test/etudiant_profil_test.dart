import 'package:flutter_test/flutter_test.dart';
import 'package:stagia/features/profile/data/models/etudiant_profil.dart';

void main() {
  test(
    'mappe la nouvelle réponse de GET /me sans valeurs de démonstration',
    () {
      final profil = EtudiantProfil.fromApi({
        'user': {
          'id': 55,
          'identifiant': 'STG-ETU-00000030',
          'nom': 'MBIMBU',
          'postnom': 'GEMIMA',
          'prenom': 'Gemima',
          'sexe': 'F',
          'date_naissance': '1993-07-12',
          'adresse': 'RTR',
          'ville': 'KIB',
          'province': 'Maniema',
          'avatar_url': 'https://example.test/avatar.jpg',
          'telephone': null,
          'email': 'nzuzianges53@gmail.com',
          'matricule': 'ISP-ETU-2026-000044',
        },
        'student': {
          'id': 30,
          'stagia_code': 'STG-ETU-00000030',
          'nom': 'MBIMBU',
          'postnom': 'GEMIMA',
          'prenom': 'Gemima',
          'sexe': 'F',
          'date_naissance': '1993-07-12',
          'adresse': 'RTR',
          'ville': 'KIB',
          'province': 'Maniema',
          'avatar_url': null,
          'telephone': null,
          'email': 'nzuzianges53@gmail.com',
          'matricule': 'ISP-ETU-2026-000044',
        },
      });

      expect(profil.studentId, '30');
      expect(profil.stagiaCode, 'STG-ETU-00000030');
      expect(profil.nomComplet, 'MBIMBU GEMIMA Gemima');
      expect(profil.sexe, 'F');
      expect(profil.ville, 'KIB');
      expect(profil.province, 'Maniema');
      expect(profil.telephone, isEmpty);
      expect(profil.email, 'nzuzianges53@gmail.com');
      expect(profil.matricule, 'ISP-ETU-2026-000044');
      expect(profil.avatarUrl, 'https://example.test/avatar.jpg');
    },
  );
}
