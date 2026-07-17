import 'package:equatable/equatable.dart';
import 'package:team_workspace/features/tasks/domain/entities/task.dart';

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
