import 'package:flutter/material.dart';
import '../core/app_colors.dart';
import '../core/app_text_styles.dart';

/// اللوغو (الأيقونة + اسم التطبيق) المستخدم بأعلى الصفحتين
class ScaleFlowLogo extends StatelessWidget {
  final double iconSize;

  const ScaleFlowLogo({super.key, this.iconSize = 64});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          width: iconSize,
          height: iconSize,
          child: CustomPaint(
            painter: _LogoIconPainter(),
          ),
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Scale', style: AppTextStyles.brandScale),
            Text('Flow', style: AppTextStyles.brandFlow),
          ],
        ),
      ],
    );
  }
}

/// رسم بسيط لأيقونة اللوغو (حرفي S/F متشابكين بتدرج أزرق-أخضر)
/// بديل مؤقت عن ملف SVG/PNG الرسمي للهوية البصرية
class _LogoIconPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final gradient = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [AppColors.logoTeal, AppColors.logoGreen],
    );

    final rect = Offset.zero & size;
    final paint = Paint()
      ..shader = gradient.createShader(rect)
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.17
      ..strokeCap = StrokeCap.round;

    final w = size.width;
    final h = size.height;

    // القوس العلوي (حرف S)
    final topPath = Path()
      ..moveTo(w * 0.72, h * 0.18)
      ..cubicTo(w * 0.30, h * 0.05, w * 0.10, h * 0.30, w * 0.32, h * 0.46)
      ..cubicTo(w * 0.48, h * 0.58, w * 0.60, h * 0.55, w * 0.68, h * 0.50);

    // القوس السفلي (حرف F)
    final bottomPath = Path()
      ..moveTo(w * 0.28, h * 0.82)
      ..cubicTo(w * 0.70, h * 0.95, w * 0.90, h * 0.70, w * 0.68, h * 0.54)
      ..cubicTo(w * 0.52, h * 0.42, w * 0.40, h * 0.45, w * 0.32, h * 0.50);

    canvas.drawPath(topPath, paint);
    canvas.drawPath(bottomPath, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
