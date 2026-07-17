import 'package:equatable/equatable.dart';
import 'package:team_workspace/features/tasks/domain/entities/task.dart';

sealed class TaskDetailState extends Equatable {
  const TaskDetailState();

  @override
  List<Object?> get props => [];
}

final class TaskDetailLoading extends TaskDetailState {
  const TaskDetailLoading();
}

final class TaskDetailLoadFailure extends TaskDetailState {
  const TaskDetailLoadFailure(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}

final class TaskDetailLoadSuccess extends TaskDetailState {
  const TaskDetailLoadSuccess(this.task);

  final Task task;

  @override
  List<Object?> get props => [task];
}

/// One-shot: emitted right before the bloc reverts to LoadSuccess(previousTask).
final class TaskDetailToggleFailed extends TaskDetailState {
  const TaskDetailToggleFailed(this.revertedTask, this.message);

  final Task revertedTask;
  final String message;

  @override
  List<Object?> get props => [revertedTask, message];
}
