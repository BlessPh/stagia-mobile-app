import 'package:flutter/material.dart';
import '../../domain/entities/tache_planning.dart';

class SourcePlanningMock {
  static final List<TachePlanning> _taches = [
    // 16 Septembre 2026 (Exemple fourni par l'utilisateur)
    TachePlanning(
      id: 'plan-16-1',
      titre: 'Effectuer une lectomie',
      date: DateTime(2026, 9, 16),
      heureDebut: '10:00',
      heureFin: '10:30',
      type: 'Chirurgie',
      service: 'Chirurgie',
      departement: 'Soins intensifs',
      superviseur: 'Ngoy Jean',
      lieu: 'Bloc opératoire B, Aile Chirurgicale',
      description:
          'Consignes de stérilisation, préparation du champ opératoire et assistance directe sous la supervision de Ngoy Jean.',
      noteRappel:
          'Vérifier le dossier médical préopératoire, s\'assurer du bilan d\'hémostase et revêtir la tenue stérile 15 minutes avant le début de l\'acte.',
      statut: 'À venir',
      couleur: const Color(0xFF2563EB),
    ),
    TachePlanning(
      id: 'plan-16-2',
      titre: 'Visite des patients post-opératoires',
      date: DateTime(2026, 9, 16),
      heureDebut: '14:00',
      heureFin: '15:30',
      type: 'Stage',
      service: 'Chirurgie',
      departement: 'Soins intensifs',
      superviseur: 'Ngoy Jean',
      lieu: 'Aile Ouest - Chambres 201-210',
      description:
          'Contrôle des pansements, relevé des constantes vitales et vérification des drainages.',
      noteRappel:
          'Consigner les constantes sur la fiche de transmission et avertir immédiatement le médecin référent en cas d\'anomalie.',
      statut: 'À venir',
      couleur: const Color(0xFF10B981),
    ),

    // 10 Septembre 2026 (Image de référence exacte)
    TachePlanning(
      id: 'plan-10-1',
      titre: 'Cours de Mathématiques',
      date: DateTime(2026, 9, 10),
      heureDebut: '09:00',
      heureFin: '10:30',
      type: 'Cours',
      service: 'Académique',
      departement: 'Bâtiment Principal',
      superviseur: 'Prof. Mukendi',
      lieu: 'Salle B204, Bâtiment Principal',
      description:
          'Introduction aux équations différentielles du premier ordre. Nous aborderons les méthodes de résolution fondamentales et réaliserons plusieurs cas d\'études appliqués à la physique.',
      noteRappel:
          'N\'oubliez pas d\'apporter le polycopié de cours imprimé et d\'avoir complété l\'exercice préparatoire du chapitre 3.',
      statut: 'À venir',
      couleur: const Color(0xFF3B82F6),
    ),
    TachePlanning(
      id: 'plan-10-2',
      titre: 'Réunion groupe projet',
      date: DateTime(2026, 9, 10),
      heureDebut: '11:00',
      heureFin: '12:30',
      type: 'Projet',
      service: 'Pédagogique',
      departement: 'Projets d\'étudiants',
      superviseur: 'Coord. Kabila',
      lieu: 'Espace Cowork',
      description: 'Point d\'étape sur le mémoire de fin de premier cycle.',
      noteRappel:
          'Préparer les diapositives de synthèse de la revue de littérature.',
      statut: 'À venir',
      couleur: const Color(0xFFF97316),
    ),
    TachePlanning(
      id: 'plan-10-3',
      titre: 'Révision Physique',
      date: DateTime(2026, 9, 10),
      heureDebut: '14:00',
      heureFin: '16:00',
      type: 'Examen',
      service: 'Académique',
      departement: 'Sciences biomédicales',
      superviseur: 'Dr. Ilunga',
      lieu: 'Bibliothèque',
      description:
          'Préparation à l\'évaluation certificative d\'imagerie médicale.',
      noteRappel: 'Apporter la calculatrice scientifique autorisée.',
      statut: 'À venir',
      couleur: const Color(0xFF2563EB),
    ),
    TachePlanning(
      id: 'plan-10-4',
      titre: 'Rapport de Stage',
      date: DateTime(2026, 9, 10),
      heureDebut: '17:00',
      heureFin: '18:30',
      type: 'Stage',
      service: 'Chirurgie',
      departement: 'Soins intensifs',
      superviseur: 'Ngoy Jean',
      lieu: 'Travail perso',
      description:
          'Saisie des observations cliniques et synthèse des activités du jour.',
      statut: 'À venir',
      couleur: const Color(0xFF10B981),
    ),

    // 11 Septembre 2026
    TachePlanning(
      id: 'plan-11-1',
      titre: 'Garde aux Urgences',
      date: DateTime(2026, 9, 11),
      heureDebut: '08:00',
      heureFin: '14:00',
      type: 'Garde',
      service: 'Urgences',
      departement: 'Urgences & Réanimation',
      superviseur: 'Dr. Kalala',
      lieu: 'Box de déchoquage',
      description: 'Prise en charge initiale des urgences traumatiques.',
      statut: 'À venir',
      couleur: const Color(0xFFEF4444),
    ),

    // 14 Septembre 2026
    TachePlanning(
      id: 'plan-14-1',
      titre: 'Tour de salle pédiatrique',
      date: DateTime(2026, 9, 14),
      heureDebut: '08:30',
      heureFin: '11:00',
      type: 'Stage',
      service: 'Pédiatrie',
      departement: 'Néonatologie',
      superviseur: 'Dr. Mwamba',
      lieu: 'Pavillon 4',
      description:
          'Suivi pondéral et administration des traitements spécifiques.',
      statut: 'À venir',
      couleur: const Color(0xFF8B5CF6),
    ),

    // 18 Septembre 2026
    TachePlanning(
      id: 'plan-18-1',
      titre: 'Staff médico-chirurgical hebdomadaire',
      date: DateTime(2026, 9, 18),
      heureDebut: '09:00',
      heureFin: '11:30',
      type: 'Réunion',
      service: 'Chirurgie',
      departement: 'Staff collégial',
      superviseur: 'Prof. Masiala',
      lieu: 'Amphithéâtre 1',
      description:
          'Présentation des cas complexes et discussion pluridisciplinaire.',
      statut: 'À venir',
      couleur: const Color(0xFFF59E0B),
    ),

    // 21 Septembre 2026
    TachePlanning(
      id: 'plan-21-1',
      titre: 'Pose de cathéters et perfusions',
      date: DateTime(2026, 9, 21),
      heureDebut: '10:00',
      heureFin: '12:00',
      type: 'Stage',
      service: 'Soins infirmiers',
      departement: 'Soins intensifs',
      superviseur: 'Inf. Major Lucie',
      lieu: 'Unité de soins 2',
      description:
          'Validation des compétences techniques de pose de voies veineuses.',
      statut: 'À venir',
      couleur: const Color(0xFF10B981),
    ),

    // 25 Septembre 2026
    TachePlanning(
      id: 'plan-25-1',
      titre: 'Évaluation formative clinique',
      date: DateTime(2026, 9, 25),
      heureDebut: '14:00',
      heureFin: '16:30',
      type: 'Évaluation',
      service: 'Chirurgie',
      departement: 'Soins intensifs',
      superviseur: 'Ngoy Jean',
      lieu: 'Salle de simulation',
      description:
          'Évaluation de mi-parcours sur les gestes d\'urgence.',
      statut: 'À venir',
      couleur: const Color(0xFF2563EB),
    ),
  ];

  static List<TachePlanning> toutesLesTaches() => List.unmodifiable(_taches);

  static List<TachePlanning> obtenirTachesPourDate(DateTime date) {
    return _taches.where((t) {
      return t.date.year == date.year &&
          t.date.month == date.month &&
          t.date.day == date.day;
    }).toList();
  }

  static bool dateContientTaches(DateTime date) {
    return _taches.any((t) {
      return t.date.year == date.year &&
          t.date.month == date.month &&
          t.date.day == date.day;
    });
  }

  static void ajouterTache(TachePlanning tache) {
    _taches.add(tache);
  }

  static void mettreAJourTache(TachePlanning tacheModifiee) {
    final index = _taches.indexWhere((t) => t.id == tacheModifiee.id);
    if (index != -1) {
      _taches[index] = tacheModifiee;
    }
  }

  static void supprimerTache(String id) {
    _taches.removeWhere((t) => t.id == id);
  }
}
