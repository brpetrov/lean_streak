import 'package:flutter/material.dart';

const _isWebKitBuild = bool.fromEnvironment('LEANSTREAK_WEBKIT_BUILD');

class AppLogoMark extends StatelessWidget {
  const AppLogoMark({
    super.key,
    this.size = 52,
    this.backgroundColor = Colors.white,
    this.markColor = const Color(0xFF2E8276),
  });

  final double size;
  final Color backgroundColor;
  final Color markColor;

  @override
  Widget build(BuildContext context) {
    if (!_isWebKitBuild) {
      return Image.asset(
        'assets/web/icon-192.png',
        width: size,
        height: size,
        fit: BoxFit.contain,
        filterQuality: FilterQuality.high,
      );
    }

    return RepaintBoundary(
      child: CustomPaint(
        size: Size.square(size),
        painter: _AppLogoMarkPainter(
          backgroundColor: backgroundColor,
          markColor: markColor,
        ),
      ),
    );
  }
}

class _AppLogoMarkPainter extends CustomPainter {
  const _AppLogoMarkPainter({
    required this.backgroundColor,
    required this.markColor,
  });

  final Color backgroundColor;
  final Color markColor;

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.shortestSide / 192;
    final dx = (size.width - size.shortestSide) / 2;
    final dy = (size.height - size.shortestSide) / 2;

    final backgroundPaint = Paint()
      ..isAntiAlias = true
      ..color = backgroundColor;
    canvas.drawCircle(
      Offset(dx + 96 * s, dy + 96 * s),
      94 * s,
      backgroundPaint,
    );

    final shadowPaint = Paint()
      ..isAntiAlias = true
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0x22000000), Color(0x00000000)],
      ).createShader(Rect.fromLTWH(dx + 30 * s, dy + 78 * s, 140 * s, 90 * s));
    final shadow = Path()
      ..moveTo(dx + 35 * s, dy + 92 * s)
      ..lineTo(dx + 92 * s, dy + 92 * s)
      ..lineTo(dx + 110 * s, dy + 96 * s)
      ..lineTo(dx + 160 * s, dy + 65 * s)
      ..lineTo(dx + 180 * s, dy + 86 * s)
      ..lineTo(dx + 120 * s, dy + 154 * s)
      ..lineTo(dx + 96 * s, dy + 154 * s)
      ..lineTo(dx + 35 * s, dy + 92 * s)
      ..close();
    canvas.drawPath(shadow, shadowPaint);

    final markPaint = Paint()
      ..isAntiAlias = true
      ..color = markColor
      ..style = PaintingStyle.fill;

    canvas.drawCircle(Offset(dx + 64 * s, dy + 63 * s), 13 * s, markPaint);

    final mark = Path()
      ..moveTo(dx + 35 * s, dy + 79 * s)
      ..lineTo(dx + 88 * s, dy + 79 * s)
      ..lineTo(dx + 110 * s, dy + 53 * s)
      ..lineTo(dx + 123 * s, dy + 64 * s)
      ..lineTo(dx + 104 * s, dy + 79 * s)
      ..lineTo(dx + 154 * s, dy + 52 * s)
      ..lineTo(dx + 162 * s, dy + 65 * s)
      ..lineTo(dx + 111 * s, dy + 97 * s)
      ..lineTo(dx + 108 * s, dy + 154 * s)
      ..lineTo(dx + 91 * s, dy + 154 * s)
      ..lineTo(dx + 94 * s, dy + 94 * s)
      ..lineTo(dx + 35 * s, dy + 94 * s)
      ..close();
    canvas.drawPath(mark, markPaint);
  }

  @override
  bool shouldRepaint(covariant _AppLogoMarkPainter oldDelegate) {
    return oldDelegate.backgroundColor != backgroundColor ||
        oldDelegate.markColor != markColor;
  }
}
