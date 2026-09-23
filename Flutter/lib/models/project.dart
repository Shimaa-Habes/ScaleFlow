import 'package:flutter/material.dart';
import '../core/app_colors.dart';
import 'task_item.dart';

enum ProjectStatus {
  onTrack,
  atRisk,
}

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

class TeamMember {
  final String initials;
  final Color color;

  const TeamMember({
    required this.initials,
    required this.color,
  });
}

class Project {
  // ============================================================
  // Backend fields
  // ============================================================

  /// Backend Project.Id
  /// Kept as String because the existing Flutter UI uses String IDs.
  final String id;

  /// Backend OrganizationId
  final int organizationId;

  /// Backend OwnerId
  final int ownerId;

  final String name;
  final String subtitle;

  /// Backend Description
  final String? description;

  /// Backend WorkspaceUrl
  final String? workspaceUrl;

  /// Backend Progress
  final int progress;

  /// Backend IsAtRisk
  final bool isAtRisk;

  /// Backend ImageUrl
  final String? imageUrl;

  /// Backend Status
  final ProjectStatus status;

  /// Backend Priority
  final int priority;

  /// Backend Budget
  final double? budget;

  /// Backend StartDate
  final DateTime? startDate;

  /// Backend EndDate
  final DateTime? endDate;

  /// UI / calculated values
  final int percentComplete;
  final String dueDate;
  final int healthPercent;
  final String healthNote;

  final int teamCount;
  final int tasksCompleted;
  final int tasksTotal;
  final int daysLeft;

  final String aiInsightTitle;
  final String aiInsightBody;

  final List<TeamMember> team;
  final List<TaskItem> tasks;

  final String projectLink;
  final List<String> memberNames;

  const Project({
    required this.id,
    this.organizationId = 0,
    this.ownerId = 0,
    required this.name,
    required this.subtitle,
    this.description,
    this.workspaceUrl,
    this.progress = 0,
    this.isAtRisk = false,
    this.imageUrl,
    required this.status,
    this.priority = 2,
    this.budget,
    this.startDate,
    this.endDate,
    this.percentComplete = 0,
    this.dueDate = '',
    this.healthPercent = 0,
    this.healthNote = '',
    this.teamCount = 0,
    this.tasksCompleted = 0,
    this.tasksTotal = 0,
    this.daysLeft = 0,
    this.aiInsightTitle = '',
    this.aiInsightBody = '',
    this.team = const [],
    this.tasks = const [],
    this.projectLink = '',
    this.memberNames = const [],
  });

  // ============================================================
  // Helpers
  // ============================================================

  /// Returns the project progress safely between 0 and 100.
  int get safeProgress {
    return progress.clamp(0, 100);
  }

  /// Returns a display-friendly due date.
  String get displayDueDate {
    if (dueDate.trim().isNotEmpty) {
      return dueDate;
    }

    if (endDate != null) {
      final date = endDate!.toLocal();

      return '${date.day.toString().padLeft(2, '0')}/'
          '${date.month.toString().padLeft(2, '0')}/'
          '${date.year}';
    }

    return 'No due date';
  }

  /// Returns the workspace URL when available.
  String get effectiveProjectLink {
    if (projectLink.trim().isNotEmpty) {
      return projectLink;
    }

    return workspaceUrl ?? '';
  }

  /// Converts the UI status into the backend IsAtRisk meaning.
  bool get riskStatus => isAtRisk || status == ProjectStatus.atRisk;
}
