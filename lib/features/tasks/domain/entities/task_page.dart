import 'package:equatable/equatable.dart';
import 'package:team_workspace/features/tasks/domain/entities/task.dart';

final class TaskPage extends Equatable {
  const TaskPage({
    required this.tasks,
    required this.hasMore,
    required this.isFromCache,
  });

  final List<Task> tasks;
  final bool hasMore;
  final bool isFromCache;

  @override
  List<Object?> get props => [tasks, hasMore, isFromCache];
}
