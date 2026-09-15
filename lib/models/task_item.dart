import 'package:flutter/material.dart';
import '../core/app_colors.dart';

/// أولوية/حالة المهمة — كل حالة إلها لون محدد بنظام الألوان الرسمي:
/// Due today = أحمر/كورال (تنبيه)، Due tomorrow = أصفر (متوسط)،
/// أي موعد بعيد = أخضر (مطمئن)
enum TaskUrgency { dueToday, dueSoon, upcoming }

extension TaskUrgencyColor on TaskUrgency {
  Color get color {
    switch (this) {
      case TaskUrgency.dueToday:
        return AppColors.alertCoral;
      case TaskUrgency.dueSoon:
        return AppColors.priorityYellow;
      case TaskUrgency.upcoming:
        return AppColors.statusGreen;
    }
  }
}

/// مهمة وحيدة (مستخدمة بـ Priority Tasks بشاشة الـ Home
/// وبـ Upcoming Tasks بشاشة Project Details)
class TaskItem {
  final String id;
  final String title;
  final String dueLabel; // "Due Today", "Due Tomorrow", "Due Sep 15"...
  final TaskUrgency urgency;
  final bool isDone;

  const TaskItem({
    required this.id,
    required this.title,
    required this.dueLabel,
    required this.urgency,
    this.isDone = false,
  });
}
