import 'package:flutter/material.dart';

import '../core/app_colors.dart';

/// Task urgency/status.
/// Each urgency level uses the official ScaleFlow color system.
enum TaskUrgency {
  dueToday,
  dueSoon,
  upcoming,
}

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

/// A single task used across Home and Project Details.
class TaskItem {
  final String id;
  final String title;
  final String dueLabel;
  final TaskUrgency urgency;

  /// Mutable because the Home screen checkbox updates task completion.
  bool isDone;

  TaskItem({
    required this.id,
    required this.title,
    required this.dueLabel,
    required this.urgency,
    this.isDone = false,
  });
}
