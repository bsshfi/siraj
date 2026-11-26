import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../data.dart';

/// رسمة المشهد + البطل + الرمز (نفس تكوين ART.page في الويب: لوحة 400×260)
class SceneArt extends StatelessWidget {
  final String scene;
  final String prop;
  final Kid? hero;
  final double radius;
  const SceneArt({super.key, required this.scene, this.prop = '', this.hero, this.radius = 24});

  static const _known = {
    'desert', 'farm', 'fields', 'garden', 'hills', 'home', 'kitchen', 'market', 'mosque', 'mountain',
    'night', 'oldhome', 'park', 'rain', 'road', 'school', 'sea', 'souq', 'space'
  };

  @override
  Widget build(BuildContext context) {
    final name = _known.contains(scene) ? scene : 'home';
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: AspectRatio(
        aspectRatio: 400 / 260,
        child: LayoutBuilder(builder: (context, box) {
          final k = box.maxWidth / 400; // نفس مقياس لوحة الويب
          return Stack(fit: StackFit.expand, children: [
            SvgPicture.asset('assets/scenes/$name.svg', fit: BoxFit.cover),
            if (hero != null)
              Positioned(
                left: 132 * k,
                top: 120 * k,
                width: 100 * k * .92,
                height: 150 * k * .92,
                child: SvgPicture.asset(hero!.isGirl ? 'assets/avatars/girl.svg' : 'assets/avatars/boy.svg', fit: BoxFit.contain),
              ),
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
