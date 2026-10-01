import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/network/client_api_http.dart';
import '../../../../core/network/configuration_api.dart';
import '../../../../core/network/source_etudiant_distante.dart';
import '../../../notifications/presentation/pages/notifications_page.dart';

class MesTachesPage extends StatefulWidget {
  const MesTachesPage({this.assignmentUuid, super.key});

  final String? assignmentUuid;

  @override
  State<MesTachesPage> createState() => _MesTachesPageState();
}

class _MesTachesPageState extends State<MesTachesPage> {
  final _source = SourceEtudiantDistante(ClientApiHttp());
  int _ongletIndex = 0; // 0 = En cours, 1 = Historique
  late Future<Map<String, dynamic>> _chargement;

  @override
  void initState() {
    super.initState();
    _chargement = _charger();
  }

  Future<Map<String, dynamic>> _charger() =>
      _source.taches(assignmentUuid: widget.assignmentUuid);

  Future<void> _actualiser() async {
    final futur = _charger();
    setState(() => _chargement = futur);
    await futur;
  }

  Future<void> _demarrer(String uuid) async {
    try {
      await _source.demarrerTache(uuid);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Tâche démarrée avec succès !')),
        );
      }
      await _actualiser();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: const Color(0xFFDC2626),
          ),
        );
      }
    }
  }

  Future<void> _terminer(String uuid) async {
    final commentCtrl = TextEditingController();
    final valide = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          'Terminer la tâche',
          style: GoogleFonts.inter(fontWeight: FontWeight.w800, fontSize: 17),
        ),
        content: TextField(
          controller: commentCtrl,
          decoration: const InputDecoration(
            labelText: 'Rapport / Commentaire d\'exécution (optionnel)',
            hintText: 'Précisez les gestes ou observations...',
          ),
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Confirmer'),
          ),
        ],
      ),
    );
    if (valide != true) return;

    try {
      await _source.terminerTache(
        uuid,
        commentaire: commentCtrl.text.trim().isNotEmpty
            ? commentCtrl.text.trim()
            : null,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Tâche terminée avec succès !')),
        );
      }
      await _actualiser();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: const Color(0xFFDC2626),
          ),
        );
      }
    }
  }

  final List<Map<String, dynamic>> _tachesEnCours = [
    {
      'priorite': 'HAUTE PRIORITÉ',
      'prioriteBg': const Color(0xFFFFF7ED),
      'prioriteCouleur': const Color(0xFFEA580C),
      'statut': 'EN COURS',
      'statutBg': const Color(0xFFE0F2FE),
      'statutCouleur': const Color(0xFF0284C7),
      'titre': 'Prise des constantes et pansements',
      'echeance': 'Aujourd\'hui, 11:30',
      'action': 'Terminer la tâche',
    },
    {
      'priorite': 'URGENT',
      'prioriteBg': const Color(0xFFFEE2E2),
      'prioriteCouleur': const Color(0xFFDC2626),
      'statut': 'À FAIRE',
      'statutBg': const Color(0xFFFEF3C7),
      'statutCouleur': const Color(0xFFD97706),
      'titre': 'Préparation du champ opératoire Bloc B',
      'echeance': 'Aujourd\'hui, 15:00',
      'action': 'Démarrer',
    },
  ];

  final List<Map<String, dynamic>> _tachesHistorique = [
    {
      'priorite': 'HAUTE PRIORITÉ',
      'prioriteBg': const Color(0xFFFFF7ED),
      'prioriteCouleur': const Color(0xFFEA580C),
      'statut': 'À CORRIGER',
      'statutBg': const Color(0xFFFFF7ED),
      'statutCouleur': const Color(0xFFEA580C),
      'titre': 'Rapport d\'admission - Traumatisme thoracique',
      'retour':
          'À réviser : Compléter la partie description du mécanisme de traumatisme.',
      'infoLigne': 'Échéance : Aujourd\'hui, 14:00',
      'actionLibelle': 'Reprendre la tâche',
    },
    {
      'priorite': 'PROCÉDURE',
      'prioriteBg': const Color(0xFFF3E8FF),
      'prioriteCouleur': const Color(0xFF7E22CE),
      'statut': 'VALIDÉ',
      'statutBg': const Color(0xFFDCFCE7),
      'statutCouleur': const Color(0xFF16A34A),
      'titre': 'Suture et parage de plaie complexe',
      'retour': null,
      'infoLigne': 'Évalué le 12 Jan, 18:00',
      'actionLibelle': 'Consulter',
    },
    {
      'priorite': 'PROCÉDURE',
      'prioriteBg': const Color(0xFFF3E8FF),
      'prioriteCouleur': const Color(0xFF7E22CE),
      'statut': 'SOUMIS',
      'statutBg': const Color(0xFFE0F2FE),
      'statutCouleur': const Color(0xFF0284C7),
      'titre': 'Installation d\'une sonde urinaire à demeure',
      'retour': null,
      'infoLigne': 'Envoyé hier, 16:30',
      'actionLibelle': 'Consulter',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF8FAFC),
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(
            CupertinoIcons.chevron_left,
            color: Color(0xFF0F172A),
            size: 24,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Mes tâches',
          style: GoogleFonts.inter(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: const Color(0xFF0F172A),
          ),
        ),
        actions: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              IconButton(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const NotificationsPage(),
                  ),
                ),
                icon: const Icon(
                  CupertinoIcons.bell,
                  color: Color(0xFF0F172A),
                  size: 25,
                ),
              ),
              if (ConfigurationApi.utiliserDonneesMockees)
                Positioned(
                  top: 8,
                  right: 6,
                  child: Container(
                    padding: const EdgeInsets.all(3),
                    decoration: const BoxDecoration(
                      color: Color(0xFFEF4444),
                      shape: BoxShape.circle,
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 16,
                      minHeight: 16,
                    ),
                    child: const Text(
                      '5',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 9.5,
                        fontWeight: FontWeight.w800,
                        height: 1,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: FutureBuilder<Map<String, dynamic>>(
          future: _chargement,
          builder: (context, snapshot) {
            final data = snapshot.data ?? {};
            final apiItems = (data['items'] as List? ?? [])
                .whereType<Map>()
                .map(Map<String, dynamic>.from)
                .toList();

            final List<Map<String, dynamic>> sourceEnCours;
            final List<Map<String, dynamic>> sourceHistorique;

            if (apiItems.isNotEmpty) {
              sourceEnCours = apiItems
                  .where((t) {
                    final statut = t['statut'] ?? t['status'];
                    return statut == 'A_FAIRE' || statut == 'EN_COURS';
                  })
                  .map(
                    (t) => {
                      'uuid': t['uuid'],
                      'priorite': (t['priorite'] ?? t['priority'] ?? '')
                          .toString()
                          .toUpperCase(),
                      'prioriteBg': const Color(0xFFFFF7ED),
                      'prioriteCouleur': const Color(0xFFEA580C),
                      'statut': (t['statut'] ?? t['status'] ?? '')
                          .toString()
                          .replaceAll('_', ' '),
                      'statutBg': (t['statut'] ?? t['status']) == 'EN_COURS'
                          ? const Color(0xFFE0F2FE)
                          : const Color(0xFFFEF3C7),
                      'statutCouleur':
                          (t['statut'] ?? t['status']) == 'EN_COURS'
                          ? const Color(0xFF0284C7)
                          : const Color(0xFFD97706),
                      'titre': (t['titre'] ?? t['title'])?.toString() ?? '',
                      'echeance':
                          (t['date_echeance'] ?? t['due_date'])?.toString() ??
                          '',
                      'action': (t['statut'] ?? t['status']) == 'EN_COURS'
                          ? 'Terminer la tâche'
                          : 'Démarrer',
                    },
                  )
                  .toList();

              sourceHistorique = apiItems
                  .where((t) {
                    final statut = t['statut'] ?? t['status'];
                    return statut != 'A_FAIRE' && statut != 'EN_COURS';
                  })
                  .map(
                    (t) => {
                      'uuid': t['uuid'],
                      'priorite': (t['priorite'] ?? t['priority'] ?? '')
                          .toString()
                          .toUpperCase(),
                      'prioriteBg': const Color(0xFFF3E8FF),
                      'prioriteCouleur': const Color(0xFF7E22CE),
                      'statut': (t['statut'] ?? t['status'] ?? '')
                          .toString()
                          .replaceAll('_', ' '),
                      'statutBg': const Color(0xFFDCFCE7),
                      'statutCouleur': const Color(0xFF16A34A),
                      'titre': (t['titre'] ?? t['title'])?.toString() ?? '',
                      'retour':
                          t['commentaire_encadreur'] ??
                          t['comment'] ??
                          t['feedback'],
                      'infoLigne':
                          (t['completed_at'] ?? t['updated_at'])?.toString() ??
                          '',
                      'actionLibelle': 'Consulter',
                    },
                  )
                  .toList();
            } else {
              sourceEnCours = ConfigurationApi.utiliserDonneesMockees
                  ? _tachesEnCours
                  : const [];
              sourceHistorique = ConfigurationApi.utiliserDonneesMockees
                  ? _tachesHistorique
                  : const [];
            }

            final listeAffichee = _ongletIndex == 0
                ? sourceEnCours
                : sourceHistorique;

            return RefreshIndicator(
              color: const Color(0xFF1D61F2),
              onRefresh: _actualiser,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 28),
                children: [
                  Row(
                    children: [
                      _buildOngletPill('En cours (${sourceEnCours.length})', 0),
                      const SizedBox(width: 10),
                      _buildOngletPill(
                        'Historique (${sourceHistorique.length})',
                        1,
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  if (listeAffichee.isEmpty)
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.only(top: 40),
                        child: Text(
                          'Aucune tâche dans cette section.',
                          style: GoogleFonts.inter(
                            color: const Color(0xFF94A3B8),
                            fontSize: 14,
                          ),
                        ),
                      ),
                    )
                  else
                    for (final t in listeAffichee)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 14),
                        child: _buildCarteTache(t),
                      ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildOngletPill(String titre, int index) {
    final actif = _ongletIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _ongletIndex = index),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8.5),
        decoration: BoxDecoration(
          color: actif ? const Color(0xFF1D61F2) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: actif ? const Color(0xFF1D61F2) : const Color(0xFFE2E8F0),
          ),
        ),
        child: Text(
          titre,
          style: GoogleFonts.inter(
            fontSize: 13.5,
            fontWeight: actif ? FontWeight.w700 : FontWeight.w500,
            color: actif ? Colors.white : const Color(0xFF64748B),
          ),
        ),
      ),
    );
  }

  Widget _buildCarteTache(Map<String, dynamic> t) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x05000000),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Ligne Badge Priorité + Badge Statut
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                decoration: BoxDecoration(
                  color: t['prioriteBg'] as Color,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  t['priorite'] as String,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: t['prioriteCouleur'] as Color,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                decoration: BoxDecoration(
                  color: t['statutBg'] as Color,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  t['statut'] as String,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: t['statutCouleur'] as Color,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Titre
          Text(
            t['titre'] as String,
            style: GoogleFonts.inter(
              fontSize: 15.5,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF0F172A),
            ),
          ),

          // Bloc Retour de l'encadreur
          if (t['retour'] != null) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF7ED),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFFFEDD5)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Retour de l\'encadreur :',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFFEA580C),
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    t['retour'] as String,
                    style: GoogleFonts.inter(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF0F172A),
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 12),
          const Divider(height: 1, color: Color(0xFFF1F5F9)),
          const SizedBox(height: 10),

          // Footer : Info / Échéance + Action
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                (t['infoLigne'] ?? t['echeance']) as String,
                style: GoogleFonts.inter(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFF94A3B8),
                ),
              ),
              GestureDetector(
                onTap: () {
                  final uuid = t['uuid']?.toString();
                  final action = t['actionLibelle'] ?? t['action'];
                  if (uuid != null) {
                    if (action == 'Démarrer') {
                      _demarrer(uuid);
                      return;
                    } else if (action == 'Terminer la tâche') {
                      _terminer(uuid);
                      return;
                    }
                  }
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text('Action: $action')));
                },
                child: Text(
                  (t['actionLibelle'] ?? t['action']) as String,
                  style: GoogleFonts.inter(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    color:
                        (t['actionLibelle'] == 'Consulter' ||
                            t['action'] == 'Consulter')
                        ? const Color(0xFF64748B)
                        : const Color(0xFF1D61F2),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
