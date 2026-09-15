import 'package:flutter/material.dart';
import '../core/app_colors.dart';
import 'task_item.dart';

/// حالة المشروع العامة — On Track = أخضر (نجاح)، At Risk = كورال (تنبيه)
enum ProjectStatus { onTrack, atRisk }

extension ProjectStatusData on ProjectStatus {
  String get label {
    switch (this) {
      case ProjectStatus.onTrack:
        return 'On Track';
      case ProjectStatus.atRisk:
        return 'At Risk';
    }
  }

  Color get color {
    switch (this) {
      case ProjectStatus.onTrack:
        return AppColors.statusGreen;
      case ProjectStatus.atRisk:
        return AppColors.alertCoral;
    }
  }
}

/// عضو بفريق المشروع — أفتكار بسيط عن الصورة (Initials بدل صورة حقيقية)
class TeamMember {
  final String initials;
  final Color color;

  const TeamMember({required this.initials, required this.color});
}

/// المشروع الكامل بكل بياناته — نفس الحقول الظاهرة بشاشتي
/// Home (My Projects) و Project Details
class Project {
  final String id;
  final String name;
  final String subtitle;
  final ProjectStatus status;
  final int percentComplete;
  final String dueDate;
  final int healthPercent; // Project Health %
  final String healthNote;
  final int teamCount;
  final int tasksCompleted;
  final int tasksTotal;
  final int daysLeft;
  final String aiInsightTitle;
  final String aiInsightBody;
  final List<TeamMember> team;
  final List<TaskItem> tasks;

  const Project({
    required this.id,
    required this.name,
    required this.subtitle,
    required this.status,
    required this.percentComplete,
    required this.dueDate,
    required this.healthPercent,
    required this.healthNote,
    required this.teamCount,
    required this.tasksCompleted,
    required this.tasksTotal,
    required this.daysLeft,
    required this.aiInsightTitle,
    required this.aiInsightBody,
    required this.team,
    required this.tasks,
  });
}
