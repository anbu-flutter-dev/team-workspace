import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:team_workspace/features/tasks/domain/entities/task_priority.dart';
import 'package:team_workspace/features/tasks/domain/entities/task_status.dart';
import 'package:team_workspace/features/tasks/presentation/bloc/task_list_bloc.dart';
import 'package:team_workspace/features/tasks/presentation/bloc/task_list_event.dart';
import 'package:team_workspace/features/tasks/presentation/bloc/task_list_state.dart';

class TaskSearchFilterBar extends StatefulWidget {
  const TaskSearchFilterBar({super.key, required this.state});

  final TaskListLoadSuccess state;

  @override
  State<TaskSearchFilterBar> createState() => _TaskSearchFilterBarState();
}

class _TaskSearchFilterBarState extends State<TaskSearchFilterBar> {
  late final TextEditingController _controller = TextEditingController(
    text: widget.state.searchQuery,
  );
  Timer? _debounce;

  @override
  void didUpdateWidget(covariant TaskSearchFilterBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Only resync when the bloc's query diverges from what's typed — covers
    // the "Clear all filters" button on the no-results view, not live typing.
    if (widget.state.searchQuery != oldWidget.state.searchQuery &&
        widget.state.searchQuery != _controller.text) {
      _controller.text = widget.state.searchQuery;
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _onChanged(String value) {
    _debounce?.cancel();
    // 300ms felt right on a mid-range device — enough to skip mid-word fetches.
    _debounce = Timer(const Duration(milliseconds: 300), () {
      context.read<TaskListBloc>().add(TaskListSearchQueryChanged(value));
    });
  }

  void _clearAll() {
    _debounce?.cancel();
    _controller.clear();
    context.read<TaskListBloc>().add(const TaskListFiltersCleared());
  }

  @override
  Widget build(BuildContext context) {
    final state = widget.state;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _controller,
            onChanged: _onChanged,
            decoration: InputDecoration(
              hintText: 'Search tasks',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: state.hasActiveFilters
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: _clearAll,
                    )
                  : null,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: [
              for (final status in TaskStatus.values)
                FilterChip(
                  label: Text(_statusLabel(status)),
                  selected: state.selectedStatuses.contains(status),
                  onSelected: (_) => context.read<TaskListBloc>().add(
                    TaskListStatusFilterToggled(status),
                  ),
                ),
              for (final priority in TaskPriority.values)
                FilterChip(
                  label: Text(_priorityLabel(priority)),
                  selected: state.selectedPriorities.contains(priority),
                  onSelected: (_) => context.read<TaskListBloc>().add(
                    TaskListPriorityFilterToggled(priority),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  String _statusLabel(TaskStatus status) => switch (status) {
    TaskStatus.pending => 'Pending',
    TaskStatus.inProgress => 'In progress',
    TaskStatus.completed => 'Completed',
  };

  String _priorityLabel(TaskPriority priority) => switch (priority) {
    TaskPriority.low => 'Low',
    TaskPriority.medium => 'Medium',
    TaskPriority.high => 'High',
  };
}
