enum CategorieDiscussion {
  general,
  diffusion,
  groupes,
  encadreurs,
}

enum StatutMessage {
  envoye,
  distribue,
  lu,
}

class Discussion {
  Discussion({
    required this.id,
    required this.nom,
    required this.roleOuService,
    required this.dernierMessage,
    required this.date,
    required this.categorie,
    this.avatarUrl,
    this.nbNonLus = 0,
    this.estEnLigne = false,
    this.estGroupe = false,
    this.estDiffusion = false,
    this.estEpingle = false,
    this.dernierMessageEstMien = false,
    this.statutMessage = StatutMessage.lu,
  });

  final String id;
  final String nom;
  final String roleOuService;
  final String dernierMessage;
  final DateTime date;
  final CategorieDiscussion categorie;
  final String? avatarUrl;
  int nbNonLus;
  final bool estEnLigne;
  final bool estGroupe;
  final bool estDiffusion;
  final bool estEpingle;
  final bool dernierMessageEstMien;
  final StatutMessage statutMessage;

  String get tempsAffiche {
    final diff = DateTime.now().difference(date);
    if (diff.inMinutes < 60) {
      if (diff.inMinutes < 1) return "À l'instant";
      return '${diff.inMinutes}m';
    } else if (diff.inHours < 24) {
      final minute = date.minute.toString().padLeft(2, '0');
      final heure = date.hour.toString().padLeft(2, '0');
      return '$heure:$minute';
    } else if (diff.inDays == 1) {
      return 'Hier';
    } else {
      return '${date.day}/${date.month}';
    }
  }

  Discussion copyWith({
    String? id,
    String? nom,
    String? roleOuService,
    String? dernierMessage,
    DateTime? date,
    CategorieDiscussion? categorie,
    String? avatarUrl,
    int? nbNonLus,
    bool? estEnLigne,
    bool? estGroupe,
    bool? estDiffusion,
    bool? estEpingle,
    bool? dernierMessageEstMien,
    StatutMessage? statutMessage,
  }) {
    return Discussion(
      id: id ?? this.id,
      nom: nom ?? this.nom,
      roleOuService: roleOuService ?? this.roleOuService,
      dernierMessage: dernierMessage ?? this.dernierMessage,
      date: date ?? this.date,
      categorie: categorie ?? this.categorie,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      nbNonLus: nbNonLus ?? this.nbNonLus,
      estEnLigne: estEnLigne ?? this.estEnLigne,
      estGroupe: estGroupe ?? this.estGroupe,
      estDiffusion: estDiffusion ?? this.estDiffusion,
      estEpingle: estEpingle ?? this.estEpingle,
      dernierMessageEstMien: dernierMessageEstMien ?? this.dernierMessageEstMien,
      statutMessage: statutMessage ?? this.statutMessage,
    );
  }

  factory Discussion.fromJson(Map<String, dynamic> json) {
    final typeConv = json['type_conversation']?.toString().toLowerCase() ?? '';
    final estGrp = typeConv == 'groupe';
    final estDiff = typeConv == 'institutionnelle';

    CategorieDiscussion cat;
    if (estDiff) {
      cat = CategorieDiscussion.diffusion;
    } else if (estGrp) {
      cat = CategorieDiscussion.groupes;
    } else {
      cat = CategorieDiscussion.encadreurs;
    }

    DateTime parsedDate;
    try {
      final dateStr = json['last_activity_at'] ?? json['cree_le'];
      parsedDate = DateTime.parse(dateStr?.toString() ?? '');
    } catch (_) {
      parsedDate = DateTime.now();
    }

    final nbNonLus = int.tryParse(json['unread_count']?.toString() ?? '0') ?? 0;

    return Discussion(
      id: json['uuid']?.toString() ?? json['id']?.toString() ?? '',
      nom: json['objet']?.toString() ?? json['nom']?.toString() ?? 'Discussion',
      roleOuService: estGrp
          ? '${json['participant_count'] ?? 2} participants'
          : (json['role_ou_service']?.toString() ?? 'Encadrement STAGIA'),
      dernierMessage: json['last_message']?.toString() ??
          json['dernier_message']?.toString() ??
          'Nouvelle conversation',
      date: parsedDate,
      categorie: cat,
      avatarUrl: json['avatar_url']?.toString(),
      nbNonLus: nbNonLus,
      estEnLigne: json['est_en_ligne'] == true,
      estGroupe: estGrp,
      estDiffusion: estDiff,
      estEpingle: json['est_epingle'] == true,
      dernierMessageEstMien: json['dernier_message_est_mien'] == true,
      statutMessage: nbNonLus > 0 ? StatutMessage.distribue : StatutMessage.lu,
    );
  }
}

