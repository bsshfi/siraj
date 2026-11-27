import 'package:flutter/material.dart';

/// ألوان سراج (نفس نسخة الويب)
class C {
  static const sky = Color(0xFF4FA3EC);
  static const skyLight = Color(0xFFBFE0FB);
  static const skyPale = Color(0xFFEAF5FF);
  static const orange = Color(0xFFF2851E);
  static const orange2 = Color(0xFFFFA03E);
  static const ink = Color(0xFF2A2F45);
  static const soft = Color(0xFF7A8098);
  static const purple = Color(0xFF8B5CF6);
  static const night1 = Color(0xFF1E2348);
  static const night2 = Color(0xFF4A3F6B);
}

ThemeData sirajTheme() {
  final base = ThemeData(
    useMaterial3: true,
    fontFamily: 'Baloo',
    colorScheme: ColorScheme.fromSeed(seedColor: C.sky, primary: C.orange, secondary: C.purple),
    scaffoldBackgroundColor: C.skyPale,
    splashFactory: InkSparkle.splashFactory,
  );
  return base.copyWith(
    textTheme: base.textTheme.apply(bodyColor: C.ink, displayColor: C.ink, fontFamily: 'Baloo'),
    pageTransitionsTheme: const PageTransitionsTheme(builders: {
      TargetPlatform.android: ZoomPageTransitionsBuilder(),
    }),
  );
}

/// بطاقة زجاجية مثل .card في الويب: أبيض ٧٤٪، حدّ أبيض، زوايا ٢٦، ظل ناعم
class SoftCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final bool clip;
  const SoftCard({super.key, required this.child, this.padding = const EdgeInsets.all(16), this.onTap, this.clip = false});

  @override
  Widget build(BuildContext context) {
    final r = BorderRadius.circular(26);
    Widget inner = Padding(padding: padding, child: child);
    if (onTap != null) inner = Material(color: Colors.transparent, child: InkWell(borderRadius: r, onTap: onTap, child: inner));
    return Container(
      clipBehavior: clip ? Clip.antiAlias : Clip.none,
      decoration: BoxDecoration(
        color: const Color(0xBDFFFFFF),
        borderRadius: r,
        border: Border.all(color: const Color(0xF2FFFFFF), width: 1),
        boxShadow: const [BoxShadow(color: Color(0x1C50628A), blurRadius: 28, offset: Offset(0, 10))],
      ),
      child: inner,
    );
  }
}

/// الزر البرتقالي الكبير مثل .btn في الويب (تدرّج، ظل تحته، وحافة سفلية أغمق)
class BigButton extends StatelessWidget {
  final String label;
  final IconData? icon;
  final VoidCallback onTap;
  final double fontSize;
  const BigButton({super.key, required this.label, required this.onTap, this.icon, this.fontSize = 20});

  @override
  Widget build(BuildContext context) {
    final r = BorderRadius.circular(20);
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [C.orange2, C.orange], begin: Alignment.topCenter, end: Alignment.bottomCenter),
        borderRadius: r,
        boxShadow: const [BoxShadow(color: Color(0x4DF2851E), blurRadius: 16, offset: Offset(0, 7))],
      ),
      child: ClipRRect(
        borderRadius: r,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: r,
            onTap: onTap,
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(begin: Alignment.bottomCenter, end: Alignment.topCenter, colors: [Color(0x1A000000), Color(0x1A000000), Color(0x00000000), Color(0x00000000)], stops: [0, .07, .07, 1]),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
              child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                if (icon != null) ...[Icon(icon, color: Colors.white, size: 24), const SizedBox(width: 8)],
                Flexible(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(label, maxLines: 1, style: TextStyle(color: Colors.white, fontSize: fontSize, fontWeight: FontWeight.w800, height: 1.4)),
                  ),
                ),
              ]),
            ),
          ),
        ),
      ),
    );
  }
}
