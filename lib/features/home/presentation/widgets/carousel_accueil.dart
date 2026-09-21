import 'dart:async';
import 'package:flutter/material.dart';

class CarouselAccueil extends StatefulWidget {
  const CarouselAccueil({this.autoPlay = true, super.key});

  final bool autoPlay;

  @override
  State<CarouselAccueil> createState() => _CarouselAccueilState();
}

class _CarouselAccueilState extends State<CarouselAccueil> {
  late final PageController _pageController;
  int _pageActuelle = 0;
  Timer? _timer;

  final List<String> _images = const [
    'assets/images/carousel_stagiaires_1.jpg',
    'assets/images/carousel_stagiaires_2.jpg',
    'assets/images/carousel_stagiaires_1.jpg',
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    if (widget.autoPlay) {
      _demarrerMinuteur();
    }
  }

  void _demarrerMinuteur() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (!mounted) return;
      final pageSuivante = (_pageActuelle + 1) % _images.length;
      _pageController.animateToPage(
        pageSuivante,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOutCubic,
      );
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 195,
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: Color(0x12000000),
            blurRadius: 16,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          children: [
            // PageView pour le défilement d'images
            PageView.builder(
              controller: _pageController,
              itemCount: _images.length,
              onPageChanged: (index) {
                setState(() => _pageActuelle = index);
              },
              itemBuilder: (context, index) {
                return Image.asset(
                  _images[index],
                  width: double.infinity,
                  height: double.infinity,
                  fit: BoxFit.cover,
                  alignment: Alignment.center,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      color: const Color(0xFF1E293B),
                      child: const Center(
                        child: Icon(
                          Icons.medical_services_outlined,
                          size: 48,
                          color: Colors.white70,
                        ),
                      ),
                    );
                  },
                );
              },
            ),

            // Voile dégradé très léger en bas pour la lisibilité des indicateurs
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              height: 48,
              child: Container(
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

            // Indicateurs de pagination en bas au centre
            Positioned(
              left: 0,
              right: 0,
              bottom: 12,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(_images.length, (index) {
                  final estActif = index == _pageActuelle;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    width: estActif ? 16 : 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: estActif
                          ? const Color(0xFF2563EB)
                          : Colors.white.withValues(alpha: 0.7),
                      borderRadius: BorderRadius.circular(3),
                    ),
                  );
                }),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
