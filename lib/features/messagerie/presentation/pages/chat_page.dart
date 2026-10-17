import 'dart:async';
import 'package:emoji_picker_flutter/emoji_picker_flutter.dart' as emoji_picker;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/widgets/contenu_adaptatif.dart';
import '../../../../core/network/client_api_http.dart';
import '../../../../core/network/source_etudiant_distante.dart';
import '../../../../core/services/sse_notifications_service.dart';
import '../../domain/entities/discussion.dart';
import '../../domain/entities/message_chat.dart';
import '../widgets/avatar_discussion.dart';
import '../widgets/barre_saisie_chat.dart';
import '../widgets/bulle_message.dart';
import '../widgets/feuille_pieces_jointes.dart';

class ChatPage extends StatefulWidget {
  const ChatPage({
    required this.discussion,
    super.key,
  });

  final Discussion discussion;

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final _source = SourceEtudiantDistante(ClientApiHttp());
  final TextEditingController _controleurTexte = TextEditingController();
  final ScrollController _controleurDefilement = ScrollController();
  final FocusNode _focusNode = FocusNode();

  List<MessageChat> _messages = [];
  MessageChat? _messageEnReponse;
  bool _chargementLotPrecedent = false;
  bool _aDesLotsAnciens = true;
  bool _chargementInitial = true;
  bool _afficherEmojis = false;
  StreamSubscription? _sseSubscription;

  @override
  void initState() {
    super.initState();
    _chargerMessages();
    _controleurDefilement.addListener(_surDefilement);

    // Écoute SSE pour réception des messages en direct
    _sseSubscription = SseNotificationsService.instance.fluxMessages.listen((msgMap) {
      final convTarget = msgMap['action']?['target_id']?.toString() ??
          msgMap['conversation_uuid']?.toString();
      if (convTarget == null || convTarget == widget.discussion.id) {
        final messageItem = MessageChat.fromJson(msgMap);
        if (mounted && !_messages.any((m) => m.id == messageItem.id)) {
          setState(() {
            _messages.add(messageItem);
          });
          _defilerVersBas();
        }
      }
    });

    _focusNode.addListener(() {
      if (_focusNode.hasFocus && _afficherEmojis) {
        setState(() => _afficherEmojis = false);
      }
    });
  }


  Future<void> _chargerMessages() async {
    setState(() => _chargementInitial = true);
    try {
      final res = await _source.messagesConversation(widget.discussion.id);
      final items = (res['items'] as List?)
              ?.whereType<Map>()
              .map((m) => MessageChat.fromJson(Map<String, dynamic>.from(m)))
              .toList() ??
          <MessageChat>[];
      if (mounted) {
        setState(() {
          _messages = items;
          _chargementInitial = false;
        });
        _defilerVersBas();
      }
    } catch (_) {
      if (mounted) {
        setState(() => _chargementInitial = false);
      }
    }
  }

  @override
  void dispose() {
    _sseSubscription?.cancel();
    _controleurTexte.dispose();
    _controleurDefilement.removeListener(_surDefilement);
    _controleurDefilement.dispose();
    _focusNode.dispose();
    super.dispose();
  }


  void _surDefilement() {
    // Si on arrive vers le haut de la liste (messages plus anciens)
    if (_controleurDefilement.position.pixels >=
            _controleurDefilement.position.maxScrollExtent - 40 &&
        !_chargementLotPrecedent &&
        _aDesLotsAnciens) {
      _chargerLotPrecedent();
    }
  }

  Future<void> _chargerLotPrecedent() async {
    setState(() => _chargementLotPrecedent = true);
    await Future<void>.delayed(const Duration(milliseconds: 600));
    if (!mounted) return;

    setState(() {
      _chargementLotPrecedent = false;
      _aDesLotsAnciens = false;
    });
  }

  Future<void> _envoyerMessage(String texte) async {
    if (texte.trim().isEmpty) return;

    final texteEnvoye = texte.trim();
    final messageId = 'm_${DateTime.now().millisecondsSinceEpoch}';
    final nouveauMessage = MessageChat(
      id: messageId,
      texte: texteEnvoye,
      date: DateTime.now(),
      estMien: true,
      expediteurNom: 'Moi',
      reponseA: _messageEnReponse,
      statut: StatutMessage.enCours,
    );

    setState(() {
      _messages.add(nouveauMessage);
      _messageEnReponse = null;
    });
    _defilerVersBas();

    try {
      await _source.envoyerMessageConversation(
        widget.discussion.id,
        contenu: texteEnvoye,
      );
      if (mounted) {
        setState(() {
          final idx = _messages.indexWhere((m) => m.id == messageId);
          if (idx != -1) {
            _messages[idx] = _messages[idx].copyWith(statut: StatutMessage.envoye);
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          final idx = _messages.indexWhere((m) => m.id == messageId);
          if (idx != -1) {
            _messages[idx] = _messages[idx].copyWith(statut: StatutMessage.envoye);
          }
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur d\'envoi : $e'),
            backgroundColor: const Color(0xFFEF4444),
          ),
        );
      }
    }
  }

  Future<void> _envoyerMessageVocal(Duration duree) async {
    final messageId = 'm_voc_${DateTime.now().millisecondsSinceEpoch}';
    final minutes = (duree.inSeconds ~/ 60).toString().padLeft(2, '0');
    final secondes = (duree.inSeconds % 60).toString().padLeft(2, '0');
    final messageVocal = MessageChat(
      id: messageId,
      texte: '🎤 Message vocal ($minutes:$secondes)',
      date: DateTime.now(),
      estMien: true,
      expediteurNom: 'Moi',
      type: TypeMessage.vocal,
      dureeVocal: duree,
      reponseA: _messageEnReponse,
      statut: StatutMessage.enCours,
    );

    setState(() {
      _messages.add(messageVocal);
      _messageEnReponse = null;
    });
    _defilerVersBas();

    try {
      await _source.envoyerMessageConversation(
        widget.discussion.id,
        contenu: '🎤 Message vocal ($minutes:$secondes)',
      );
      if (mounted) {
        setState(() {
          final idx = _messages.indexWhere((m) => m.id == messageId);
          if (idx != -1) {
            _messages[idx] = _messages[idx].copyWith(statut: StatutMessage.envoye);
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          final idx = _messages.indexWhere((m) => m.id == messageId);
          if (idx != -1) {
            _messages[idx] = _messages[idx].copyWith(statut: StatutMessage.envoye);
          }
        });
      }
    }
  }

  void _basculerEmojis() {
    if (_afficherEmojis) {
      setState(() => _afficherEmojis = false);
      _focusNode.requestFocus();
    } else {
      _focusNode.unfocus();
      setState(() => _afficherEmojis = true);
    }
  }


  void _envoyerPieceJointe(OptionPieceJointe option) {
    String nomFichier = 'Document_medical.pdf';
    String taille = '840 Ko';
    TypeMessage type = TypeMessage.document;

    switch (option) {
      case OptionPieceJointe.document:
        nomFichier = 'Compte_Rendu_Clinique.pdf';
        taille = '1.1 Mo';
        type = TypeMessage.document;
      case OptionPieceJointe.camera:
      case OptionPieceJointe.galerie:
        nomFichier = 'Photo_Radio_Thorax.jpg';
        taille = '2.4 Mo';
        type = TypeMessage.document;
      case OptionPieceJointe.ficheStage:
        nomFichier = 'Fiche_Validation_Service.pdf';
        taille = '520 Ko';
        type = TypeMessage.document;
    }

    final nouveauMessage = MessageChat(
      id: 'm_pj_${DateTime.now().millisecondsSinceEpoch}',
      texte: nomFichier,
      date: DateTime.now(),
      estMien: true,
      expediteurNom: 'Moi',
      type: type,
      nomFichier: nomFichier,
      tailleFichier: taille,
      reponseA: _messageEnReponse,
      statut: StatutMessage.envoye,
    );

    setState(() {
      _messages.add(nouveauMessage);
      _messageEnReponse = null;
    });

    _defilerVersBas();
  }

  void _defilerVersBas() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_controleurDefilement.hasClients) {
        _controleurDefilement.animateTo(
          _controleurDefilement.position.minScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _definirReponse(MessageChat message) {
    setState(() => _messageEnReponse = message);
    _focusNode.requestFocus();
  }

  void _ouvrirFeuillePiecesJointes() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => FeuillePiecesJointes(
        onOptionChoisie: _envoyerPieceJointe,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final modeSombre = Theme.of(context).brightness == Brightness.dark;
    final fondPage = modeSombre ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC);

    return Scaffold(
      backgroundColor: fondPage,
      appBar: _construireAppBar(context, modeSombre, fondPage),
      body: ContenuAdaptatif(
        largeurMaximale: 820,
        enfant: Column(
          children: [
            // Indicateur de chargement par lot vers le haut
            if (_chargementLotPrecedent)
              Container(
                padding: const EdgeInsets.symmetric(vertical: 8),
                alignment: Alignment.center,
                child: const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Color(0xFFFF751F),
                  ),
                ),
              ),

            // Liste des messages (inversée pour une UX de chat moderne)
            Expanded(
              child: _chargementInitial
                  ? const Center(
                      child: CircularProgressIndicator(color: Color(0xFF1D61F2)),
                    )
                  : ListView.builder(
                      controller: _controleurDefilement,
                      reverse: true,
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                      itemCount: _messages.length,
                      itemBuilder: (context, index) {
                  // Vue inversée : dernier message = index 0
                  final messageIndex = _messages.length - 1 - index;
                  final message = _messages[messageIndex];

                  // Séparateur de date si changement de jour
                  final afficherDate = index == _messages.length - 1 ||
                      !_memeJour(
                        message.date,
                        _messages[_messages.length - 2 - index + 1].date,
                      );

                  return Column(
                    children: [
                      if (afficherDate) _SeparateurDate(date: message.date),
                      BulleMessage(
                        message: message,
                        onRepondre: () => _definirReponse(message),
                        afficherNomExpediteur: widget.discussion.estGroupe,
                      ),
                    ],
                  );
                },
              ),
            ),

            // Barre de saisie
            BarreSaisieChat(
              controleur: _controleurTexte,
              focusNode: _focusNode,
              messageEnReponse: _messageEnReponse,
              afficherEmojis: _afficherEmojis,
              onAnnulerReponse: () => setState(() => _messageEnReponse = null),
              onEnvoyerTexte: _envoyerMessage,
              onEnvoyerVocal: _envoyerMessageVocal,
              onOuvrirPiecesJointes: _ouvrirFeuillePiecesJointes,
              onBasculerEmojis: _basculerEmojis,
            ),

            // Sélecteur d'émojis
            if (_afficherEmojis)
              SizedBox(
                height: 270,
                child: emoji_picker.EmojiPicker(
                  textEditingController: _controleurTexte,
                  config: emoji_picker.Config(
                    height: 270,
                    checkPlatformCompatibility: false,
                    emojiViewConfig: emoji_picker.EmojiViewConfig(
                      backgroundColor: modeSombre ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
                      columns: 7,
                      emojiSizeMax: 30,
                    ),
                    categoryViewConfig: emoji_picker.CategoryViewConfig(
                      backgroundColor: modeSombre ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
                      indicatorColor: const Color(0xFFFF751F),
                      iconColor: modeSombre ? const Color(0xFFCBD5E1) : const Color(0xFF64748B),
                      iconColorSelected: const Color(0xFFFF751F),
                      backspaceColor: const Color(0xFFFF751F),
                    ),
                    bottomActionBarConfig: emoji_picker.BottomActionBarConfig(
                      backgroundColor: modeSombre ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
                      buttonColor: modeSombre ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
                      buttonIconColor: modeSombre ? const Color(0xFFCBD5E1) : const Color(0xFF64748B),
                    ),
                    searchViewConfig: emoji_picker.SearchViewConfig(
                      backgroundColor: modeSombre ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
                      buttonIconColor: modeSombre ? const Color(0xFFCBD5E1) : const Color(0xFF64748B),
                      hintText: 'Rechercher un émoji...',
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  bool _memeJour(DateTime d1, DateTime d2) {
    return d1.year == d2.year && d1.month == d2.month && d1.day == d2.day;
  }

  PreferredSizeWidget _construireAppBar(
    BuildContext context,
    bool modeSombre,
    Color fondPage,
  ) {
    final iconeCouleur = modeSombre ? const Color(0xFFCBD5E1) : const Color(0xFF0F172A);

    return AppBar(
      elevation: 0,
      backgroundColor: fondPage,
      surfaceTintColor: Colors.transparent,
      leading: IconButton(
        icon: Icon(
          Icons.arrow_back_ios_new_rounded,
          size: 20,
          color: iconeCouleur,
        ),
        onPressed: () => Navigator.pop(context),
      ),
      titleSpacing: 0,
      title: Row(
        children: [
          AvatarDiscussion(
            nom: widget.discussion.nom,
            estEnLigne: widget.discussion.estEnLigne,
            estGroupe: widget.discussion.estGroupe,
            estDiffusion: widget.discussion.estDiffusion,
            rayon: 19,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  widget.discussion.nom,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    fontSize: 15.5,
                    fontWeight: FontWeight.w800,
                    color: modeSombre ? Colors.white : const Color(0xFF0F172A),
                    letterSpacing: -0.2,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  widget.discussion.estEnLigne
                      ? 'En ligne'
                      : widget.discussion.roleOuService,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: widget.discussion.estEnLigne
                        ? const Color(0xFF10B981)
                        : const Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        IconButton(
          tooltip: 'Appel vocal',
          icon: const Icon(
            Icons.phone_outlined,
            size: 22,
            color: Color(0xFF1D61F2),
          ),
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Appel d’urgence vers l’encadreur en préparation.'),
                duration: Duration(seconds: 2),
              ),
            );
          },
        ),
        IconButton(
          tooltip: 'Options',
          icon: Icon(
            Icons.more_vert_rounded,
            size: 22,
            color: modeSombre ? Colors.white : const Color(0xFF64748B),
          ),
          onPressed: () {},
        ),
        const SizedBox(width: 4),
      ],
    );
  }
}

class _SeparateurDate extends StatelessWidget {
  const _SeparateurDate({required this.date});

  final DateTime date;

  @override
  Widget build(BuildContext context) {
    final modeSombre = Theme.of(context).brightness == Brightness.dark;
    final difference = DateTime.now().difference(date);
    String texte;
    if (difference.inDays == 0) {
      texte = "Aujourd'hui";
    } else if (difference.inDays == 1) {
      texte = 'Hier';
    } else {
      texte = '${date.day}/${date.month}/${date.year}';
    }

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 12),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: modeSombre
            ? const Color(0xFF1E293B)
            : const Color(0xFFE2E8F0).withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        texte,
        style: GoogleFonts.inter(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: modeSombre ? const Color(0xFF94A3B8) : const Color(0xFF475569),
        ),
      ),
    );
  }
}
