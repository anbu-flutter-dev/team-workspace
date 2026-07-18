import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:team_workspace/core/theme/app_colors.dart';
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

  /// Selected chips sit on a fixed brand color (not theme-driven), so their
  /// label/icon needs a contrast-computed color rather than the theme's
  /// default — but unselected chips sit on the theme's own chip background,
  /// so those must stay null and inherit ChipTheme.labelStyle, or they read
  /// as invisible dark-on-dark in dark mode (the bug this replaced).
  Color _onColor(Color background) =>
      ThemeData.estimateBrightnessForColor(background) == Brightness.dark
      ? Colors.white
      : Colors.black;

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
          const SizedBox(height: 12),
          _FilterGroupLabel(icon: Icons.flag_outlined, label: 'Status'),
          const SizedBox(height: 6),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: [
              for (final status in TaskStatus.values)
                _statusChip(context, state, status),
            ],
          ),
          const SizedBox(height: 12),
          _FilterGroupLabel(icon: Icons.speed_outlined, label: 'Priority'),
          const SizedBox(height: 6),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: [
              for (final priority in TaskPriority.values)
                _priorityChip(context, state, priority),
            ],
          ),
        ],
      ),
    );
  }

  Widget _statusChip(
    BuildContext context,
    TaskListLoadSuccess state,
    TaskStatus status,
  ) {
    final isSelected = state.selectedStatuses.contains(status);
    final statusColor = _statusColor(status);
    final onColor = isSelected ? _onColor(statusColor) : null;
    return FilterChip(
      avatar: Icon(
        _statusIcon(status),
        size: 16,
        color: onColor ?? statusColor,
      ),
      showCheckmark: false,
      label: Text(
        _statusLabel(status),
        style: onColor == null ? null : TextStyle(color: onColor),
      ),
      selected: isSelected,
      selectedColor: statusColor,
      onSelected: (_) =>
          context.read<TaskListBloc>().add(TaskListStatusFilterToggled(status)),
    );
  }

  Widget _priorityChip(
    BuildContext context,
    TaskListLoadSuccess state,
    TaskPriority priority,
  ) {
    final isSelected = state.selectedPriorities.contains(priority);
    final priorityColor = _priorityColor(priority);
    final onColor = isSelected ? _onColor(priorityColor) : null;
    return FilterChip(
      avatar: isSelected
          ? null
          : CircleAvatar(backgroundColor: priorityColor, radius: 5),
      showCheckmark: isSelected,
      checkmarkColor: onColor,
      label: Text(
        _priorityLabel(priority),
        style: onColor == null ? null : TextStyle(color: onColor),
      ),
      selected: isSelected,
      selectedColor: priorityColor,
      onSelected: (_) => context.read<TaskListBloc>().add(
        TaskListPriorityFilterToggled(priority),
      ),
    );
  }

  String _statusLabel(TaskStatus status) => switch (status) {
    TaskStatus.pending => 'Pending',
    TaskStatus.inProgress => 'In progress',
    TaskStatus.completed => 'Completed',
  };

  IconData _statusIcon(TaskStatus status) => switch (status) {
    TaskStatus.pending => Icons.schedule_rounded,
    TaskStatus.inProgress => Icons.autorenew_rounded,
    TaskStatus.completed => Icons.check_circle_rounded,
  };

  Color _statusColor(TaskStatus status) => switch (status) {
    TaskStatus.pending => AppColors.statusPending,
    TaskStatus.inProgress => AppColors.statusInProgress,
    TaskStatus.completed => AppColors.statusCompleted,
  };

  String _priorityLabel(TaskPriority priority) => switch (priority) {
    TaskPriority.low => 'Low',
    TaskPriority.medium => 'Medium',
    TaskPriority.high => 'High',
  };

  Color _priorityColor(TaskPriority priority) => switch (priority) {
    TaskPriority.low => AppColors.priorityLow,
    TaskPriority.medium => AppColors.priorityMedium,
    TaskPriority.high => AppColors.priorityHigh,
  };
}

class _FilterGroupLabel extends StatelessWidget {
  const _FilterGroupLabel({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        Icon(icon, size: 14, color: colorScheme.outline),
        const SizedBox(width: 6),
        Text(label, style: Theme.of(context).textTheme.titleSmall),
      ],
    );
  }
}
