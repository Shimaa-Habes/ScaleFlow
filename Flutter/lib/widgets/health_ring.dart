import 'package:flutter/material.dart';
import '../core/app_colors.dart';

/// حلقة دائرية بتعرض نسبة صحة المشروع (Project Health)، ولونها بيتغيّر
/// تلقائياً حسب النسبة: أخضر (صحي) / أصفر (متوسط) / كورال (خطر)
class HealthRing extends StatelessWidget {
  final int percent;
  final double size;
  final double strokeWidth;

  const HealthRing({
    super.key,
    required this.percent,
    this.size = 72,
    this.strokeWidth = 7,
  });

  Color get _ringColor {
    if (percent >= 75) return AppColors.statusGreen;
    if (percent >= 50) return AppColors.priorityYellow;
    return AppColors.alertCoral;
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: size,
            height: size,
            child: CircularProgressIndicator(
              value: percent / 100,
              strokeWidth: strokeWidth,
              backgroundColor: const Color(0xFFE7EAEC),
              valueColor: AlwaysStoppedAnimation<Color>(_ringColor),
              strokeCap: StrokeCap.round,
            ),
          ),
          Text(
            '$percent%',
            style: TextStyle(
              fontSize: size * 0.2,
              fontWeight: FontWeight.w700,
              color: AppColors.darkCharcoal,
            ),
          ),
        ],
      ),
    );
  }
}
