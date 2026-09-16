import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/widgets/contenu_adaptatif.dart';
import '../../data/models/etudiant_profil.dart';

class ModifierInformationsPersonnellesPage extends StatefulWidget {
  const ModifierInformationsPersonnellesPage({
    required this.profil,
    super.key,
  });

  final EtudiantProfil profil;

  @override
  State<ModifierInformationsPersonnellesPage> createState() =>
      _ModifierInformationsPersonnellesPageState();
}

class _ModifierInformationsPersonnellesPageState
    extends State<ModifierInformationsPersonnellesPage> {
  final _cle = GlobalKey<FormState>();
  late final TextEditingController _nom;
  late final TextEditingController _postnom;
  late final TextEditingController _prenom;
  late final TextEditingController _naissance;
  late final TextEditingController _adresse;
  late final TextEditingController _ville;
  late String _sexe;
  late String _province;

  final List<String> _provinces = const [
    'Kinshasa',
    'Haut-Katanga',
    'Kongo-Central',
    'Lualaba',
    'Nord-Kivu',
    'Sud-Kivu',
    'Kwilu',
    'Kwango',
    'Mai-Ndombe',
    'Kasaï',
    'Kasaï-Central',
    'Kasaï-Oriental',
    'Lomami',
    'Sankuru',
    'Maniema',
    'Ituri',
    'Haut-Uele',
    'Tshopo',
    'Bas-Uele',
    'Nord-Ubangi',
    'Sud-Ubangi',
    'Mongala',
    'Équateur',
    'Tshuapa',
    'Tanganyika',
    'Haut-Lomami',
  ];

  @override
  void initState() {
    super.initState();
    final p = widget.profil;
    final parties = p.nomComplet.trim().split(RegExp(r'\s+'));

    _nom = TextEditingController(text: parties.isEmpty ? '' : parties.first);
    _postnom = TextEditingController(
      text: parties.length > 1
          ? parties[1]
          : (parties.isNotEmpty ? parties.first : 'KABAMBA'),
    );
    _prenom = TextEditingController(
      text: parties.length > 2
          ? parties.sublist(2).join(' ')
          : (parties.length == 2 ? parties.last : 'Jonas'),
    );

    _naissance = TextEditingController(
      text: p.dateNaissance.trim().isNotEmpty ? p.dateNaissance : '',
    );
    _adresse = TextEditingController(text: p.adresse);
    _ville = TextEditingController();

    _sexe = p.sexe.trim().isNotEmpty ? p.sexe : 'Masculin';
    if (_sexe != 'Masculin' && _sexe != 'Féminin') {
      _sexe = 'Masculin';
    }

    _province = p.province.trim().isNotEmpty && _provinces.contains(p.province)
        ? p.province
        : 'Kinshasa';
  }

  @override
  void dispose() {
    _nom.dispose();
    _postnom.dispose();
    _prenom.dispose();
    _naissance.dispose();
    _adresse.dispose();
    _ville.dispose();
    super.dispose();
  }

  Future<void> _choisirDate() async {
    final date = await showDatePicker(
      context: context,
      firstDate: DateTime(1960),
      lastDate: DateTime.now(),
      initialDate: DateTime(2003, 3, 14),
    );
    if (date != null) {
      setState(() {
        _naissance.text =
            '${date.day.toString().padLeft(2, '0')}-${date.month.toString().padLeft(2, '0')}-${date.year}';
      });
    }
  }

  void _enregistrer() {
    FocusScope.of(context).unfocus();
    if (!(_cle.currentState?.validate() ?? false)) return;

    final nomComplet = [
      _nom.text,
      _postnom.text,
      _prenom.text,
    ].map((e) => e.trim()).where((e) => e.isNotEmpty).join(' ');

    final adresseFinale = _ville.text.trim().isNotEmpty
        ? '${_adresse.text.trim()}, ${_ville.text.trim()}'
        : _adresse.text.trim();

    Navigator.pop(
      context,
      widget.profil.copyWith(
        nomComplet: nomComplet,
        sexe: _sexe,
        dateNaissance: _naissance.text.trim(),
        adresse: adresseFinale,
        province: _province,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final modeSombre = Theme.of(context).brightness == Brightness.dark;
    final fondPage =
        modeSombre ? const Color(0xFF0F172A) : const Color(0xFFF4F5F7);
    final fondChamp = modeSombre ? const Color(0xFF1E293B) : Colors.white;
    final texteCouleur = modeSombre ? Colors.white : const Color(0xFF1E293B);
    final bordureCouleur =
        modeSombre ? const Color(0xFF334155) : const Color(0xFFCBD5E1);

    final inputDecoration = InputDecoration(
      filled: true,
      fillColor: fondChamp,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: bordureCouleur, width: 1.2),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: bordureCouleur, width: 1.2),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFF1D61FF), width: 1.5),
      ),
    );

    return Scaffold(
      backgroundColor: fondPage,
      appBar: AppBar(
        backgroundColor: fondPage,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            size: 20,
            color: texteCouleur,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Informations personnelles',
          style: GoogleFonts.inter(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: texteCouleur,
            letterSpacing: -0.3,
          ),
        ),
      ),
      body: ContenuAdaptatif(
        largeurMaximale: 520,
        enfant: Form(
          key: _cle,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 36),
            children: [
              // POST-NOM
              _Libelle(libelle: 'Post-nom', couleur: texteCouleur),
              const SizedBox(height: 8),
              TextFormField(
                controller: _postnom,
                style: GoogleFonts.inter(
                  fontSize: 15.5,
                  fontWeight: FontWeight.w500,
                  color: texteCouleur,
                ),
                decoration: inputDecoration,
              ),

              const SizedBox(height: 18),

              // PRÉNOM
              _Libelle(libelle: 'Prénom', couleur: texteCouleur),
              const SizedBox(height: 8),
              TextFormField(
                controller: _prenom,
                style: GoogleFonts.inter(
                  fontSize: 15.5,
                  fontWeight: FontWeight.w500,
                  color: texteCouleur,
                ),
                decoration: inputDecoration,
              ),

              const SizedBox(height: 18),

              // SEXE
              _Libelle(libelle: 'Sexe', couleur: texteCouleur),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                initialValue: _sexe,
                dropdownColor: fondChamp,
                icon: Icon(
                  Icons.keyboard_arrow_down_rounded,
                  size: 26,
                  color: texteCouleur,
                ),
                style: GoogleFonts.inter(
                  fontSize: 15.5,
                  fontWeight: FontWeight.w500,
                  color: texteCouleur,
                ),
                decoration: inputDecoration,
                items: const ['Masculin', 'Féminin']
                    .map(
                      (e) => DropdownMenuItem(
                        value: e,
                        child: Text(e),
                      ),
                    )
                    .toList(),
                onChanged: (val) {
                  if (val != null) setState(() => _sexe = val);
                },
              ),

              const SizedBox(height: 18),

              // DATE DE NAISSANCE
              _Libelle(libelle: 'Date de naissance', couleur: texteCouleur),
              const SizedBox(height: 8),
              InkWell(
                onTap: _choisirDate,
                borderRadius: BorderRadius.circular(14),
                child: IgnorePointer(
                  child: TextFormField(
                    controller: _naissance,
                    style: GoogleFonts.inter(
                      fontSize: 15.5,
                      fontWeight: FontWeight.w500,
                      color: texteCouleur,
                    ),
                    decoration: inputDecoration.copyWith(
                      hintText: 'JJ-MM-AAAA',
                      hintStyle: GoogleFonts.inter(
                        fontSize: 15.5,
                        color: const Color(0xFF94A3B8),
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // SECTION ADRESSE
              Text(
                'ADRESSE',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: texteCouleur,
                  letterSpacing: 0.5,
                ),
              ),

              const SizedBox(height: 14),

              // ADRESSE
              _Libelle(libelle: 'Adresse', couleur: texteCouleur),
              const SizedBox(height: 8),
              TextFormField(
                controller: _adresse,
                style: GoogleFonts.inter(
                  fontSize: 15.5,
                  fontWeight: FontWeight.w500,
                  color: texteCouleur,
                ),
                decoration: inputDecoration,
              ),

              const SizedBox(height: 18),

              // CITÉ / VILLE
              _Libelle(libelle: 'Cité/Ville', couleur: texteCouleur),
              const SizedBox(height: 8),
              TextFormField(
                controller: _ville,
                style: GoogleFonts.inter(
                  fontSize: 15.5,
                  fontWeight: FontWeight.w500,
                  color: texteCouleur,
                ),
                decoration: inputDecoration,
              ),

              const SizedBox(height: 18),

              // PROVINCE
              _Libelle(libelle: 'Province', couleur: texteCouleur),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                initialValue: _province,
                dropdownColor: fondChamp,
                icon: Icon(
                  Icons.keyboard_arrow_down_rounded,
                  size: 26,
                  color: texteCouleur,
                ),
                style: GoogleFonts.inter(
                  fontSize: 15.5,
                  fontWeight: FontWeight.w500,
                  color: texteCouleur,
                ),
                decoration: inputDecoration,
                items: _provinces
                    .map(
                      (e) => DropdownMenuItem(
                        value: e,
                        child: Text(e),
                      ),
                    )
                    .toList(),
                onChanged: (val) {
                  if (val != null) setState(() => _province = val);
                },
              ),

              const SizedBox(height: 32),

              // BOUTON ENREGISTRER
              SizedBox(
                width: double.infinity,
                height: 50,
                child: FilledButton(
                  onPressed: _enregistrer,
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF1D61FF),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: Text(
                    'Enregistrer les modifications',
                    style: GoogleFonts.inter(
                      fontSize: 15.5,
                      fontWeight: FontWeight.w600,
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

class _Libelle extends StatelessWidget {
  const _Libelle({required this.libelle, required this.couleur});
  final String libelle;
  final Color couleur;

  @override
  Widget build(BuildContext context) {
    return Text(
      libelle,
      style: GoogleFonts.inter(
        fontSize: 14.5,
        fontWeight: FontWeight.w700,
        color: couleur,
      ),
    );
  }
}
