import 'package:equatable/equatable.dart';
import 'package:team_workspace/features/tasks/domain/entities/task.dart';

enum SyncStatus { synced, pendingSync }

/// Result of a create/update write — distinguishes a save that reached the
/// server from one that only landed in the local overlay because the device
/// was offline or the remote call failed. Both count as success from the
/// user's point of view (the task is safely saved locally), but the
/// presentation layer needs the distinction so it doesn't claim a sync that
/// didn't actually happen.
class TaskSaveOutcome extends Equatable {
  const TaskSaveOutcome({required this.task, required this.syncStatus});

  final Task task;
  final SyncStatus syncStatus;

  bool get isPendingSync => syncStatus == SyncStatus.pendingSync;

  @override
  List<Object?> get props => [task, syncStatus];
}
