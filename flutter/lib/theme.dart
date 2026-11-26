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

/// بطاقة بيضاء ناعمة (بديل "الزجاج" في الويب — بدون تمويه، أخف بكثير)
class SoftCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  const SoftCard({super.key, required this.child, this.padding = const EdgeInsets.all(16), this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      elevation: 0,
      shadowColor: const Color(0x2250628A),
      borderRadius: BorderRadius.circular(26),
      child: InkWell(
        borderRadius: BorderRadius.circular(26),
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(26),
            boxShadow: const [BoxShadow(color: Color(0x1A50628A), blurRadius: 22, offset: Offset(0, 8))],
          ),
          padding: padding,
          child: child,
        ),
      ),
    );
  }
}

/// زر برتقالي كبير مثل الويب
class BigButton extends StatelessWidget {
  final String label;
  final IconData? icon;
  final VoidCallback onTap;
  const BigButton({super.key, required this.label, required this.onTap, this.icon});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [C.orange2, C.orange], begin: Alignment.topCenter, end: Alignment.bottomCenter),
        borderRadius: BorderRadius.circular(22),
        boxShadow: const [BoxShadow(color: Color(0x55F2851E), blurRadius: 14, offset: Offset(0, 6))],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(22),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
            child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              if (icon != null) ...[Icon(icon, color: Colors.white, size: 24), const SizedBox(width: 8)],
              Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(label, maxLines: 1, style: const TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w800)),
                ),
              ),
            ]),
          ),
        ),
      ),
    );
  }
}
