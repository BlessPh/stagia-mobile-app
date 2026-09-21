import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:latlong2/latlong.dart';
import '../../../notifications/presentation/pages/notifications_page.dart';
import '../../data/datasources/source_campagne_mock.dart';
import '../../domain/entities/campagne_stage.dart';
import 'reservation_page.dart';

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
  late final CampagneStage _campagne;
  late HopitalCampagne _hopitalSelectionne;
  final MapController _mapController = MapController();

  @override
  void initState() {
    super.initState();
    _campagne = widget.campagne ?? SourceCampagneMock.obtenirCampagneOuverte();
    _hopitalSelectionne = widget.hopitalInitial ??
        (_campagne.hopitaux.isNotEmpty
            ? _campagne.hopitaux.first
            : SourceCampagneMock.campagnePrincipale.hopitaux.first);
  }

  void _selectionnerHopital(HopitalCampagne hopital) {
    setState(() => _hopitalSelectionne = hopital);
    if (hopital.latitude != null && hopital.longitude != null) {
      _mapController.move(
        LatLng(hopital.latitude!, hopital.longitude!),
        13.8,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final centreCarte = LatLng(
      _hopitalSelectionne.latitude ?? -4.3060,
      _hopitalSelectionne.longitude ?? 15.2866,
    );

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: _buildAppBar(context),
      body: SafeArea(
        child: Column(
          children: [
            // 1. CARTE INTERACTIVE
            Expanded(
              flex: 42,
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
                        markers: _campagne.hopitaux.map((hopital) {
                          final estSelectionne =
                              hopital.id == _hopitalSelectionne.id;
                          final lat = hopital.latitude ?? -4.3060;
                          final lng = hopital.longitude ?? 15.2866;

                          if (estSelectionne) {
                            return Marker(
                              point: LatLng(lat, lng),
                              width: 150,
                              height: 80,
                              alignment: Alignment.topCenter,
                              child: GestureDetector(
                                onTap: () => _selectionnerHopital(hopital),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      Icons.location_on,
                                      color: Color(0xFFEF4444),
                                      size: 42,
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 3.5,
                                      ),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF1D61F2),
                                        borderRadius: BorderRadius.circular(20),
                                        boxShadow: const [
                                          BoxShadow(
                                            color: Color(0x33000000),
                                            blurRadius: 6,
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
                            width: 36,
                            height: 36,
                            child: GestureDetector(
                              onTap: () => _selectionnerHopital(hopital),
                              child: Icon(
                                Icons.location_on,
                                color: couleurMarker,
                                size: 34,
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ),

                  // Bouton recentrer en bas à droite de la carte
                  Positioned(
                    right: 12,
                    bottom: 12,
                    child: FloatingActionButton.small(
                      heroTag: 'recentrer_carte',
                      backgroundColor: Colors.white,
                      foregroundColor: const Color(0xFF1D61F2),
                      elevation: 3,
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
                      child: const Icon(Icons.my_location_rounded, size: 20),
                    ),
                  ),
                ],
              ),
            ),

            // 2. CARROUSEL HORIZONTAL DES HÔPITAUX + DÉTAIL EN BAS
            Expanded(
              flex: 58,
              child: ListView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.only(top: 14, bottom: 20),
                children: [
                  // Carrousel horizontal des cartes d'hôpitaux
                  SizedBox(
                    height: 122,
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
                          onSelectionner: () => _selectionnerHopital(hopital),
                          onReserver: () {
                            Navigator.of(context).push(
                              MaterialPageRoute<void>(
                                builder: (_) => ReservationPage(
                                  campagne: _campagne,
                                  hopital: hopital,
                                ),
                              ),
                            );
                          },
                          onVoirItineraire: () {
                            _mapController.move(
                              LatLng(
                                hopital.latitude ?? -4.3060,
                                hopital.longitude ?? 15.2866,
                              ),
                              15.0,
                            );
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Itinéraire vers ${hopital.nom} (${hopital.distanceKm} km)'),
                                duration: const Duration(seconds: 2),
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),

                  const SizedBox(height: 14),

                  // Fiche détaillée de l'hôpital sélectionné
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: _FicheDetailHopital(
                      hopital: _hopitalSelectionne,
                      onReserver: () {
                        Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => ReservationPage(
                              campagne: _campagne,
                              hopital: _hopitalSelectionne,
                            ),
                          ),
                        );
                      },
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

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: const Color(0xFFF8FAFC),
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      centerTitle: true,
      leading: IconButton(
        tooltip: 'Retour',
        icon: const Icon(
          Icons.arrow_back_ios_new_rounded,
          size: 20,
          color: Color(0xFF0F172A),
        ),
        onPressed: () => Navigator.of(context).maybePop(),
      ),
      title: Text(
        'Hôpitaux disponibles',
        style: GoogleFonts.inter(
          fontSize: 17,
          fontWeight: FontWeight.w800,
          color: const Color(0xFF0F172A),
        ),
      ),
      actions: [
        Stack(
          clipBehavior: Clip.none,
          children: [
            IconButton(
              tooltip: 'Notifications',
              onPressed: () => Navigator.of(context, rootNavigator: true).push(
                MaterialPageRoute<void>(
                  builder: (_) => const NotificationsPage(),
                ),
              ),
              icon: const Icon(
                Icons.notifications_none_rounded,
                color: Color(0xFF0F172A),
                size: 26,
              ),
              visualDensity: VisualDensity.compact,
            ),
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
    required this.onSelectionner,
    required this.onReserver,
    required this.onVoirItineraire,
  });

  final HopitalCampagne hopital;
  final bool estSelectionne;
  final VoidCallback onSelectionner;
  final VoidCallback onReserver;
  final VoidCallback onVoirItineraire;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onSelectionner,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: 258,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: estSelectionne
                ? const Color(0xFF1D61F2)
                : const Color(0xFFE2E8F0),
            width: estSelectionne ? 2.0 : 1.0,
          ),
          boxShadow: [
            BoxShadow(
              color: estSelectionne
                  ? const Color(0xFF1D61F2).withValues(alpha: 0.08)
                  : const Color(0x06000000),
              blurRadius: 10,
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
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    hopital.nom,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF0F172A),
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
                    color: const Color(0xFFFFF1EB),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '${hopital.placesRestantesEffectives} places rest.',
                    style: GoogleFonts.inter(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFFEA580C),
                    ),
                  ),
                ),
              ],
            ),

            // Distance & Localisation
            Text(
              '${hopital.distanceKm.toStringAsFixed(1)} km • ${hopital.localisationCourte}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF64748B),
              ),
            ),

            // Ligne d'actions : "Voir itinéraire" + Bouton "Réserver"
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                InkWell(
                  onTap: onVoirItineraire,
                  borderRadius: BorderRadius.circular(4),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Text(
                      'Voir itinéraire',
                      style: GoogleFonts.inter(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF1D61F2),
                      ),
                    ),
                  ),
                ),
                if (estSelectionne)
                  SizedBox(
                    height: 32,
                    child: FilledButton(
                      onPressed: onReserver,
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFF1D61F2),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        elevation: 0,
                      ),
                      child: Text(
                        'Réserver',
                        style: GoogleFonts.inter(
                          fontSize: 12,
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
    required this.onReserver,
  });

  final HopitalCampagne hopital;
  final VoidCallback onReserver;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFF1F5F9)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x08000000),
            blurRadius: 12,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Titre et Description
          Text(
            hopital.nom,
            style: GoogleFonts.inter(
              fontSize: 18.5,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 3),
          Text(
            hopital.description,
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF64748B),
            ),
          ),

          const SizedBox(height: 14),

          // Adresse
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.location_on_outlined,
                size: 18,
                color: Color(0xFF64748B),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  hopital.adresse ?? '${hopital.commune}, ${hopital.ville}',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF475569),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          // Téléphone
          Row(
            children: [
              const Icon(
                Icons.phone_outlined,
                size: 17,
                color: Color(0xFF64748B),
              ),
              const SizedBox(width: 8),
              Text(
                hopital.telephone,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFF475569),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Titre des services ouverts
          Text(
            'SERVICES OUVERTS AUX STAGIAIRES',
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.6,
              color: const Color(0xFF0F172A),
            ),
          ),

          const SizedBox(height: 10),

          // Badges des services
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: hopital.services.map((service) {
              return Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6.5,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  service,
                  style: GoogleFonts.inter(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF2563EB),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
