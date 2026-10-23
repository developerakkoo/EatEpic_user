import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:food_app/core/theme/login_tokens.dart';

class LoginIndiaFlag extends StatelessWidget {
  const LoginIndiaFlag({super.key, this.width = 20, this.height = 14});

  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(3),
      child: SizedBox(
        width: width,
        height: height,
        child: const Column(
          children: [
            Expanded(child: ColoredBox(color: Color(0xFFFF9933))),
            Expanded(child: ColoredBox(color: Color(0xFFFFFFFF))),
            Expanded(child: ColoredBox(color: Color(0xFF138808))),
          ],
        ),
      ),
    );
  }
}

class LoginGoogleMark extends StatelessWidget {
  const LoginGoogleMark({super.key, this.size = 20});

  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: const CustomPaint(painter: _GoogleMarkPainter()),
    );
  }
}

class _GoogleMarkPainter extends CustomPainter {
  const _GoogleMarkPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final stroke = size.width * 0.18;
    final inset = stroke / 2;
    final rect = Rect.fromLTWH(
      inset,
      inset,
      size.width - stroke,
      size.height - stroke,
    );
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.square;

    paint.color = const Color(0xFFEA4335);
    canvas.drawArc(rect, -math.pi * 0.85, math.pi * 0.7, false, paint);
    paint.color = const Color(0xFFFBBC05);
    canvas.drawArc(rect, math.pi * 0.85, math.pi * 0.55, false, paint);
    paint.color = const Color(0xFF34A853);
    canvas.drawArc(rect, math.pi * 0.3, math.pi * 0.55, false, paint);
    paint.color = const Color(0xFF4285F4);
    canvas.drawArc(rect, -math.pi * 0.15, math.pi * 0.45, false, paint);

    canvas.drawRect(
      Rect.fromLTWH(
        size.width / 2,
        size.height / 2 - stroke / 2,
        size.width / 2 - inset,
        stroke,
      ),
      Paint()..color = const Color(0xFF4285F4),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class LoginBowlIllustration extends StatelessWidget {
  const LoginBowlIllustration({super.key});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'A bowl of home-cooked food',
      image: true,
      child: const SizedBox(
        width: 220,
        height: 200,
        child: CustomPaint(painter: _BowlPainter()),
      ),
    );
  }
}

class _BowlPainter extends CustomPainter {
  const _BowlPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final shadow = Paint()..color = const Color(0x33000000);
    canvas.drawOval(
      Rect.fromCenter(center: Offset(cx, size.height * 0.90), width: 120, height: 16),
      shadow,
    );

    final bowlFill = Paint()..color = Colors.white;
    final body = Path()
      ..moveTo(cx - 78, size.height * 0.46)
      ..quadraticBezierTo(cx - 82, size.height * 0.78, cx, size.height * 0.86)
      ..quadraticBezierTo(cx + 82, size.height * 0.78, cx + 78, size.height * 0.46)
      ..close();
    canvas.drawPath(body, bowlFill);

    final rim = Rect.fromCenter(
      center: Offset(cx, size.height * 0.46),
      width: 168,
      height: 42,
    );
    canvas.drawOval(rim, bowlFill);
    canvas.drawOval(
      rim,
      Paint()
        ..color = const Color(0x14000000)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );

    final food = Rect.fromCenter(
      center: Offset(cx, size.height * 0.45),
      width: 148,
      height: 34,
    );
    canvas.drawOval(food, Paint()..color = LoginTokens.orange);

    void bit(Offset c, double r, Color color) {
      canvas.drawCircle(c, r, Paint()..color = color);
    }

    bit(Offset(cx - 28, size.height * 0.43), 9, LoginTokens.saffron);
    bit(Offset(cx - 6, size.height * 0.40), 11, LoginTokens.deepOrange);
    bit(Offset(cx + 18, size.height * 0.44), 8, LoginTokens.saffron);
    bit(Offset(cx + 36, size.height * 0.41), 7, LoginTokens.orange);
    bit(Offset(cx - 44, size.height * 0.46), 6, LoginTokens.deepOrange);
    bit(Offset(cx + 4, size.height * 0.48), 5, LoginTokens.saffron);

    final garnish = Paint()
      ..color = LoginTokens.garnish
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.4
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(
      Rect.fromCenter(center: Offset(cx + 22, size.height * 0.40), width: 28, height: 14),
      math.pi * 0.15,
      math.pi * 0.9,
      false,
      garnish,
    );
    canvas.drawArc(
      Rect.fromCenter(center: Offset(cx - 18, size.height * 0.38), width: 22, height: 12),
      math.pi * 1.1,
      math.pi * 0.8,
      false,
      garnish,
    );

    final steam = Paint()
      ..color = Colors.white.withValues(alpha: 0.55)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;

    void steamCurve(double x, double top) {
      final path = Path()
        ..moveTo(x, size.height * 0.36)
        ..cubicTo(x + 8, size.height * 0.28, x - 8, size.height * 0.20, x, top);
      canvas.drawPath(path, steam);
    }

    steamCurve(cx - 22, size.height * 0.10);
    steamCurve(cx + 2, size.height * 0.06);
    steamCurve(cx + 24, size.height * 0.12);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class LoginHeroBadge extends StatelessWidget {
  const LoginHeroBadge({
    super.key,
    required this.icon,
    required this.iconColor,
    required this.label,
  });

  final IconData icon;
  final Color iconColor;
  final String label;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(LoginTokens.radiusPill),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1F000000),
            blurRadius: 24,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: iconColor),
            const SizedBox(width: 8),
            Text(label, style: LoginType.badge(LoginTokens.textPrimary)),
          ],
        ),
      ),
    );
  }
}
