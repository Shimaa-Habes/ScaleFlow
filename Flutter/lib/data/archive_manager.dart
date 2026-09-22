import '../models/project.dart';

class ArchiveManager {
  ArchiveManager._();

  static final List<Project> archivedProjects = [];

  static bool isArchived(Project project) {
    return archivedProjects.any(
      (item) => item.id == project.id,
    );
  }

  static void archive(Project project) {
    if (!isArchived(project)) {
      archivedProjects.add(project);
    }
  }

  static void restore(Project project) {
    archivedProjects.removeWhere(
      (item) => item.id == project.id,
    );
  }
}