import 'package:equatable/equatable.dart';
import 'package:team_workspace/features/tasks/domain/entities/task.dart';
import 'package:team_workspace/features/tasks/domain/entities/task_priority.dart';
import 'package:team_workspace/features/tasks/domain/entities/task_status.dart';

sealed class TaskListEvent extends Equatable {
  const TaskListEvent();

  @override
  List<Object?> get props => [];
}

final class TaskListStarted extends TaskListEvent {
  const TaskListStarted();
}

final class TaskListNextPageRequested extends TaskListEvent {
  const TaskListNextPageRequested();
}

final class TaskListRefreshRequested extends TaskListEvent {
  const TaskListRefreshRequested();
}

final class TaskUpdateReceived extends TaskListEvent {
  const TaskUpdateReceived(this.task);

  final Task task;

  @override
  List<Object?> get props => [task];
}

final class TaskListSearchQueryChanged extends TaskListEvent {
  const TaskListSearchQueryChanged(this.query);

  final String query;

  @override
  List<Object?> get props => [query];
}

final class TaskListStatusFilterToggled extends TaskListEvent {
  const TaskListStatusFilterToggled(this.status);

  final TaskStatus status;

  @override
  List<Object?> get props => [status];
}

final class TaskListPriorityFilterToggled extends TaskListEvent {
  const TaskListPriorityFilterToggled(this.priority);

  final TaskPriority priority;

  @override
  List<Object?> get props => [priority];
}

final class TaskListFiltersCleared extends TaskListEvent {
  const TaskListFiltersCleared();
}
