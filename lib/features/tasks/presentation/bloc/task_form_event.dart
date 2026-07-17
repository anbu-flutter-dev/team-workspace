import 'package:equatable/equatable.dart';
import 'package:team_workspace/features/tasks/domain/entities/task.dart';
import 'package:team_workspace/features/tasks/domain/entities/task_priority.dart';
import 'package:team_workspace/features/tasks/domain/entities/task_status.dart';

sealed class TaskFormEvent extends Equatable {
  const TaskFormEvent();

  @override
  List<Object?> get props => [];
}

final class TaskFormSubmitted extends TaskFormEvent {
  const TaskFormSubmitted({
    required this.title,
    required this.description,
    required this.priority,
    required this.dueDate,
    this.status,
    this.existingTask,
  });

  final String title;
  final String description;
  final TaskPriority priority;
  final DateTime dueDate;
  final TaskStatus? status;

  /// Null means create; non-null means edit that task in place.
  final Task? existingTask;

  @override
  List<Object?> get props => [
    title,
    description,
    priority,
    dueDate,
    status,
    existingTask,
  ];
}
