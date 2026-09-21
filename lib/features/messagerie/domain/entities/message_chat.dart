import 'discussion.dart';

enum TypeMessage {
  texte,
  vocal,
  document,
  image,
}

class MessageChat {
  MessageChat({
    required this.id,
    required this.texte,
    required this.date,
    required this.estMien,
    required this.expediteurNom,
    this.type = TypeMessage.texte,
    this.dureeVocal,
    this.nomFichier,
    this.tailleFichier,
    this.reponseA,
    this.statut = StatutMessage.lu,
  });

  final String id;
  final String texte;
  final DateTime date;
  final bool estMien;
  final String expediteurNom;
  final TypeMessage type;
  final Duration? dureeVocal;
  final String? nomFichier;
  final String? tailleFichier;
  final MessageChat? reponseA;
  final StatutMessage statut;

  String get heureAffichee {
    final heure = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');
    return '$heure:$minute';
  }

  MessageChat copyWith({
    String? id,
    String? texte,
    DateTime? date,
    bool? estMien,
    String? expediteurNom,
    TypeMessage? type,
    Duration? dureeVocal,
    String? nomFichier,
    String? tailleFichier,
    MessageChat? reponseA,
    StatutMessage? statut,
  }) {
    return MessageChat(
      id: id ?? this.id,
      texte: texte ?? this.texte,
      date: date ?? this.date,
      estMien: estMien ?? this.estMien,
      expediteurNom: expediteurNom ?? this.expediteurNom,
      type: type ?? this.type,
      dureeVocal: dureeVocal ?? this.dureeVocal,
      nomFichier: nomFichier ?? this.nomFichier,
      tailleFichier: tailleFichier ?? this.tailleFichier,
      reponseA: reponseA ?? this.reponseA,
      statut: statut ?? this.statut,
    );
  }
}
