import 'package:equatable/equatable.dart';
import 'package:team_workspace/features/tasks/domain/entities/task.dart';

sealed class TaskDetailEvent extends Equatable {
  const TaskDetailEvent();

  @override
  List<Object?> get props => [];
}

final class TaskDetailStarted extends TaskDetailEvent {
  const TaskDetailStarted(this.taskId);

  final String taskId;

  @override
  List<Object?> get props => [taskId];
}

final class TaskDetailToggleStatusRequested extends TaskDetailEvent {
  const TaskDetailToggleStatusRequested();
}

final class TaskDetailExternalUpdateReceived extends TaskDetailEvent {
  const TaskDetailExternalUpdateReceived(this.task);

  final Task task;

  @override
  List<Object?> get props => [task];
}
