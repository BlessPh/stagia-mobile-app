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

  factory MessageChat.fromJson(Map<String, dynamic> json) {
    final attachments = json['attachments'] is List ? json['attachments'] as List : const [];
    TypeMessage type = TypeMessage.texte;
    String? nomFichier;
    String? tailleFichier;

    if (attachments.isNotEmpty) {
      final firstAtt = attachments.first as Map<String, dynamic>;
      nomFichier = firstAtt['name']?.toString();
      final sizeBytes = int.tryParse(firstAtt['size']?.toString() ?? '0') ?? 0;
      if (sizeBytes > 1024 * 1024) {
        tailleFichier = '${(sizeBytes / (1024 * 1024)).toStringAsFixed(1)} Mo';
      } else if (sizeBytes > 0) {
        tailleFichier = '${(sizeBytes / 1024).toStringAsFixed(0)} Ko';
      }
      final mime = firstAtt['mime_type']?.toString().toLowerCase() ?? '';
      if (mime.startsWith('image/')) {
        type = TypeMessage.image;
      } else {
        type = TypeMessage.document;
      }
    }

    DateTime parsedDate;
    try {
      parsedDate = DateTime.parse(json['cree_le']?.toString() ?? '');
    } catch (_) {
      parsedDate = DateTime.now();
    }

    final readCount = int.tryParse(json['read_by_count']?.toString() ?? '0') ?? 0;

    return MessageChat(
      id: json['uuid']?.toString() ?? json['id']?.toString() ?? '',
      texte: json['contenu']?.toString() ?? '',
      date: parsedDate,
      estMien: json['is_mine'] == true,
      expediteurNom: json['author']?.toString() ?? (json['is_mine'] == true ? 'Moi' : 'Interlocuteur'),
      type: type,
      nomFichier: nomFichier,
      tailleFichier: tailleFichier,
      statut: readCount > 0 ? StatutMessage.lu : StatutMessage.envoye,
    );
  }
}

