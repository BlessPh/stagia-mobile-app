import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';
import 'package:latlong2/latlong.dart';
import '../../../../core/network/configuration_api.dart';
import '../../../notifications/presentation/pages/notifications_page.dart';
import '../../data/datasources/source_campagne_mock.dart';
import '../../domain/entities/campagne_stage.dart';
import 'reservation_page.dart';

import 'dart:async';
import '../../../../core/services/sse_notifications_service.dart';
import '../../../../core/network/client_api_http.dart';
import '../../../../core/network/source_etudiant_distante.dart';

class HopitauxDisponiblesPage extends StatefulWidget {
  const HopitauxDisponiblesPage({
    this.campagne,
    this.hopitalInitial,
    super.key,
  });

  final CampagneStage? campagne;
  final HopitalCampagne? hopitalInitial;

  @override
  State<HopitauxDisponiblesPage> createState() =>
      _HopitauxDisponiblesPageState();
}

class _HopitauxDisponiblesPageState extends State<HopitauxDisponiblesPage> {
  final _sourceEtudiant = SourceEtudiantDistante(ClientApiHttp());
  late final CampagneStage _campagne;
  late HopitalCampagne _hopitalSelectionne;
  final MapController _mapController = MapController();
  Map<String, dynamic>? _counts;
  StreamSubscription? _sseSubscription;

  @override
  void initState() {
    super.initState();
    _chargerCounts();
    _sseSubscription = SseNotificationsService.instance.fluxCompteurs.listen((counts) {
      if (mounted) setState(() => _counts = counts);
    });
    _campagne =
        widget.campagne ??
        (ConfigurationApi.utiliserDonneesMockees
            ? SourceCampagneMock.obtenirCampagneOuverte()
            : throw StateError('Une campagne API est requise.'));
    _hopitalSelectionne =
        widget.hopitalInitial ??
        (_campagne.hopitaux.isNotEmpty
            ? _campagne.hopitaux.firstWhere(
                (hopital) => hopital.peutReserver,
                orElse: () => _campagne.hopitaux.first,
              )
            : ConfigurationApi.utiliserDonneesMockees
            ? SourceCampagneMock.campagnePrincipale.hopitaux.first
            : throw StateError('Aucun hôpital disponible.'));
  }

  Future<void> _chargerCounts() async {
    try {
      final res = await _sourceEtudiant.notificationCounts();
      if (mounted) {
        setState(() => _counts = res);
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _sseSubscription?.cancel();
    super.dispose();
  }

  void _selectionnerHopital(HopitalCampagne hopital) {
    setState(() => _hopitalSelectionne = hopital);
    if (hopital.latitude != null && hopital.longitude != null) {
      _mapController.move(LatLng(hopital.latitude!, hopital.longitude!), 13.8);
    }
  }

  @override
  Widget build(BuildContext context) {
    final modeSombre = Theme.of(context).brightness == Brightness.dark;
    final fondPage = modeSombre ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC);
    final fondCarte = modeSombre ? const Color(0xFF1E293B) : Colors.white;
    final bordure = modeSombre ? const Color(0xFF334155) : const Color(0xFFE2E8F0);
    final textePrincipal = modeSombre ? Colors.white : const Color(0xFF0F172A);
    final texteSecondaire = modeSombre ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
    final iconeCouleur = modeSombre ? const Color(0xFFCBD5E1) : const Color(0xFF475569);

    final centreCarte = LatLng(
      _hopitalSelectionne.latitude ?? -4.3060,
      _hopitalSelectionne.longitude ?? 15.2866,
    );

    return Scaffold(
      backgroundColor: fondPage,
      appBar: _buildAppBar(context, modeSombre, textePrincipal, iconeCouleur),
      body: SafeArea(
        child: Column(
          children: [
            // 1. CARTE INTERACTIVE
            Expanded(
              flex: 40,
              child: Stack(
                children: [
                  FlutterMap(
                    mapController: _mapController,
                    options: MapOptions(
                      initialCenter: centreCarte,
                      initialZoom: 13.5,
                      minZoom: 11.0,
                      maxZoom: 17.0,
                    ),
                    children: [
                      TileLayer(
                        urlTemplate:
                            'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                        userAgentPackageName: 'com.stagia.stagia',
                      ),
                      MarkerLayer(
                        markers: _campagne.hopitaux
                            .where(
                              (hopital) =>
                                  hopital.latitude != null &&
                                  hopital.longitude != null,
                            )
                            .map((hopital) {
                              final estSelectionne =
                                  hopital.id == _hopitalSelectionne.id;
                              final lat = hopital.latitude!;
                              final lng = hopital.longitude!;

                              if (estSelectionne) {
                                return Marker(
                                  point: LatLng(lat, lng),
                                  width: 170,
                                  height: 84,
                                  alignment: Alignment.topCenter,
                                  child: GestureDetector(
                                    onTap: () => _selectionnerHopital(hopital),
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(5),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFEF4444),
                                            shape: BoxShape.circle,
                                            boxShadow: [
                                              BoxShadow(
                                                color: const Color(0xFFEF4444).withValues(alpha: 0.4),
                                                blurRadius: 10,
                                                offset: const Offset(0, 3),
                                              ),
                                            ],
                                          ),
                                          child: const Icon(
                                            Icons.location_on_rounded,
                                            color: Colors.white,
                                            size: 20,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 10,
                                            vertical: 4,
                                          ),
                                          decoration: BoxDecoration(
                                            color: modeSombre
                                                ? const Color(0xFF1E293B)
                                                : const Color(0xFF0F172A),
                                            borderRadius: BorderRadius.circular(20),
                                            border: Border.all(
                                              color: const Color(0xFF38BDF8),
                                              width: 1.5,
                                            ),
                                            boxShadow: const [
                                              BoxShadow(
                                                color: Color(0x33000000),
                                                blurRadius: 8,
                                                offset: Offset(0, 2),
                                              ),
                                            ],
                                          ),
                                          child: Text(
                                            hopital.nom,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: GoogleFonts.inter(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w700,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              }

                              // Marqueurs des autres hôpitaux (colorés)
                              Color couleurMarker;
                              switch (hopital.id) {
                                case 'HOSP-002':
                                  couleurMarker = const Color(0xFF9333EA);
                                  break;
                                case 'HOSP-003':
                                  couleurMarker = const Color(0xFFF59E0B);
                                  break;
                                case 'HOSP-004':
                                  couleurMarker = const Color(0xFFEC4899);
                                  break;
                                default:
                                  couleurMarker = const Color(0xFF0EA5E9);
                              }

                              return Marker(
                                point: LatLng(lat, lng),
                                width: 38,
                                height: 38,
                                child: GestureDetector(
                                  onTap: () => _selectionnerHopital(hopital),
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: couleurMarker,
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: Colors.white,
                                        width: 2,
                                      ),
                                      boxShadow: const [
                                        BoxShadow(
                                          color: Color(0x2E000000),
                                          blurRadius: 5,
                                          offset: Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: const Icon(
                                      Icons.local_hospital_rounded,
                                      color: Colors.white,
                                      size: 18,
                                    ),
                                  ),
                                ),
                              );
                            })
                            .toList(),
                      ),
                    ],
                  ),

                  // Bouton recentrer en bas à droite de la carte
                  Positioned(
                    right: 14,
                    bottom: 14,
                    child: FloatingActionButton.small(
                      heroTag: 'recentrer_carte',
                      backgroundColor: fondCarte,
                      foregroundColor: iconeCouleur,
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(color: bordure),
                      ),
                      onPressed: () {
                        if (_hopitalSelectionne.latitude != null &&
                            _hopitalSelectionne.longitude != null) {
                          _mapController.move(
                            LatLng(
                              _hopitalSelectionne.latitude!,
                              _hopitalSelectionne.longitude!,
                            ),
                            14.0,
                          );
                        }
                      },
                      child: Icon(Iconsax.radar_2, size: 20, color: iconeCouleur),
                    ),
                  ),

                  // Pill indicateur du nombre d'hôpitaux
                  Positioned(
                    left: 14,
                    top: 14,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: (modeSombre ? const Color(0xFF0F172A) : Colors.white).withValues(alpha: 0.92),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: bordure),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x15000000),
                            blurRadius: 8,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Iconsax.hospital,
                            size: 14,
                            color: iconeCouleur,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '${_campagne.hopitaux.length} hôpitaux',
                            style: GoogleFonts.inter(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w700,
                              color: textePrincipal,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // 2. CARROUSEL HORIZONTAL DES HÔPITAUX + DÉTAIL EN BAS
            Expanded(
              flex: 60,
              child: ListView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.only(top: 14, bottom: 24),
                children: [
                  // En-tête carrousel
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Établissements partenaires',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.2,
                            color: texteSecondaire,
                          ),
                        ),
                        Text(
                          'Faites défiler',
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: texteSecondaire,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 10),

                  // Carrousel horizontal des cartes d'hôpitaux
                  SizedBox(
                    height: 130,
                    child: ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      scrollDirection: Axis.horizontal,
                      physics: const BouncingScrollPhysics(),
                      itemCount: _campagne.hopitaux.length,
                      separatorBuilder: (_, _) => const SizedBox(width: 12),
                      itemBuilder: (context, index) {
                        final hopital = _campagne.hopitaux[index];
                        final estSelectionne =
                            hopital.id == _hopitalSelectionne.id;

                        return _CarteHopitalHorizontal(
                          hopital: hopital,
                          estSelectionne: estSelectionne,
                          modeSombre: modeSombre,
                          iconeCouleur: iconeCouleur,
                          onSelectionner: () => _selectionnerHopital(hopital),
                          onReserver:
                              _campagne.autoriseReservationAutonome &&
                                  hopital.peutReserver
                              ? () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute<void>(
                                      builder: (_) => ReservationPage(
                                        campagne: _campagne,
                                        hopital: hopital,
                                      ),
                                    ),
                                  );
                                }
                              : null,
                          onVoirItineraire: () {
                            final latitude = hopital.latitude;
                            final longitude = hopital.longitude;
                            if (latitude != null && longitude != null) {
                              _mapController.move(
                                LatLng(latitude, longitude),
                                15.0,
                              );
                            }
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                backgroundColor: modeSombre ? const Color(0xFF1E293B) : const Color(0xFF0F172A),
                                content: Text(
                                  latitude != null && longitude != null
                                      ? 'Itinéraire vers ${hopital.nom} (${hopital.distanceKm} km)'
                                      : 'Coordonnées indisponibles pour ${hopital.nom}.',
                                  style: GoogleFonts.inter(color: Colors.white),
                                ),
                                duration: const Duration(seconds: 2),
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Fiche détaillée de l'hôpital sélectionné
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: _FicheDetailHopital(
                      hopital: _hopitalSelectionne,
                      modeSombre: modeSombre,
                      iconeCouleur: iconeCouleur,
                      onReserver:
                          _campagne.autoriseReservationAutonome &&
                              _hopitalSelectionne.peutReserver
                          ? () {
                              Navigator.of(context).push(
                                MaterialPageRoute<void>(
                                  builder: (_) => ReservationPage(
                                    campagne: _campagne,
                                    hopital: _hopitalSelectionne,
                                  ),
                                ),
                              );
                            }
                          : null,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(
    BuildContext context,
    bool modeSombre,
    Color textePrincipal,
    Color iconeCouleur,
  ) {
    final unreadNotifs =
        int.tryParse(_counts?['notifications']?.toString() ?? '0') ?? 0;
    final fondAppBar = modeSombre ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC);

    return AppBar(
      backgroundColor: fondAppBar,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      centerTitle: true,
      leading: IconButton(
        tooltip: 'Retour',
        icon: Icon(
          Icons.arrow_back_ios_new_rounded,
          size: 19,
          color: iconeCouleur,
        ),
        onPressed: () => Navigator.of(context).maybePop(),
      ),
      title: Text(
        'Hôpitaux disponibles',
        style: GoogleFonts.inter(
          fontSize: 17,
          fontWeight: FontWeight.w800,
          color: textePrincipal,
        ),
      ),
      actions: [
        Stack(
          clipBehavior: Clip.none,
          children: [
            IconButton(
              tooltip: 'Notifications',
              onPressed: () async {
                await Navigator.of(context, rootNavigator: true).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const NotificationsPage(),
                  ),
                );
                _chargerCounts();
              },
              icon: Icon(
                Iconsax.notification,
                color: iconeCouleur,
                size: 23,
              ),
              visualDensity: VisualDensity.compact,
            ),
            if (unreadNotifs > 0)
              Positioned(
                top: 5,
                right: 6,
                child: Container(
                  padding: const EdgeInsets.all(3),
                  decoration: const BoxDecoration(
                    color: Color(0xFFEF4444),
                    shape: BoxShape.circle,
                  ),
                  constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                  child: Text(
                    '$unreadNotifs',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
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
    );
  }
}

// -------------------------------------------------------------
// CARTE HORIZONTALE D'UN HÔPITAL
// -------------------------------------------------------------
class _CarteHopitalHorizontal extends StatelessWidget {
  const _CarteHopitalHorizontal({
    required this.hopital,
    required this.estSelectionne,
    required this.modeSombre,
    required this.iconeCouleur,
    required this.onSelectionner,
    required this.onReserver,
    required this.onVoirItineraire,
  });

  final HopitalCampagne hopital;
  final bool estSelectionne;
  final bool modeSombre;
  final Color iconeCouleur;
  final VoidCallback onSelectionner;
  final VoidCallback? onReserver;
  final VoidCallback onVoirItineraire;

  @override
  Widget build(BuildContext context) {
    final fond = modeSombre ? const Color(0xFF1E293B) : Colors.white;
    final bordureNormale = modeSombre ? const Color(0xFF334155) : const Color(0xFFE2E8F0);
    final bordureActive = const Color(0xFF1D61F2);
    final textePrincipal = modeSombre ? Colors.white : const Color(0xFF0F172A);
    final texteSecondaire = modeSombre ? const Color(0xFF94A3B8) : const Color(0xFF64748B);

    final placesRestantes = hopital.placesRestantesEffectives;
    final bool aDesPlaces = placesRestantes > 0;

    final badgeFond = aDesPlaces
        ? (modeSombre ? const Color(0xFF431407) : const Color(0xFFFFF1EB))
        : (modeSombre ? const Color(0xFF450A0A) : const Color(0xFFFEE2E2));
    final badgeTexte = aDesPlaces
        ? (modeSombre ? const Color(0xFFFB923C) : const Color(0xFFEA580C))
        : (modeSombre ? const Color(0xFFF87171) : const Color(0xFFDC2626));

    return InkWell(
      onTap: onSelectionner,
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 268,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: fond,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: estSelectionne ? bordureActive : bordureNormale,
            width: estSelectionne ? 2.0 : 1.0,
          ),
          boxShadow: [
            BoxShadow(
              color: estSelectionne
                  ? const Color(0xFF1D61F2).withValues(alpha: modeSombre ? 0.25 : 0.12)
                  : (modeSombre ? const Color(0x33000000) : const Color(0x08000000)),
              blurRadius: estSelectionne ? 12 : 6,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Ligne Titre + Badge places restantes
            Row(
              children: [
                Expanded(
                  child: Text(
                    hopital.nom,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: textePrincipal,
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 7,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: badgeFond,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    aDesPlaces ? '$placesRestantes places' : 'Complet',
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: badgeTexte,
                    ),
                  ),
                ),
              ],
            ),

            // Distance & Localisation avec icône neutre/grisâtre
            Row(
              children: [
                Icon(
                  Iconsax.location,
                  size: 13,
                  color: iconeCouleur,
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    [
                      if (hopital.distanceKm > 0)
                        '${hopital.distanceKm.toStringAsFixed(1)} km',
                      if (hopital.localisationCourte.isNotEmpty)
                        hopital.localisationCourte,
                    ].join(' • '),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w500,
                      color: texteSecondaire,
                    ),
                  ),
                ),
              ],
            ),

            // Ligne d'actions : "Voir itinéraire" + Bouton "Réserver"
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                InkWell(
                  onTap: onVoirItineraire,
                  borderRadius: BorderRadius.circular(6),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Iconsax.routing_2,
                          size: 14,
                          color: iconeCouleur,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Itinéraire',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: modeSombre ? const Color(0xFF60A5FA) : const Color(0xFF1D61F2),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                if (estSelectionne)
                  SizedBox(
                    height: 32,
                    child: FilledButton(
                      onPressed: onReserver,
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFFFF751F),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        elevation: 0,
                      ),
                      child: Text(
                        hopital.peutReserver ? 'Réserver' : 'Complet',
                        style: GoogleFonts.inter(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// -------------------------------------------------------------
// FICHE DÉTAILLÉE DE L'HÔPITAL
// -------------------------------------------------------------
class _FicheDetailHopital extends StatelessWidget {
  const _FicheDetailHopital({
    required this.hopital,
    required this.modeSombre,
    required this.iconeCouleur,
    required this.onReserver,
  });

  final HopitalCampagne hopital;
  final bool modeSombre;
  final Color iconeCouleur;
  final VoidCallback? onReserver;

  @override
  Widget build(BuildContext context) {
    final fond = modeSombre ? const Color(0xFF1E293B) : Colors.white;
    final bordure = modeSombre ? const Color(0xFF334155) : const Color(0xFFF1F5F9);
    final textePrincipal = modeSombre ? Colors.white : const Color(0xFF0F172A);
    final texteSecondaire = modeSombre ? const Color(0xFF94A3B8) : const Color(0xFF64748B);

    final fondInfoTile = modeSombre ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC);
    final bordureInfoTile = modeSombre ? const Color(0xFF334155) : const Color(0xFFE2E8F0);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: fond,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: bordure),
        boxShadow: [
          BoxShadow(
            color: modeSombre ? const Color(0x33000000) : const Color(0x08000000),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Titre et Description
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: modeSombre ? const Color(0xFF334155) : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Iconsax.hospital,
                  size: 22,
                  color: iconeCouleur,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      hopital.nom,
                      style: GoogleFonts.inter(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: textePrincipal,
                      ),
                    ),
                    if (hopital.description.isNotEmpty) ...[
                      const SizedBox(height: 3),
                      Text(
                        hopital.description,
                        style: GoogleFonts.inter(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w500,
                          color: texteSecondaire,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Coordonnées (Adresse & Téléphone)
          if ((hopital.adresse?.trim().isNotEmpty ?? false) ||
              hopital.localisationCourte.isNotEmpty) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: fondInfoTile,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: bordureInfoTile),
              ),
              child: Row(
                children: [
                  Icon(
                    Iconsax.location,
                    size: 18,
                    color: iconeCouleur,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      (hopital.adresse?.trim().isNotEmpty ?? false)
                          ? hopital.adresse!
                          : hopital.localisationCourte,
                      style: GoogleFonts.inter(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w500,
                        color: textePrincipal,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          if (hopital.telephone.trim().isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: fondInfoTile,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: bordureInfoTile),
              ),
              child: Row(
                children: [
                  Icon(
                    Iconsax.call,
                    size: 17,
                    color: iconeCouleur,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    hopital.telephone,
                    style: GoogleFonts.inter(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w500,
                      color: textePrincipal,
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 16),

          // Grille des indicateurs Clés (Capacité / Places et Frais)
          Row(
            children: [
              // Bloc Places
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: hopital.peutReserver
                        ? (modeSombre ? const Color(0xFF14532D).withValues(alpha: 0.4) : const Color(0xFFDCFCE7))
                        : (modeSombre ? const Color(0xFF7F1D1D).withValues(alpha: 0.35) : const Color(0xFFFEE2E2)),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: hopital.peutReserver
                          ? (modeSombre ? const Color(0xFF166534) : const Color(0xFFBBF7D0))
                          : (modeSombre ? const Color(0xFF991B1B) : const Color(0xFFFECACA)),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Iconsax.user_tag,
                            size: 15,
                            color: iconeCouleur,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Capacité',
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: texteSecondaire,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${hopital.placesRestantesEffectives} / ${hopital.capacite} places',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: hopital.peutReserver
                              ? (modeSombre ? const Color(0xFF4ADE80) : const Color(0xFF15803D))
                              : (modeSombre ? const Color(0xFFF87171) : const Color(0xFFDC2626)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(width: 10),

              // Bloc Frais
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: fondInfoTile,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: bordureInfoTile),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Iconsax.card,
                            size: 15,
                            color: iconeCouleur,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Frais requis',
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: texteSecondaire,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        hopital.fraisRequis
                            ? '${_formaterMontant(hopital.montantFrais)} ${hopital.devise}'
                            : 'Gratuit',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: textePrincipal,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          if (hopital.conditions != null && hopital.conditions!.trim().isNotEmpty) ...[
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: modeSombre ? const Color(0xFF1E293B) : const Color(0xFFFEF3C7).withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: modeSombre ? const Color(0xFF475569) : const Color(0xFFFDE68A),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Iconsax.info_circle,
                    size: 16,
                    color: iconeCouleur,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      hopital.conditions!,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: textePrincipal,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          if (hopital.services.isNotEmpty) ...[
            const SizedBox(height: 18),
            Row(
              children: [
                Icon(
                  Iconsax.firstline,
                  size: 15,
                  color: iconeCouleur,
                ),
                const SizedBox(width: 6),
                Text(
                  'SERVICES OUVERTS AUX STAGIAIRES',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                    color: texteSecondaire,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: hopital.services.map((service) {
                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 11,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: modeSombre ? const Color(0xFF0F172A) : const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: modeSombre ? const Color(0xFF334155) : const Color(0xFFDBEAFE),
                    ),
                  ),
                  child: Text(
                    service,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: modeSombre ? const Color(0xFF93C5FD) : const Color(0xFF2563EB),
                    ),
                  ),
                );
              }).toList(),
            ),
          ],

          const SizedBox(height: 20),

          // Bouton principal d'action
          SizedBox(
            width: double.infinity,
            height: 48,
            child: FilledButton(
              onPressed: onReserver,
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFFF751F),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    hopital.peutReserver ? Iconsax.calendar_tick : Iconsax.close_circle,
                    size: 18,
                    color: Colors.white,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    hopital.peutReserver ? 'Réserver dans cet hôpital' : 'Aucune place disponible',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formaterMontant(double montant) {
    if (montant <= 0) return 'Non communiqué';
    return montant == montant.roundToDouble()
        ? montant.toStringAsFixed(0)
        : montant.toStringAsFixed(2);
  }
}

