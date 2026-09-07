import 'package:flutter/material.dart';

/// A small decorative "mock aquarium" made entirely out of Material icons,
/// arranged to suggest a tank: fish swimming mid-water, a decor piece and
/// plant on the gravel, a filter box in the corner, and a few food flakes
/// drifting near the surface. Used as the hero graphic on the auth screens.
class TankIllustration extends StatelessWidget {
  const TankIllustration({super.key, this.height = 210});

  final double height;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(28),
      child: Container(
        height: height,
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF1E7F8C), Color(0xFF0B3B42)],
          ),
        ),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            // surface glare
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: 28,
              child: Container(color: Colors.white.withOpacity(0.10)),
            ),

            // drifting food flakes near the surface
            const Positioned(top: 20, left: 46, child: _Flake()),
            const Positioned(top: 34, left: 90, child: _Flake()),
            const Positioned(top: 16, left: 140, child: _Flake()),

            // equipment: filter box tucked in the back corner
            Positioned(
              top: 14,
              right: 14,
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.14),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.filter_alt_rounded, size: 20, color: Color(0xFF8FE3D8)),
              ),
            ),
            // a thin airline with a stream of bubbles from the filter
            Positioned(
              top: 40,
              right: 24,
              child: Column(
                children: const [
                  _Bubble(size: 5),
                  SizedBox(height: 6),
                  _Bubble(size: 7),
                  SizedBox(height: 6),
                  _Bubble(size: 4),
                ],
              ),
            ),

            // fish swimming at different depths
            Positioned(
              top: 44,
              left: 24,
              child: Icon(Icons.set_meal_rounded, size: 34, color: const Color(0xFFFF8A5B).withOpacity(0.95)),
            ),
            Positioned(
              top: 78,
              right: 70,
              child: Transform.flip(
                flipX: true,
                child: Icon(Icons.set_meal_rounded, size: 26, color: const Color(0xFFFFD166).withOpacity(0.95)),
              ),
            ),
            Positioned(
              top: 108,
              left: 90,
              child: Icon(Icons.set_meal_rounded, size: 20, color: const Color(0xFF8A4FD1).withOpacity(0.9)),
            ),

            // plant near the substrate
            Positioned(
              bottom: 22,
              left: 30,
              child: Icon(Icons.grass_rounded, size: 30, color: const Color(0xFF2EC4B6).withOpacity(0.9)),
            ),

            // castle / decor ornament
            Positioned(
              bottom: 20,
              right: 44,
              child: Icon(Icons.fort_rounded, size: 32, color: const Color(0xFFEAF7F5).withOpacity(0.85)),
            ),

            // gravel substrate strip
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                height: 18,
                decoration: BoxDecoration(
                  color: const Color(0xFF0B3B42),
                  border: Border(top: BorderSide(color: Colors.white.withOpacity(0.08), width: 2)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Flake extends StatelessWidget {
  const _Flake();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 5,
      height: 5,
      decoration: BoxDecoration(
        color: const Color(0xFFFFD166).withOpacity(0.85),
        borderRadius: BorderRadius.circular(1.5),
      ),
    );
  }
}

class _Bubble extends StatelessWidget {
  const _Bubble({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withOpacity(0.35),
      ),
    );
  }
}
