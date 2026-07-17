import 'package:team_workspace/features/tasks/domain/entities/assigned_user.dart';
import 'package:team_workspace/features/tasks/domain/entities/task_priority.dart';
import 'package:team_workspace/features/tasks/domain/entities/task_status.dart';

/// dummyjson todos only have id/todo/completed/userId — everything else here
/// is derived deterministically from id so a refresh doesn't reshuffle the list.
class TaskEnrichment {
  TaskEnrichment._();

  static const List<String> mockUsers = [
    'Aditi Rao',
    'Marcus Chen',
    'Priya Nair',
    'Daniel Osei',
    'Sofia Ruiz',
    'Ken Watanabe',
  ];

  static TaskPriority priorityFor(int id) {
    switch (id % 3) {
      case 0:
        return TaskPriority.low;
      case 1:
        return TaskPriority.medium;
      default:
        return TaskPriority.high;
    }
  }

  static DateTime dueDateFor(int id, {DateTime? now}) {
    final base = now ?? DateTime.now();
    final today = DateTime(base.year, base.month, base.day);
    return today.add(Duration(days: id % 30));
  }

  static String descriptionFor(int id, String todo) {
    return '$todo\n\n'
        'Auto-generated detail for demo task #$id — enriched client-side since '
        'dummyjson only returns a bare title and completion flag.';
  }

  static AssignedUser assignedUserFor(int id) {
    return AssignedUser(name: mockUsers[id % mockUsers.length]);
  }

  static TaskStatus initialStatusFor(int id, {required bool completed}) {
    if (completed) return TaskStatus.completed;
    return id.isEven ? TaskStatus.pending : TaskStatus.inProgress;
  }
}
