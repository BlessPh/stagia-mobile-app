import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';
import 'package:image_picker/image_picker.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:photo_manager_image_provider/photo_manager_image_provider.dart';

/// Modal bottom sheet moderne permettant de sélectionner une photo de profil :
/// - Prendre une nouvelle photo avec la caméra
/// - Parcourir et choisir parmi les images récentes du téléphone dans un GridView
/// - Accéder au sélecteur complet de documents / galerie système si besoin
class BottomSheetPhotoProfil extends StatefulWidget {
  const BottomSheetPhotoProfil({super.key});

  /// Affiche le bottom sheet et retourne le chemin [File.path] sélectionné ou pris, ou null si annulé.
  static Future<String?> afficher(BuildContext context) {
    return showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const BottomSheetPhotoProfil(),
    );
  }

  @override
  State<BottomSheetPhotoProfil> createState() => _BottomSheetPhotoProfilState();
}

class _BottomSheetPhotoProfilState extends State<BottomSheetPhotoProfil> {
  final ImagePicker _picker = ImagePicker();
  List<AssetEntity> _imagesRecentes = [];
  bool _chargement = true;
  bool _permissionRefusee = false;

  @override
  void initState() {
    super.initState();
    _chargerImagesRecentes();
  }

  Future<void> _chargerImagesRecentes() async {
    setState(() {
      _chargement = true;
      _permissionRefusee = false;
    });

    try {
      final PermissionState ps = await PhotoManager.requestPermissionExtend();
      if (!ps.isAuth && !ps.hasAccess) {
        if (mounted) {
          setState(() {
            _permissionRefusee = true;
            _chargement = false;
          });
        }
        return;
      }

      final List<AssetPathEntity> albums = await PhotoManager.getAssetPathList(
        type: RequestType.image,
        onlyAll: true,
      );

      if (albums.isNotEmpty) {
        final List<AssetEntity> assets = await albums.first.getAssetListRange(
          start: 0,
          end: 40,
        );
        if (mounted) {
          setState(() {
            _imagesRecentes = assets;
            _chargement = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _imagesRecentes = [];
            _chargement = false;
          });
        }
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _chargement = false;
        });
      }
    }
  }

  Future<void> _prendrePhoto() async {
    try {
      final XFile? photo = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1600,
        maxHeight: 1600,
        imageQuality: 85,
      );
      if (photo != null && mounted) {
        Navigator.of(context).pop(photo.path);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Impossible d\'ouvrir la caméra.'),
            backgroundColor: Color(0xFFEF4444),
          ),
        );
      }
    }
  }

  Future<void> _ouvrirGalerieComplete() async {
    try {
      final XFile? photo = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1600,
        maxHeight: 1600,
        imageQuality: 85,
      );
      if (photo != null && mounted) {
        Navigator.of(context).pop(photo.path);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Impossible d\'ouvrir la galerie.'),
            backgroundColor: Color(0xFFEF4444),
          ),
        );
      }
    }
  }

  Future<void> _selectionnerAsset(AssetEntity asset) async {
    final File? file = await asset.file;
    if (file != null && mounted) {
      Navigator.of(context).pop(file.path);
    }
  }

  @override
  Widget build(BuildContext context) {
    final modeSombre = Theme.of(context).brightness == Brightness.dark;
    final fondModal = modeSombre ? const Color(0xFF1E293B) : Colors.white;
    final texteCouleur = modeSombre ? Colors.white : const Color(0xFF0F172A);
    final sousTexteCouleur = modeSombre ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
    final bordureCouleur = modeSombre ? const Color(0xFF334155) : const Color(0xFFE2E8F0);

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.75,
      ),
      decoration: BoxDecoration(
        color: fondModal,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 24,
            offset: const Offset(0, -6),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Poignée supérieure (drag handle)
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 44,
              height: 4.5,
              decoration: BoxDecoration(
                color: modeSombre ? const Color(0xFF475569) : const Color(0xFFCBD5E1),
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),

          // En-tête avec titre et bouton fermer
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 16, 12),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Choisir une photo',
                        style: GoogleFonts.inter(
                          fontSize: 19,
                          fontWeight: FontWeight.w800,
                          color: texteCouleur,
                          letterSpacing: -0.3,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        'Choisissez une photo dans la galerie ou prennez-en une nouvelle',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w400,
                          color: sousTexteCouleur,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: Icon(
                    Icons.close_rounded,
                    color: sousTexteCouleur,
                    size: 22,
                  ),
                  tooltip: 'Fermer',
                  style: IconButton.styleFrom(
                    backgroundColor: modeSombre
                        ? const Color(0xFF334155)
                        : const Color(0xFFF1F5F9),
                  ),
                ),
              ],
            ),
          ),

          const Divider(height: 1, thickness: 1, color: Color(0x15000000)),

          // Contenu principal : Grille avec icône Caméra + Images récentes
          Expanded(
            child: _chargement
                ? const Center(
                    child: CircularProgressIndicator(
                      color: Color(0xFF1D61FF),
                    ),
                  )
                : _permissionRefusee
                    ? _buildVuePermissionRefusee(texteCouleur, sousTexteCouleur)
                    : _buildGrillePhotos(bordureCouleur),
          ),
        ],
      ),
    );
  }

  Widget _buildVuePermissionRefusee(Color texteCouleur, Color sousTexteCouleur) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: Color(0x151D61FF),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Iconsax.gallery_slash,
                size: 38,
                color: Color(0xFF1D61FF),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Accès aux photos requis',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: texteCouleur,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Autorisez l\'accès à vos médias pour prévisualiser et choisir votre photo de profil rapidement.',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 13,
                color: sousTexteCouleur,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton.icon(
                  onPressed: _chargerImagesRecentes,
                  icon: const Icon(Icons.refresh_rounded, size: 18),
                  label: const Text('Autoriser'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1D61FF),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 12,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                OutlinedButton.icon(
                  onPressed: _prendrePhoto,
                  icon: const Icon(Iconsax.camera, size: 18),
                  label: const Text('Prendre photo'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF1D61FF),
                    side: const BorderSide(color: Color(0xFF1D61FF)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
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

  Widget _buildGrillePhotos(Color bordureCouleur) {
    // 1ère case = Caméra
    // 2ème case = Bouton "Autre dossier / Parcourir"
    // Reste = Images récentes
    final totalElements = 2 + _imagesRecentes.length;

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      physics: const BouncingScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 1.0,
      ),
      itemCount: totalElements,
      itemBuilder: (context, index) {
        if (index == 0) {
          return _buildBoutonCamera();
        }
        if (index == 1) {
          return _buildBoutonParcourirGalerie();
        }

        final asset = _imagesRecentes[index - 2];
        return _buildCaseImage(asset);
      },
    );
  }

  Widget _buildBoutonCamera() {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: _prendrePhoto,
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF1E60FF), Color(0xFF0F47D6)],
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF1D61FF).withValues(alpha: 0.3),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: const BoxDecoration(
                  color: Color(0x24FFFFFF),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Iconsax.camera,
                  color: Colors.white,
                  size: 26,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Caméra',
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBoutonParcourirGalerie() {
    final modeSombre = Theme.of(context).brightness == Brightness.dark;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: _ouvrirGalerieComplete,
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          decoration: BoxDecoration(
            color: modeSombre ? const Color(0xFF334155) : const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: modeSombre ? const Color(0xFF475569) : const Color(0xFFE2E8F0),
              width: 1.2,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFF1D61FF).withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Iconsax.folder_open,
                  color: Color(0xFF1D61FF),
                  size: 24,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Parcourir',
                style: GoogleFonts.inter(
                  color: modeSombre ? Colors.white : const Color(0xFF1E293B),
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCaseImage(AssetEntity asset) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Material(
        color: const Color(0xFFE2E8F0),
        child: InkWell(
          onTap: () => _selectionnerAsset(asset),
          child: Stack(
            fit: StackFit.expand,
            children: [
              AssetEntityImage(
                asset,
                isOriginal: false,
                thumbnailSize: const ThumbnailSize.square(250),
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => const Center(
                  child: Icon(Icons.broken_image, color: Colors.grey),
                ),
              ),
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  height: 20,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [
                        Colors.black.withValues(alpha: 0.35),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
