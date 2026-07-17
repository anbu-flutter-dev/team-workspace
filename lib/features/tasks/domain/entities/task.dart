import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:team_workspace/features/tasks/domain/entities/assigned_user.dart';
import 'package:team_workspace/features/tasks/domain/entities/task_priority.dart';
import 'package:team_workspace/features/tasks/domain/entities/task_status.dart';

part 'task.freezed.dart';
part 'task.g.dart';

/// A task on the dashboard — enriched client-side from dummyjson's bare todo shape.
@freezed
abstract class Task with _$Task {
  const Task._();

  const factory Task({
    required String id,
    required String title,
    required String description,
    required TaskPriority priority,
    required DateTime dueDate,
    required TaskStatus status,
    required AssignedUser assignedUser,
  }) = _Task;

  factory Task.fromJson(Map<String, dynamic> json) => _$TaskFromJson(json);

  bool get isCompleted => status == TaskStatus.completed;

  bool get isLocalOnly => id.startsWith('local_');
}
