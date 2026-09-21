import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/widgets/contenu_adaptatif.dart';
import '../../data/datasources/source_messagerie_mock.dart';
import '../../domain/entities/discussion.dart';
import '../widgets/barre_recherche_messagerie.dart';
import '../widgets/element_discussion.dart';
import 'chat_page.dart';

class MessageriePage extends StatefulWidget {
  const MessageriePage({super.key});

  @override
  State<MessageriePage> createState() => _MessageriePageState();
}

class _MessageriePageState extends State<MessageriePage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _controleurRecherche = TextEditingController();
  late List<Discussion> _discussions;
  String _requeteRecherche = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _discussions = SourceMessagerieMock.obtenirDiscussions();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _controleurRecherche.dispose();
    super.dispose();
  }

  int get _totalNonLus {
    return _discussions.fold<int>(0, (total, d) => total + d.nbNonLus);
  }

  List<Discussion> _filtrerDiscussions(int indexOnglet) {
    List<Discussion> resultat = _discussions;

    switch (indexOnglet) {
      case 1:
        resultat = resultat
            .where((d) => d.categorie == CategorieDiscussion.general)
            .toList();
      case 2:
        resultat = resultat
            .where((d) => d.categorie == CategorieDiscussion.diffusion)
            .toList();
      case 3:
        resultat = resultat
            .where((d) => d.categorie == CategorieDiscussion.encadreurs)
            .toList();
      case 4:
        resultat = resultat
            .where((d) => d.categorie == CategorieDiscussion.groupes)
            .toList();
      default:
        break;
    }

    if (_requeteRecherche.trim().isNotEmpty) {
      final req = _requeteRecherche.trim().toLowerCase();
      resultat = resultat.where((d) {
        return d.nom.toLowerCase().contains(req) ||
            d.roleOuService.toLowerCase().contains(req) ||
            d.dernierMessage.toLowerCase().contains(req);
      }).toList();
    }

    return resultat;
  }

  void _ouvrirDiscussion(Discussion discussion) {
    setState(() {
      final index = _discussions.indexWhere((d) => d.id == discussion.id);
      if (index != -1) {
        _discussions[index].nbNonLus = 0;
      }
    });

    Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => ChatPage(discussion: discussion),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final modeSombre = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            size: 20,
            color: modeSombre ? Colors.white : const Color(0xFF0F172A),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            Text(
              'Messagerie',
              style: GoogleFonts.inter(
                fontSize: 20,
                fontWeight: FontWeight.w900,
                color: modeSombre ? Colors.white : const Color(0xFF0F172A),
                letterSpacing: -0.4,
              ),
            ),
            if (_totalNonLus > 0) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFFF7417),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '$_totalNonLus',
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Nouvelle discussion',
            icon: const Icon(
              Icons.edit_square,
              size: 22,
              color: Color(0xFF1D61F2),
            ),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Annuaire médical des encadreurs ouvert.'),
                  duration: Duration(seconds: 2),
                ),
              );
            },
          ),
          const SizedBox(width: 4),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(104),
          child: Column(
            children: [
              // Barre de recherche
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 10),
                child: BarreRechercheMessagerie(
                  controleur: _controleurRecherche,
                  onChanged: (texte) => setState(() => _requeteRecherche = texte),
                  onClear: () => setState(() => _requeteRecherche = ''),
                ),
              ),

              // TabBar des catégories
              TabBar(
                controller: _tabController,
                isScrollable: true,
                tabAlignment: TabAlignment.start,
                indicatorColor: const Color(0xFFFF7417),
                indicatorWeight: 3,
                indicatorSize: TabBarIndicatorSize.label,
                labelColor: const Color(0xFFFF7417),
                unselectedLabelColor: const Color(0xFF64748B),
                labelStyle: GoogleFonts.inter(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                ),
                unselectedLabelStyle: GoogleFonts.inter(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w500,
                ),
                tabs: const [
                  Tab(text: 'Toutes'),
                  Tab(text: 'Général'),
                  Tab(text: 'Diffusions'),
                  Tab(text: 'Encadreurs'),
                  Tab(text: 'Groupes'),
                ],
              ),
            ],
          ),
        ),
      ),
      body: ContenuAdaptatif(
        largeurMaximale: 820,
        enfant: TabBarView(
          controller: _tabController,
          children: List.generate(5, (indexOnglet) {
            final liste = _filtrerDiscussions(indexOnglet);

            if (liste.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 68,
                      height: 68,
                      decoration: BoxDecoration(
                        color: const Color(0xFF1D61F2).withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.chat_bubble_outline_rounded,
                        color: Color(0xFF1D61F2),
                        size: 32,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      _requeteRecherche.isEmpty
                          ? 'Aucune discussion dans cette catégorie'
                          : 'Aucun résultat trouvé pour "$_requeteRecherche"',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              );
            }

            return ListView.separated(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: liste.length,
              separatorBuilder: (_, _) => Divider(
                height: 1,
                indent: 78,
                endIndent: 16,
                color: modeSombre
                    ? const Color(0xFF262626)
                    : const Color(0xFFF1F5F9),
              ),
              itemBuilder: (context, index) {
                final discussion = liste[index];
                return ElementDiscussion(
                  discussion: discussion,
                  onTap: () => _ouvrirDiscussion(discussion),
                );
              },
            );
          }),
        ),
      ),
    );
  }
}
