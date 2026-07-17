import 'package:equatable/equatable.dart';
import 'package:team_workspace/features/tasks/domain/entities/task.dart';
import 'package:team_workspace/features/tasks/domain/entities/task_priority.dart';
import 'package:team_workspace/features/tasks/domain/entities/task_status.dart';

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
    this.searchQuery = '',
    this.selectedStatuses = const {},
    this.selectedPriorities = const {},
  });

  final List<Task> tasks;
  final int currentPage;
  final bool hasMore;
  final bool isLoadingNextPage;
  final String? paginationError;
  final bool isFromCache;
  final String searchQuery;
  final Set<TaskStatus> selectedStatuses;
  final Set<TaskPriority> selectedPriorities;

  bool get hasActiveFilters =>
      searchQuery.isNotEmpty ||
      selectedStatuses.isNotEmpty ||
      selectedPriorities.isNotEmpty;

  List<Task> get filteredTasks {
    if (!hasActiveFilters) return tasks;
    final query = searchQuery.trim().toLowerCase();
    return tasks.where((task) {
      final matchesQuery =
          query.isEmpty || task.title.toLowerCase().contains(query);
      final matchesStatus =
          selectedStatuses.isEmpty || selectedStatuses.contains(task.status);
      final matchesPriority =
          selectedPriorities.isEmpty ||
          selectedPriorities.contains(task.priority);
      return matchesQuery && matchesStatus && matchesPriority;
    }).toList();
  }

  TaskListLoadSuccess copyWith({
    List<Task>? tasks,
    int? currentPage,
    bool? hasMore,
    bool? isLoadingNextPage,
    Object? paginationError = _unset,
    bool? isFromCache,
    String? searchQuery,
    Set<TaskStatus>? selectedStatuses,
    Set<TaskPriority>? selectedPriorities,
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
      searchQuery: searchQuery ?? this.searchQuery,
      selectedStatuses: selectedStatuses ?? this.selectedStatuses,
      selectedPriorities: selectedPriorities ?? this.selectedPriorities,
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
    searchQuery,
    selectedStatuses,
    selectedPriorities,
  ];
}

const Object _unset = Object();
