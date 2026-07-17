import 'package:equatable/equatable.dart';
import 'package:team_workspace/features/tasks/domain/entities/task.dart';

sealed class TaskListState extends Equatable {
  const TaskListState();

  @override
  List<Object?> get props => [];
}

final class TaskListLoading extends TaskListState {
  const TaskListLoading();
}

final class TaskListLoadFailure extends TaskListState {
  const TaskListLoadFailure(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}

final class TaskListLoadSuccess extends TaskListState {
  const TaskListLoadSuccess({
    required this.tasks,
    required this.currentPage,
    required this.hasMore,
    this.isLoadingNextPage = false,
    this.paginationError,
    this.isFromCache = false,
  });

  final List<Task> tasks;
  final int currentPage;
  final bool hasMore;
  final bool isLoadingNextPage;
  final String? paginationError;
  final bool isFromCache;

  TaskListLoadSuccess copyWith({
    List<Task>? tasks,
    int? currentPage,
    bool? hasMore,
    bool? isLoadingNextPage,
    Object? paginationError = _unset,
    bool? isFromCache,
  }) {
    return TaskListLoadSuccess(
      tasks: tasks ?? this.tasks,
      currentPage: currentPage ?? this.currentPage,
      hasMore: hasMore ?? this.hasMore,
      isLoadingNextPage: isLoadingNextPage ?? this.isLoadingNextPage,
      paginationError: identical(paginationError, _unset)
          ? this.paginationError
          : paginationError as String?,
      isFromCache: isFromCache ?? this.isFromCache,
    );
  }

  @override
  List<Object?> get props => [
    tasks,
    currentPage,
    hasMore,
    isLoadingNextPage,
    paginationError,
    isFromCache,
  ];
}

const Object _unset = Object();
