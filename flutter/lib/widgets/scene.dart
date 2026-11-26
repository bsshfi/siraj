import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../avatars.dart';
import '../data.dart';

/// رسمة المشهد + الأبطال + الرمز — نفس تكوين ART.page في الويب (لوحة 400×260):
/// البطل الأساسي كبير، والمشاركين (لين ٣) أصغر جنبه.
class SceneArt extends StatelessWidget {
  final String scene;
  final String prop;
  final List<Kid> heroes;
  final double radius;
  const SceneArt({super.key, required this.scene, this.prop = '', this.heroes = const [], this.radius = 24});

  static const _known = {
    'desert', 'farm', 'fields', 'garden', 'hills', 'home', 'kitchen', 'market', 'mosque', 'mountain',
    'night', 'oldhome', 'park', 'rain', 'road', 'school', 'sea', 'souq', 'space'
  };

  @override
  Widget build(BuildContext context) {
    final name = _known.contains(scene) ? scene : 'home';
    final main = heroes.isNotEmpty ? heroes.first : null;
    final rest = heroes.length > 1 ? heroes.sublist(1, heroes.length.clamp(1, 4)) : <Kid>[];
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: AspectRatio(
        aspectRatio: 400 / 260,
        child: LayoutBuilder(builder: (context, box) {
          final k = box.maxWidth / 400;
          Widget person(Kid kid, double x, double y, double s) =>
              Positioned(left: x * k, top: y * k, width: 100 * s * k, height: 150 * s * k, child: KidAvatar(kid: kid));
          final mx = rest.isNotEmpty ? 26 + rest.length * 58 + 6.0 : 132.0;
          return Stack(fit: StackFit.expand, children: [
            SvgPicture.asset('assets/scenes/$name.svg', fit: BoxFit.cover),
            for (var i = 0; i < rest.length; i++) person(rest[i], 26 + i * 58.0, 168, .6),
            if (main != null) person(main, mx, 120, .92),
            if (prop.isNotEmpty)
              Positioned(
                left: (318 - 40) * k,
                top: (210 - 62) * k,
                width: 80 * k,
                child: Text(prop, textAlign: TextAlign.center, style: TextStyle(fontSize: 54 * k, height: 1.1)),
              ),
          ]);
        }),
      ),
    );
  }
}
